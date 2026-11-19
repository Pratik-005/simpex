import type { IExpense } from '../expenses/expense.model.js';

export type AssistantIntent = 'record_expense' | 'expense_query' | 'confirm' | 'cancel' | 'general';
export type AssistantStatus = 'collecting' | 'awaiting_confirmation' | 'saved' | 'cancelled' | 'answered' | 'needs_clarification';

export interface TransactionDraft {
  draftId: string;
  amountMinor?: number;
  currency: string;
  categoryId?: string;
  categoryName?: string;
  description?: string;
  transactionDate?: string;
  paymentMethod?: 'UPI' | 'Cash' | 'Credit Card' | 'Debit Card' | 'Apple Pay' | 'Other';
  notes?: string;
}

export interface AssistantInput {
  userId: string;
  conversationId: string;
  message: string;
  timezone?: string;
  locale?: string;
}

export interface AssistantResponse {
  reply: string;
  status: AssistantStatus;
  pendingTransaction: TransactionDraft | null;
  expense?: IExpense | null;
}


