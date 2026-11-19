import { invokeAssistantGraph } from './assistant.graph.js';
import type { AssistantInput, AssistantResponse } from './assistant.types.js';

export class AssistantService {
  async run(input: AssistantInput): Promise<AssistantResponse> {
    return invokeAssistantGraph(input);
  }
}

export const assistantService = new AssistantService();

