import { StateGraph, Annotation, START, END } from '@langchain/langgraph';
import mongoose from 'mongoose';
import {
  getCategoriesTool,
  resolveCategory,
  createDraftTool,
  updateDraftTool,
  confirmExpenseTool,
  cancelDraftTool,
  getExpenseSummaryTool,
} from './tools/assistant-tools.js';
import { ExpenseDraft, IExpenseDraft } from './draft.model.js';
import { logger } from '../../core/utils/logger.js';

export interface AssistantInput {
  userId: string;
  conversationId: string;
  message: string;
  locale?: string;
}

export type AssistantResponseStatus =
  | 'idle'
  | 'draft'
  | 'awaiting_confirmation'
  | 'saved'
  | 'cancelled'
  | 'draft_created'
  | 'draft_updated'
  | 'query_answered'
  | 'needs_clarification'
  | 'fallback'
  | 'error';

export interface AssistantResponse {
  reply: string;
  activeDraft: IExpenseDraft | null;
  status: AssistantResponseStatus;
}

export type AssistantIntent =
  | 'confirm'
  | 'cancel'
  | 'query'
  | 'fill_slot'
  | 'update_draft'
  | 'create_draft'
  | 'fallback';

// 1. LangGraph State Annotation Schema
export const AssistantStateAnnotation = Annotation.Root({
  userId: Annotation<string>(),
  conversationId: Annotation<string>(),
  message: Annotation<string>(),
  locale: Annotation<string>({
    reducer: (_current, update) => update,
    default: () => 'en_IN',
  }),
  // CRITICAL FIX: Reducer accepts null as an explicit update to clear active draft
  activeDraft: Annotation<IExpenseDraft | null>({
    reducer: (_current, update) => update,
    default: () => null,
  }),
  intent: Annotation<AssistantIntent>({
    reducer: (_current, update) => update,
    default: () => 'fallback',
  }),
  extractedAmountMinor: Annotation<number | undefined>({
    reducer: (_current, update) => update,
    default: () => undefined,
  }),
  detectedCategory: Annotation<{ id: string; name: string } | undefined>({
    reducer: (_current, update) => update,
    default: () => undefined,
  }),
  extractedPaymentMethod: Annotation<string | undefined>({
    reducer: (_current, update) => update,
    default: () => undefined,
  }),
  transactionDate: Annotation<Date | undefined>({
    reducer: (_current, update) => update,
    default: () => undefined,
  }),
  reply: Annotation<string>({
    reducer: (_current, update) => update,
    default: () => '',
  }),
  status: Annotation<AssistantResponseStatus>({
    reducer: (_current, update) => update,
    default: () => 'idle',
  }),
});

export type AssistantState = typeof AssistantStateAnnotation.State;

// 2. LangGraph Node: Fetch Active Draft Context
export const fetchContextNode = async (state: AssistantState) => {
  try {
    const userObjId = mongoose.Types.ObjectId.isValid(state.userId)
      ? new mongoose.Types.ObjectId(state.userId)
      : undefined;

    if (!userObjId) return { activeDraft: null };

    const activeDraft = await ExpenseDraft.findOne({
      userId: userObjId,
      conversationId: state.conversationId,
      status: { $in: ['draft', 'awaiting_confirmation'] },
    }).sort({ createdAt: -1 });

    return { activeDraft };
  } catch (err) {
    logger.error({ err }, 'Error fetching active draft context in LangGraph');
    return { activeDraft: null };
  }
};

