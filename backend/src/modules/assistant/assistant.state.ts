import { Annotation, messagesStateReducer } from '@langchain/langgraph';
import type { BaseMessage } from '@langchain/core/messages';
import type { AssistantIntent, AssistantStatus, TransactionDraft } from './assistant.types.js';

export const AssistantState = Annotation.Root({
  messages: Annotation<BaseMessage[]>({
    reducer: messagesStateReducer,
    default: () => [],
  }),
  // These values are supplied by authenticated server code, never by the model.
  userId: Annotation<string>(),
  conversationId: Annotation<string>(),
  timezone: Annotation<string>(),
  locale: Annotation<string>(),
  intent: Annotation<AssistantIntent>({ default: () => 'general' }),
  extracted: Annotation<Record<string, unknown> | null>({ default: () => null }),
  pendingTransaction: Annotation<TransactionDraft | null>({
    reducer: (_previous, update) => update,
    default: () => null,
  }),
  status: Annotation<AssistantStatus>({ default: () => 'collecting' }),
  reply: Annotation<string>({ default: () => '' }),
  queryResult: Annotation<unknown>({ default: () => null }),
});

export type AssistantStateType = typeof AssistantState.State;
