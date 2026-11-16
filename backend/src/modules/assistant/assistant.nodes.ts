import { AIMessage, HumanMessage } from '@langchain/core/messages';
import { logger } from '../../core/utils/logger.js';
import { assistantLlm } from './assistant.llm.js';
import { assistantTools } from './assistant.tools.js';
import type { AssistantStateType, } from './assistant.state.js';
import type { TransactionDraft } from './assistant.types.js';

const formatRupees = (minor: number) => (minor / 100).toLocaleString('en-IN', {
  minimumFractionDigits: 0,
  maximumFractionDigits: 2,
});

const mergeDraft = (previous: TransactionDraft | null, incoming: Record<string, unknown>): TransactionDraft => {
  const draft: TransactionDraft = { ...(previous ?? { currency: 'INR' }) };
  if (typeof incoming.amount === 'number' && Number.isFinite(incoming.amount) && incoming.amount > 0) {
    const minor = Math.round(incoming.amount * 100);
    if (Number.isSafeInteger(minor) && minor > 0) draft.amountMinor = minor;
  }
  if (typeof incoming.currency === 'string') draft.currency = incoming.currency.toUpperCase();
  if (typeof incoming.categoryId === 'string') draft.categoryId = incoming.categoryId;
  if (typeof incoming.categoryName === 'string') draft.categoryName = incoming.categoryName;
  if (typeof incoming.description === 'string' && incoming.description.trim()) draft.description = incoming.description.trim();
  if (typeof incoming.transactionDate === 'string') draft.transactionDate = incoming.transactionDate;
  if (typeof incoming.paymentMethod === 'string') draft.paymentMethod = incoming.paymentMethod as TransactionDraft['paymentMethod'];
  if (typeof incoming.notes === 'string') draft.notes = incoming.notes;
  return draft;
};

export const understandMessageNode = async (state: AssistantStateType) => {
  const extracted = await assistantLlm.extract(state.messages.at(-1)?.content?.toString() ?? '', state.timezone, state.locale);
  let intent = extracted.intent;

  // Pending confirmation is application state, not a model decision.
  if (state.status === 'awaiting_confirmation' && state.pendingTransaction) {
    const text = state.messages.at(-1)?.content?.toString().trim().toLowerCase() ?? '';
    if (/^(yes|yes please|confirm|save|save it|correct|proceed|okay)$/i.test(text)) intent = 'confirm';
    else if (/^(no|cancel|discard|forget it|don't save|do not save)$/i.test(text)) intent = 'cancel';
  }
  return { extracted: extracted as unknown as Record<string, unknown>, intent };
};

export const collectTransactionNode = async (state: AssistantStateType) => {
  const extracted = state.extracted ?? {};
  const candidate = mergeDraft(state.pendingTransaction, extracted);
  if (typeof extracted.category === 'string') {
    const category = await assistantTools.resolveCategory(state.userId, extracted.category);
    if (category) {
      candidate.categoryId = category._id.toString();
      candidate.categoryName = category.name;
    } else {
      candidate.categoryId = undefined;
      candidate.categoryName = extracted.category;
    }
  }

  const missing: string[] = [];
  if (!candidate.amountMinor) missing.push('amount');
  if (!candidate.categoryId) missing.push('category');
  if (!candidate.description) missing.push('description');

  if (missing.length) {
    const question = missing.length === 1
      ? `What is the ${missing[0]}?`
      : `I have the details so far. What is the ${missing.join(' and ')}?`;
    return {
      pendingTransaction: candidate,
      status: 'collecting' as const,
      reply: question,
      messages: [new AIMessage(question)],
    };
  }

  const reply = `Please confirm: ₹${formatRupees(candidate.amountMinor!)} for ${candidate.description} under ${candidate.categoryName}, paid via ${candidate.paymentMethod ?? 'UPI'}. Should I save it?`;
  return {
    pendingTransaction: candidate,
    status: 'awaiting_confirmation' as const,
    reply,
    messages: [new AIMessage(reply)],
  };
};

export const confirmTransactionNode = async (state: AssistantStateType) => {
  if (!state.pendingTransaction) {
    return { reply: 'There is no expense waiting for confirmation.', status: 'collecting' as const };
  }
  const expense = await assistantTools.saveExpense(state.userId, state.pendingTransaction);
  const reply = `Saved ₹${formatRupees(expense.amountMinor)} for ${expense.description}.`;
  return {
    pendingTransaction: null,
    status: 'saved' as const,
    reply,
    queryResult: expense.toObject(),
    messages: [new AIMessage(reply)],
  };
};

export const cancelTransactionNode = async () => {
  const reply = 'Okay, I discarded the pending expense. Nothing was saved.';
  return { pendingTransaction: null, status: 'cancelled' as const, reply, messages: [new AIMessage(reply)] };
};

export const expenseQueryNode = async (state: AssistantStateType) => {
  const query = state.extracted?.query;
  let result: unknown;
  let reply: string;

  if (query === 'category_breakdown') {
    result = await assistantTools.categoryBreakdown(state.userId);
    const rows = result as Array<{ categoryName: string; totalMinor: number; percentageOfTotal: number }>;
    reply = rows.length
      ? rows.map((row) => `${row.categoryName}: ₹${formatRupees(row.totalMinor)} (${row.percentageOfTotal}%)`).join('\n')
      : 'There is no spending data for this period.';
  } else if (query === 'largest_expenses') {
    result = await assistantTools.largestExpenses(state.userId);
    const rows = result as Array<{ description: string; amountMinor: number }>;
    reply = rows.length
      ? rows.map((row) => `${row.description}: ₹${formatRupees(row.amountMinor)}`).join('\n')
      : 'No expenses found.';
  } else if (query === 'transaction_search' && typeof state.extracted?.searchTerm === 'string') {
    result = await assistantTools.searchExpenses(state.userId, state.extracted.searchTerm);
    const rows = result as Array<{ description: string; amountMinor: number }>;
    reply = rows.length
      ? rows.map((row) => `${row.description}: ₹${formatRupees(row.amountMinor)}`).join('\n')
      : 'I could not find matching expenses.';
  } else {
    result = await assistantTools.spendingSummary(state.userId);
    const summary = result as { monthTotalMinor: number; todayTotalMinor: number; monthTransactionCount: number };
    reply = `You have spent ₹${formatRupees(summary.monthTotalMinor)} this month across ${summary.monthTransactionCount} transactions. Today's total is ₹${formatRupees(summary.todayTotalMinor)}.`;
  }

  // Read-only queries do not clear or overwrite a pending expense.
  return { queryResult: result, reply, status: state.status, pendingTransaction: state.pendingTransaction, messages: [new AIMessage(reply)] };
};

export const generalNode = async () => {
  const reply = 'I can record an expense or answer questions about your spending. For example, say “I spent 500 on groceries”.';
  return { reply, status: 'collecting' as const, messages: [new AIMessage(reply)] };
};

export const logNodeError = (error: unknown) => {
  logger.error({ error }, 'Assistant graph node failed');
  throw error;
};
