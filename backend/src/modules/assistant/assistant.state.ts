import { Annotation, messagesStateReducer } from '@langchain/langgraph';
import type { BaseMessage } from '@langchain/core/messages';
import type { AssistantIntent, AssistantStatus, TransactionDraft } from './assistant.types.js';

export const AssistantState = Annotation.Root({
  messages: Annotation<BaseMessage[]>({
    reducer: (current, update) => messagesStateReducer(current.slice(-12), update),
    default: () => [],
  }),
  // Trusted values are inserted by the authenticated controller; the LLM never writes these.
  userId: Annotation<string>(),
  conversationId: Annotation<string>(),
  timezone: Annotation<string>(),
  locale: Annotation<string>(),
  intent: Annotation<AssistantIntent>({
    reducer: (_, update) => update,
    default: () => 'general',
  }),
  extracted: Annotation<Record<string, unknown> | null>({
    reducer: (_, update) => update,
    default: () => null
  }),
  pendingTransaction: Annotation<TransactionDraft | null>({
    reducer: (_previous, update) => update,
    default: () => null,
  }),
  status: Annotation<AssistantStatus>({
    reducer: (_, update) => update,
    default: () => 'collecting'
  }),
  reply: Annotation<string>({
    reducer: (_, update) => update, default: () => ''
  }),
  queryResult: Annotation<unknown>({
    reducer: (_, update) => update,
    default: () => null
  }),
});

export type AssistantStateType = typeof AssistantState.State;