// 3. Helper: Accurate Entity Extraction from Text
export const extractEntities = async (userId: string, message: string) => {
  const lowerMsg = message.toLowerCase().trim();

  // A. Accurate Decimal Amount Parsing to Paise
  let extractedAmountMinor: number | undefined;
  // Match forms like ₹500, ₹500.50, 500.50 rupees, 1,250 bucks, etc.
  const amountPattern = /(?:₹|rs\.?|inr|rupees)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)\s*(?:₹|rs\.?|inr|rupees|bucks)?/i;
  const match = lowerMsg.match(amountPattern);

  if (match && match[1]) {
    const cleanNum = match[1].replace(/,/g, '');
    const parsed = parseFloat(cleanNum);
    if (!isNaN(parsed) && parsed > 0 && isFinite(parsed)) {
      extractedAmountMinor = Math.round(parsed * 100);
    }
  }

  // B. Payment Method Extraction
  let extractedPaymentMethod: string | undefined;
  if (/\b(cash)\b/i.test(lowerMsg)) {
    extractedPaymentMethod = 'Cash';
  } else if (/\b(credit\s*card)\b/i.test(lowerMsg)) {
    extractedPaymentMethod = 'Credit Card';
  } else if (/\b(debit\s*card)\b/i.test(lowerMsg)) {
    extractedPaymentMethod = 'Debit Card';
  } else if (/\b(card)\b/i.test(lowerMsg)) {
    extractedPaymentMethod = 'Card';
  } else if (/\b(apple\s*pay)\b/i.test(lowerMsg)) {
    extractedPaymentMethod = 'Apple Pay';
  } else if (/\b(net\s*banking|netbanking)\b/i.test(lowerMsg)) {
    extractedPaymentMethod = 'Net Banking';
  } else if (/\b(upi|gpay|google\s*pay|phonepe|paytm)\b/i.test(lowerMsg)) {
    extractedPaymentMethod = 'UPI';
  }

  // C. Category Resolution with In-Memory Synonyms & Aliases
  let detectedCategory: { id: string; name: string } | undefined;
  const categories = await getCategoriesTool(userId);

  // 1. Direct name match
  for (const c of categories) {
    const catLower = c.name.toLowerCase();
    if (lowerMsg.includes(catLower)) {
      detectedCategory = { id: c.id, name: c.name };
      break;
    }
  }

  // 2. In-memory synonym mapping against active categories
  if (!detectedCategory && categories.length > 0) {
    const synonyms: Record<string, string[]> = {
      groceries: ['grocery', 'supermarket', 'vegetables', 'fruits', 'milk', 'bread', 'veggies', 'kirana', 'provisions'],
      'food & dining': ['food', 'dining', 'dinner', 'lunch', 'breakfast', 'restaurant', 'cafe', 'coffee', 'tea', 'swiggy', 'zomato', 'fast food', 'snack', 'snacks', 'starbucks', 'biryani'],
      transportation: ['transport', 'uber', 'ola', 'fuel', 'petrol', 'diesel', 'cab', 'taxi', 'auto', 'metro', 'bus', 'flight', 'railway', 'train', 'toll'],
      bills: ['bill', 'electricity', 'water', 'wifi', 'broadband', 'internet', 'mobile', 'recharge', 'rent', 'utility', 'utilities', 'gas', 'dth'],
      shopping: ['shop', 'clothes', 'amazon', 'flipkart', 'myntra', 'shoes', 'electronics', 'gadget'],
      entertainment: ['movie', 'movies', 'cinema', 'netflix', 'prime', 'spotify', 'concert', 'game', 'gaming'],
      health: ['doctor', 'medicine', 'pharmacy', 'hospital', 'clinic', 'medical', 'gym', 'fitness'],
      education: ['book', 'books', 'course', 'tuition', 'fee', 'school', 'college', 'exam'],
    };

    for (const [targetCategoryKey, keywords] of Object.entries(synonyms)) {
      if (keywords.some((kw) => new RegExp(`\\b${kw}\\b`, 'i').test(lowerMsg))) {
        const matched = categories.find(
          (c) =>
            c.name.toLowerCase().includes(targetCategoryKey) ||
            targetCategoryKey.includes(c.name.toLowerCase())
        );
        if (matched) {
          detectedCategory = { id: matched.id, name: matched.name };
          break;
        }
      }
    }
  }

  // 3. Fallback to DB resolver if still unresolved and database is connected
  if (!detectedCategory && mongoose.connection.readyState === 1) {
    const resolved = await resolveCategory(userId, lowerMsg);
    if (resolved) {
      detectedCategory = { id: resolved.id.toString(), name: resolved.name };
    }
  }

  // D. Date Extraction
  let transactionDate: Date | undefined;
  if (/\b(yesterday)\b/i.test(lowerMsg)) {
    const d = new Date();
    d.setDate(d.getDate() - 1);
    transactionDate = d;
  } else if (/\b(day before yesterday)\b/i.test(lowerMsg)) {
    const d = new Date();
    d.setDate(d.getDate() - 2);
    transactionDate = d;
  } else if (/\b(today)\b/i.test(lowerMsg)) {
    transactionDate = new Date();
  }

  return {
    extractedAmountMinor,
    extractedPaymentMethod,
    detectedCategory,
    transactionDate,
  };
};

