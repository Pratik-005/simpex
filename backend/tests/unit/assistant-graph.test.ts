import { describe, it, expect, vi, beforeEach } from 'vitest';
import { HumanMessage } from '@langchain/core/messages';
import type { AssistantStateType } from '../../src/modules/assistant/assistant.state.js';
import {
  collectTransactionNode,
  understandMessageNode,
  confirmTransactionNode,
  expenseQueryNode,
} from '../../src/modules/assistant/assistant.nodes.js';
import { assistantLlm } from '../../src/modules/assistant/assistant.llm.js';
import { assistantTools } from '../../src/modules/assistant/assistant.tools.js';

vi.mock('../../src/modules/assistant/assistant.llm.js', () => ({
  assistantLlm: { extract: vi.fn() },
}));
vi.mock('../../src/modules/assistant/assistant.tools.js', () => ({
  assistantTools: {
    resolveCategory: vi.fn(),
    saveExpense: vi.fn(),
    spendingSummary: vi.fn(),
    categoryBreakdown: vi.fn(),
    largestExpenses: vi.fn(),
    searchExpenses: vi.fn(),
  },
}));

const baseState = (): AssistantStateType => ({
  messages: [new HumanMessage('Spent 500 on groceries')],
  userId: '507f1f77bcf86cd799439011',
  conversationId: 'conversation-1',
  timezone: 'Asia/Kolkata',
  locale: 'en_IN',
  intent: 'record_expense',
  extracted: null,
  pendingTransaction: null,
  status: 'collecting',
  reply: '',
  queryResult: null,
});

describe('Assistant LangGraph nodes', () => {
  beforeEach(() => vi.clearAllMocks());

  it('uses model extraction but enforces confirmation from application state', async () => {
    vi.mocked(assistantLlm.extract).mockResolvedValue({
      intent: 'general', amount: null, currency: null, category: null, description: null,
      transactionDate: null, paymentMethod: null, notes: null, query: null, searchTerm: null,
    });
    const state = {
      ...baseState(),
      messages: [new HumanMessage('yes')],
      pendingTransaction: {
        draftId: 'draft-1', amountMinor: 50000, currency: 'INR',
        categoryId: 'category-1', categoryName: 'Groceries', description: 'Groceries',
      },
      status: 'awaiting_confirmation',
    } as AssistantStateType;

    const result = await understandMessageNode(state);
    expect(result.intent).toBe('confirm');
  });

  it('asks for missing required amount instead of creating an incomplete expense', async () => {
    vi.mocked(assistantTools.resolveCategory).mockResolvedValue({
      _id: { toString: () => 'category-1' },
      name: 'Groceries',
    } as never);

    const state = {
      ...baseState(),
      extracted: { amount: null, category: 'groceries', description: null },
    } as AssistantStateType;

    const result = await collectTransactionNode(state);
    expect(result.status).toBe('collecting');
    expect(result.reply).toContain('How much');
    expect(result.pendingTransaction?.categoryId).toBe('category-1');
  });

  it('uses a resolved category as description and requires confirmation', async () => {
    vi.mocked(assistantTools.resolveCategory).mockResolvedValue({
      _id: { toString: () => 'category-1' },
      name: 'Groceries',
    } as never);

    const result = await collectTransactionNode({
      ...baseState(),
      extracted: { amount: 500, category: 'grocery', description: null, currency: 'INR' },
    } as AssistantStateType);

    expect(result.status).toBe('awaiting_confirmation');
    expect(result.pendingTransaction?.amountMinor).toBe(50000);
    expect(result.pendingTransaction?.description).toBe('Groceries');
    expect(result.reply).toContain('Should I save it?');
  });

  it('saves only after the explicit confirmation node is invoked', async () => {
    vi.mocked(assistantTools.saveExpense).mockResolvedValue({
      amountMinor: 50000,
      description: 'Groceries',
      toObject: () => ({ amountMinor: 50000, description: 'Groceries' }),
    } as never);

    const result = await confirmTransactionNode({
      ...baseState(),
      pendingTransaction: {
        draftId: 'draft-1', amountMinor: 50000, currency: 'INR',
        categoryId: 'category-1', categoryName: 'Groceries', description: 'Groceries',
      },
      status: 'awaiting_confirmation',
    } as AssistantStateType);

    expect(assistantTools.saveExpense).toHaveBeenCalledOnce();
    expect(result.status).toBe('saved');
    expect(result.pendingTransaction).toBeNull();
  });

  it('keeps pending expense state unchanged when answering a read-only query', async () => {
    vi.mocked(assistantTools.spendingSummary).mockResolvedValue({
      monthTotalMinor: 1500000,
      todayTotalMinor: 50000,
      previousMonthTotalMinor: 1200000,
      monthOverMonthChangePercent: 25,
      monthTransactionCount: 42,
    });

    const pending = {
      draftId: 'draft-1', amountMinor: 50000, currency: 'INR',
      categoryId: 'category-1', categoryName: 'Groceries', description: 'Groceries',
    };
    const result = await expenseQueryNode({
      ...baseState(),
      extracted: { query: 'summary' },
      pendingTransaction: pending,
      status: 'awaiting_confirmation',
    } as AssistantStateType);

    expect(result.pendingTransaction).toBe(pending);
    expect(result.status).toBe('awaiting_confirmation');
    expect(result.reply).toContain('₹15,000');
  });
});
