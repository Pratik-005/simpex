import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  classifyIntentNode,
  queryAnalyticsNode,
  confirmExpenseNode,
  cancelDraftNode,
  AssistantState,
} from '../../src/modules/assistant/assistant.graph.js';
import * as assistantTools from '../../src/modules/assistant/tools/assistant-tools.js';

describe('LangGraph Assistant Intent & Slot Extraction', () => {
  beforeEach(() => {
    vi.spyOn(assistantTools, 'getCategoriesTool').mockResolvedValue([
      { id: 'cat-1', name: 'Groceries', color: '#10b981', icon: 'shopping-cart' },
      { id: 'cat-2', name: 'Food & Dining', color: '#f59e0b', icon: 'utensils' },
      { id: 'cat-3', name: 'Transportation', color: '#6366f1', icon: 'car' },
    ]);
  });

  const baseState: AssistantState = {
    userId: '507f1f77bcf86cd799439011',
    conversationId: 'test-convo-1',
    message: '',
    locale: 'en_IN',
    activeDraft: null,
    intent: 'fallback',
    extractedAmountMinor: undefined,
    detectedCategory: undefined,
    extractedPaymentMethod: undefined,
    transactionDate: undefined,
    reply: '',
    status: 'idle',
  };

  it('routes to confirm when user confirms and draft is awaiting_confirmation', async () => {
    const state: AssistantState = {
      ...baseState,
      message: 'Yes, save it',
      activeDraft: {
        _id: 'draft-123',
        status: 'awaiting_confirmation',
        amountMinor: 50000,
      } as any,
    };

    const update = await classifyIntentNode(state);
    expect(update.intent).toBe('confirm');
  });

  it('does not route to confirm if user says negative phrases like "not yet"', async () => {
    const state: AssistantState = {
      ...baseState,
      message: "No, don't save it yet",
      activeDraft: {
        _id: 'draft-123',
        status: 'awaiting_confirmation',
        amountMinor: 50000,
      } as any,
    };

    const update = await classifyIntentNode(state);
    expect(update.intent).not.toBe('confirm');
  });

  it('routes to cancel when user cancels an active draft', async () => {
    const state: AssistantState = {
      ...baseState,
      message: 'Cancel draft',
      activeDraft: {
        _id: 'draft-123',
        status: 'awaiting_confirmation',
      } as any,
    };

    const update = await classifyIntentNode(state);
    expect(update.intent).toBe('cancel');
  });

  it('routes to query for expense summary questions', async () => {
    const state: AssistantState = {
      ...baseState,
      message: 'How much have I spent this month?',
    };

    const update = await classifyIntentNode(state);
    expect(update.intent).toBe('query');
  });

  it('routes to create_draft and parses integer amountMinor in paise for voice entry', async () => {
    const state: AssistantState = {
      ...baseState,
      message: 'Spent 750 on groceries',
    };

    const update = await classifyIntentNode(state);
    expect(update.intent).toBe('create_draft');
    expect(update.extractedAmountMinor).toBe(75000); // 750 * 100 paise
    expect(update.detectedCategory?.name).toBe('Groceries');
  });

  it('parses decimal currency values accurately (e.g. ₹500.50 -> 50050 paise)', async () => {
    const state: AssistantState = {
      ...baseState,
      message: 'Paid 500.50 for coffee',
    };

    const update = await classifyIntentNode(state);
    expect(update.intent).toBe('create_draft');
    expect(update.extractedAmountMinor).toBe(50050); // 500.50 * 100 paise
  });

  it('extracts payment method dynamically (e.g. Cash, Credit Card, UPI)', async () => {
    const state: AssistantState = {
      ...baseState,
      message: 'Spent 450 on lunch paid with cash',
    };

    const update = await classifyIntentNode(state);
    expect(update.extractedPaymentMethod).toBe('Cash');
  });

  it('routes to fill_slot when active draft is incomplete and user supplies missing field', async () => {
    // Draft was created with amount 50000, but category was missing
    const state: AssistantState = {
      ...baseState,
      message: 'Groceries',
      activeDraft: {
        _id: 'draft-123',
        status: 'draft',
        amountMinor: 50000,
        missingFields: ['category'],
      } as any,
    };

    const update = await classifyIntentNode(state);
    expect(update.intent).toBe('fill_slot');
    expect(update.detectedCategory?.name).toBe('Groceries');
  });

  it('routes to update_draft when user makes a live correction to an existing draft', async () => {
    const state: AssistantState = {
      ...baseState,
      message: 'Actually make that 600',
      activeDraft: {
        _id: 'draft-123',
        status: 'awaiting_confirmation',
        amountMinor: 75000,
      } as any,
    };

    const update = await classifyIntentNode(state);
    expect(update.intent).toBe('update_draft');
    expect(update.extractedAmountMinor).toBe(60000);
  });

  it('queryAnalyticsNode preserves activeDraft instead of wiping it', async () => {
    vi.spyOn(assistantTools, 'getExpenseSummaryTool').mockResolvedValue({
      monthTotalMinor: 1500000,
      todayTotalMinor: 50000,
      previousMonthTotalMinor: 1200000,
      monthOverMonthChangePercent: 25,
      monthTransactionCount: 42,
    });

    const pendingDraft: any = {
      _id: 'draft-123',
      status: 'awaiting_confirmation',
      amountMinor: 50000,
    };

    const state: AssistantState = {
      ...baseState,
      activeDraft: pendingDraft,
    };

    const result = await queryAnalyticsNode(state);
    // Preserves active draft!
    expect(result.activeDraft).toBe(pendingDraft);
    expect(result.reply).toContain('You have spent ₹15,000 this month');
    expect(result.status).toBe('awaiting_confirmation');
  });

  it('confirmExpenseNode clears activeDraft to null upon successful confirmation', async () => {
    vi.spyOn(assistantTools, 'confirmExpenseTool').mockResolvedValue({
      success: true,
      persistedExpense: {
        amountMinor: 50000,
        description: 'Groceries',
      } as any,
    });

    const state: AssistantState = {
      ...baseState,
      activeDraft: {
        _id: 'draft-123',
        status: 'awaiting_confirmation',
      } as any,
    };

    const result = await confirmExpenseNode(state);
    expect(result.activeDraft).toBeNull();
    expect(result.status).toBe('saved');
    expect(result.reply).toContain('Done! Your Groceries expense of ₹500 has been saved.');
  });

  it('cancelDraftNode clears activeDraft to null upon cancellation', async () => {
    vi.spyOn(assistantTools, 'cancelDraftTool').mockResolvedValue({
      success: true,
      message: 'Expense draft cancelled',
    });

    const state: AssistantState = {
      ...baseState,
      activeDraft: {
        _id: 'draft-123',
        status: 'awaiting_confirmation',
      } as any,
    };

    const result = await cancelDraftNode(state);
    expect(result.activeDraft).toBeNull();
    expect(result.status).toBe('cancelled');
    expect(result.reply).toContain('Cancelled. I have discarded that expense draft.');
  });
});