// 4. LangGraph Node: Intent Classification & Entity Extraction
export const classifyIntentNode = async (state: AssistantState) => {
  const lowerMsg = state.message.toLowerCase().trim();

  // A. Check Confirmation
  const hasNegation = /\b(not yet|dont|don't|no|wait|nevermind)\b/i.test(lowerMsg);
  const isConfirmKeyword =
    /^(yes|confirm|save it|save|correct|sure|proceed|do it|okay save|yes save|yes please|yep|yeah)$/i.test(lowerMsg) ||
    lowerMsg.includes('save that') ||
    lowerMsg.includes('save it') ||
    lowerMsg.includes('confirm draft');

  if (
    isConfirmKeyword &&
    !hasNegation &&
    state.activeDraft &&
    state.activeDraft.status === 'awaiting_confirmation'
  ) {
    return { intent: 'confirm' as const };
  }

  // B. Check Cancellation
  const isCancelKeyword =
    /^(no|cancel|stop|dont save|don't save|nevermind|forget it|discard)$/i.test(lowerMsg) ||
    lowerMsg.includes('cancel that') ||
    lowerMsg.includes('cancel draft') ||
    lowerMsg.includes('discard draft');

  if (isCancelKeyword && state.activeDraft) {
    return { intent: 'cancel' as const };
  }

  // C. Check Analytics Query (Deterministic Aggregation)
  if (
    lowerMsg.includes('how much') ||
    lowerMsg.includes('total spend') ||
    lowerMsg.includes('spent this month') ||
    lowerMsg.includes('todays spend') ||
    lowerMsg.includes("today's spend") ||
    lowerMsg.includes('summary') ||
    lowerMsg.includes('spending summary')
  ) {
    return { intent: 'query' as const };
  }

  // D. Extract Entities (Amount, Category, Payment Method, Date)
  const entities = await extractEntities(state.userId, state.message);

  // E. Slot-Filling Mode: If active draft has missing slots, merge incoming entities!
  if (
    state.activeDraft &&
    state.activeDraft.status === 'draft' &&
    state.activeDraft.missingFields &&
    state.activeDraft.missingFields.length > 0 &&
    (entities.extractedAmountMinor || entities.detectedCategory || entities.extractedPaymentMethod)
  ) {
    return {
      intent: 'fill_slot' as const,
      ...entities,
    };
  }

  // F. Live Draft Modification / Correction Mode
  const isCorrection =
    lowerMsg.includes('actually') ||
    lowerMsg.includes('change') ||
    lowerMsg.includes('make that') ||
    lowerMsg.includes('instead') ||
    lowerMsg.includes('update') ||
    lowerMsg.includes('not ');

  if (
    state.activeDraft &&
    (isCorrection || state.activeDraft.status === 'awaiting_confirmation') &&
    (entities.extractedAmountMinor || entities.detectedCategory || entities.extractedPaymentMethod || entities.transactionDate)
  ) {
    return {
      intent: 'update_draft' as const,
      ...entities,
    };
  }

  // G. New Draft Creation Mode
  if (entities.extractedAmountMinor || entities.detectedCategory) {
    return {
      intent: 'create_draft' as const,
      ...entities,
    };
  }

  // H. Fallback
  return {
    intent: 'fallback' as const,
    ...entities,
  };
};

// 5. LangGraph Node: Confirm & Persist Expense Node
export const confirmExpenseNode = async (state: AssistantState) => {
  try {
    const draftId = state.activeDraft?._id ? state.activeDraft._id.toString() : undefined;
    const result = await confirmExpenseTool(state.userId, state.conversationId, draftId);
    const amountRupees = ((result.persistedExpense.amountMinor ?? 0) / 100).toLocaleString('en-IN', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    });

    return {
      reply: `Done! Your ${result.persistedExpense.description} expense of ₹${amountRupees} has been saved.`,
      activeDraft: null, // Clears cleanly with updated reducer
      status: 'saved' as const,
    };
  } catch (err: unknown) {
    logger.error({ err }, 'Failed to commit expense confirmation in LangGraph');
    return {
      reply: 'I was unable to save the expense to the database. Please try confirming again.',
      activeDraft: state.activeDraft,
      status: 'awaiting_confirmation' as const,
    };
  }
};

// 6. LangGraph Node: Cancel Draft Node
export const cancelDraftNode = async (state: AssistantState) => {
  try {
    const draftId = state.activeDraft?._id ? state.activeDraft._id.toString() : undefined;
    await cancelDraftTool(state.userId, state.conversationId, draftId);
    return {
      reply: 'Cancelled. I have discarded that expense draft.',
      activeDraft: null, // Clears cleanly
      status: 'cancelled' as const,
    };
  } catch (err) {
    logger.error({ err }, 'Error cancelling draft in LangGraph');
    return {
      reply: 'Error cancelling the draft. Please try again.',
      activeDraft: state.activeDraft,
      status: (state.activeDraft?.status as any) || 'idle',
    };
  }
};

// 7. LangGraph Node: Query Analytics Node (Read-only, PRESERVES active draft!)
export const queryAnalyticsNode = async (state: AssistantState) => {
  try {
    const summary = await getExpenseSummaryTool(state.userId);
    const monthRupees = (summary.monthTotalMinor / 100).toLocaleString('en-IN', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    });
    const todayRupees = (summary.todayTotalMinor / 100).toLocaleString('en-IN', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    });

    const reply = `You have spent ₹${monthRupees} this month across ${summary.monthTransactionCount} transactions. Today's total is ₹${todayRupees}.`;

    // Preserve active draft context if an unfinished draft exists
    const preservedStatus = state.activeDraft
      ? (state.activeDraft.status as any)
      : 'idle';

    return {
      reply,
      activeDraft: state.activeDraft, // Preserved!
      status: preservedStatus,
    };
  } catch (err) {
    logger.error({ err }, 'Error querying analytics in LangGraph');
    return {
      reply: 'I could not retrieve your spending analytics at the moment.',
      activeDraft: state.activeDraft,
      status: (state.activeDraft?.status as any) || 'idle',
    };
  }
};

