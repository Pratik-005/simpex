import { StateGraph, START, END } from '@langchain/langgraph';
import { assistantStateClient } from './persistence/assistant.checkpointer.js';
import { AssistantState } from './assistant.state.js';
import {
  understandMessageNode,
  collectTransactionNode,
  confirmTransactionNode,
  cancelTransactionNode,
  expenseQueryNode,
  generalNode,
} from './assistant.nodes.js';
import type { AssistantInput, AssistantResponse } from './assistant.types.js';

const graphBuilder = new StateGraph(AssistantState)
  .addNode('understandMessage', understandMessageNode)
  .addNode('collectTransaction', collectTransactionNode)
  .addNode('confirmTransaction', confirmTransactionNode)
  .addNode('cancelTransaction', cancelTransactionNode)
  .addNode('expenseQuery', expenseQueryNode)
  .addNode('general', generalNode)
  .addEdge(START, 'understandMessage')
  .addConditionalEdges('understandMessage', (state) => {
    if (state.intent === 'confirm' && state.pendingTransaction) return 'confirmTransaction';
    if (state.intent === 'cancel' && state.pendingTransaction) return 'cancelTransaction';
    if (state.intent === 'record_expense') return 'collectTransaction';
    if (state.intent === 'expense_query') return 'expenseQuery';
    return 'general';
  }, {
    collectTransaction: 'collectTransaction',
    confirmTransaction: 'confirmTransaction',
    cancelTransaction: 'cancelTransaction',
    expenseQuery: 'expenseQuery',
    general: 'general',
  })
  .addEdge('collectTransaction', END)
  .addEdge('confirmTransaction', END)
  .addEdge('cancelTransaction', END)
  .addEdge('expenseQuery', END)
  .addEdge('general', END);

let compiledGraph: ReturnType<typeof graphBuilder.compile> | null = null;
let setupPromise: Promise<void> | null = null;

export const getAssistantGraph = async () => {
  if (compiledGraph) return compiledGraph;
  if (!setupPromise) {
    setupPromise = (async () => {
      const saver = await assistantStateClient.getSaver();
      compiledGraph = graphBuilder.compile({ checkpointer: saver });
    })();
  }
  await setupPromise;
  if (!compiledGraph) throw new Error('Assistant graph failed to initialize');
  return compiledGraph;
};

export const invokeAssistantGraph = async (input: AssistantInput): Promise<AssistantResponse> => {
  const graph = await getAssistantGraph();
  const threadId = `${input.userId}:${input.conversationId}`;
  const result = await graph.invoke({
    userId: input.userId,
    conversationId: input.conversationId,
    timezone: input.timezone || 'Asia/Kolkata',
    locale: input.locale || 'en_IN',
    messages: [{ role: 'user', content: input.message }],
  }, { configurable: { thread_id: threadId } });

  return {
    reply: result.reply,
    status: result.status,
    pendingTransaction: result.pendingTransaction,
    expense: result.status === 'saved' ? result.queryResult as AssistantResponse['expense'] : undefined,
  };
};
