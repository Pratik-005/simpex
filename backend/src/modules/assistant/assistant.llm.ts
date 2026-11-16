import { env } from '../../config/env.config.js';
import { logger } from '../../core/utils/logger.js';
import { EXTRACTION_SYSTEM_PROMPT } from './assistant.prompts.js';
import { z } from 'zod';

const extractionSchema = z.object({
  intent: z.enum(['record_expense', 'expense_query', 'confirm', 'cancel', 'general']).catch('general'),
  amount: z.number().positive().finite().nullable().catch(null),
  currency: z.string().length(3).nullable().catch(null),
  category: z.string().trim().min(1).nullable().catch(null),
  description: z.string().trim().max(200).nullable().catch(null),
  transactionDate: z.string().nullable().catch(null),
  paymentMethod: z.enum(['UPI', 'Cash', 'Credit Card', 'Debit Card', 'Apple Pay', 'Other']).nullable().catch(null),
  notes: z.string().max(500).nullable().catch(null),
  query: z.enum(['summary', 'category_breakdown', 'largest_expenses', 'transaction_search']).nullable().catch(null),
  searchTerm: z.string().nullable().catch(null),
});

export type ExtractedMessage = z.infer<typeof extractionSchema>;

export class AssistantLlm {
  async extract(message: string, timezone: string, locale: string): Promise<ExtractedMessage> {
    const now = new Date().toLocaleString('en-US', { timeZone: timezone });
    const response = await fetch(new URL('/api/chat', env.OLLAMA_BASE_URL), {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      signal: AbortSignal.timeout(25_000),
      body: JSON.stringify({
        model: env.SLM_MODEL_NAME,
        stream: false,
        format: 'json',
        messages: [
          { role: 'system', content: EXTRACTION_SYSTEM_PROMPT },
          { role: 'user', content: JSON.stringify({ message, currentLocalDateTime: now, timezone, locale }) },
        ],
        options: { temperature: 0 },
      }),
    });

    if (!response.ok) {
      logger.error({ status: response.status }, 'Ollama extraction request failed');
      throw new Error(`Assistant model returned HTTP ${response.status}`);
    }

    const payload = await response.json() as { message?: { content?: string } };
    const content = payload.message?.content;
    if (!content) throw new Error('Assistant model returned an empty response');

    let parsed: unknown;
    try {
      parsed = JSON.parse(content);
    } catch {
      throw new Error('Assistant model returned invalid JSON');
    }
    return extractionSchema.parse(parsed);
  }
}

export const assistantLlm = new AssistantLlm();