// 8. LangGraph Node: Fill Missing Slot (Multi-turn Slot-Filling)
export const fillSlotNode = async (state: AssistantState) => {
  try {
    const draftId = state.activeDraft?._id ? state.activeDraft._id.toString() : undefined;
    const updatedDraft = await updateDraftTool(
      state.userId,
      state.conversationId,
      {
        amountMinor: state.extractedAmountMinor,
        categoryName: state.detectedCategory?.name,
        paymentMethod: state.extractedPaymentMethod as any,
        transactionDate: state.transactionDate,
      },
      draftId
    );

    if (updatedDraft.status === 'awaiting_confirmation') {
      const formattedAmount = ((updatedDraft.amountMinor ?? 0) / 100).toLocaleString('en-IN', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
      });
      const paymentInfo = updatedDraft.paymentMethod ? ` via ${updatedDraft.paymentMethod}` : '';
      return {
        reply: `Got it! That's ₹${formattedAmount} for ${updatedDraft.categoryName}${paymentInfo}. Should I save it?`,
        activeDraft: updatedDraft,
        status: 'awaiting_confirmation' as const,
      };
    } else {
      const missing = updatedDraft.missingFields.join(' and ');
      return {
        reply: `I noted that. I still need the ${missing}. Could you specify?`,
        activeDraft: updatedDraft,
        status: 'draft' as const,
      };
    }
  } catch (err) {
    logger.error({ err }, 'Error filling slot in LangGraph');
    return {
      reply: 'I encountered an issue updating that detail. Could you repeat it?',
      activeDraft: state.activeDraft,
      status: 'draft' as const,
    };
  }
};

// 9. LangGraph Node: Update Draft Node (Live Corrections)
export const updateDraftNode = async (state: AssistantState) => {
  try {
    const draftId = state.activeDraft?._id ? state.activeDraft._id.toString() : undefined;
    const updatedDraft = await updateDraftTool(
      state.userId,
      state.conversationId,
      {
        amountMinor: state.extractedAmountMinor,
        categoryName: state.detectedCategory?.name,
        paymentMethod: state.extractedPaymentMethod as any,
        transactionDate: state.transactionDate,
      },
      draftId
    );

    const formattedAmount = ((updatedDraft.amountMinor ?? 0) / 100).toLocaleString('en-IN', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    });
    const formattedDate = updatedDraft.transactionDate.toLocaleDateString('en-IN', {
      month: 'short',
      day: 'numeric',
    });
    const paymentInfo = updatedDraft.paymentMethod ? ` via ${updatedDraft.paymentMethod}` : '';

    return {
      reply: `Updated. That's ₹${formattedAmount} under ${updatedDraft.categoryName || 'Uncategorized'} for ${formattedDate}${paymentInfo}. Should I save it?`,
      activeDraft: updatedDraft,
      status: (updatedDraft.status as any) || 'awaiting_confirmation',
    };
  } catch (err) {
    logger.error({ err }, 'Error updating draft in LangGraph');
    return {
      reply: 'I could not update the draft. Please try again.',
      activeDraft: state.activeDraft,
      status: (state.activeDraft?.status as any) || 'awaiting_confirmation',
    };
  }
};

// 10. LangGraph Node: Create Draft Node
export const createDraftNode = async (state: AssistantState) => {
  try {
    const newDraft = await createDraftTool(state.userId, state.conversationId, {
      amountMinor: state.extractedAmountMinor,
      categoryName: state.detectedCategory?.name,
      description: state.detectedCategory?.name || 'Voice Expense',
      transactionDate: state.transactionDate,
      paymentMethod: (state.extractedPaymentMethod as any) || 'UPI',
    });

    if (newDraft.status === 'awaiting_confirmation') {
      const formattedAmount = ((newDraft.amountMinor ?? 0) / 100).toLocaleString('en-IN', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
      });
      const paymentInfo = newDraft.paymentMethod ? ` via ${newDraft.paymentMethod}` : '';
      return {
        reply: `I have drafted an expense of ₹${formattedAmount} under ${newDraft.categoryName}${paymentInfo} for today. Should I save it?`,
        activeDraft: newDraft,
        status: 'awaiting_confirmation' as const,
      };
    } else {
      const missing = newDraft.missingFields.join(' and ');
      return {
        reply: `I noted that, but I still need the ${missing}. Could you specify?`,
        activeDraft: newDraft,
        status: 'draft' as const,
      };
    }
  } catch (err) {
    logger.error({ err }, 'Error creating draft in LangGraph');
    return {
      reply: 'I had trouble creating that expense draft. Please try saying it again.',
      activeDraft: null,
      status: 'error' as const,
    };
  }
};

// 11. LangGraph Node: Fallback Node
export const fallbackNode = async (state: AssistantState) => {
  const fallbackStatus =
    state.activeDraft?.status === 'confirmed'
      ? 'saved'
      : (state.activeDraft?.status as any) || 'idle';

  return {
    reply:
      "I didn't quite catch that. You can say something like 'Spent 500 on groceries today' or 'How much have I spent this month?'.",
    activeDraft: state.activeDraft,
    status: fallbackStatus,
  };
};

// 12. Compile StateGraph with Conditional Routing
export const assistantGraph = new StateGraph(AssistantStateAnnotation)
  .addNode('fetchContext', fetchContextNode)
  .addNode('classifyIntent', classifyIntentNode)
  .addNode('confirmExpense', confirmExpenseNode)
  .addNode('cancelDraft', cancelDraftNode)
  .addNode('queryAnalytics', queryAnalyticsNode)
  .addNode('fillSlot', fillSlotNode)
  .addNode('updateDraft', updateDraftNode)
  .addNode('createDraft', createDraftNode)
  .addNode('fallback', fallbackNode)
  // Entry point
  .addEdge(START, 'fetchContext')
  .addEdge('fetchContext', 'classifyIntent')
  // Conditional routing based on evaluated intent
  .addConditionalEdges(
    'classifyIntent',
    (state) => state.intent,
    {
      confirm: 'confirmExpense',
      cancel: 'cancelDraft',
      query: 'queryAnalytics',
      fill_slot: 'fillSlot',
      update_draft: 'updateDraft',
      create_draft: 'createDraft',
      fallback: 'fallback',
    }
  )
  // Terminal edges
  .addEdge('confirmExpense', END)
  .addEdge('cancelDraft', END)
  .addEdge('queryAnalytics', END)
  .addEdge('fillSlot', END)
  .addEdge('updateDraft', END)
  .addEdge('createDraft', END)
  .addEdge('fallback', END)
  .compile();

// 13. Assistant Workflow Wrapper
export class AssistantWorkflow {
  async run(input: AssistantInput): Promise<AssistantResponse> {
    const result = await assistantGraph.invoke({
      userId: input.userId,
      conversationId: input.conversationId,
      message: input.message,
      locale: input.locale || 'en_IN',
    });

    return {
      reply: result.reply,
      activeDraft: result.activeDraft,
      status: result.status,
    };
  }
}

export const assistantWorkflow = new AssistantWorkflow();
