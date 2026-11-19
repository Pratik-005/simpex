import OpenAI from 'openai';
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

const openai = new OpenAI({
  apiKey: env.NVIDIA_API_KEY,
  baseURL: 'https://integrate.api.nvidia.com/v1',
});

export class AssistantLlm {

  async extract(message: string, timezone: string, locale: string): Promise<ExtractedMessage> {
    const now = new Date().toLocaleString('en-US', { timeZone: timezone });

    const completion = await openai.chat.completions.create({
      model: env.NVIDIA_MODEL_NAME,
      messages: [
        { role: 'system', content: EXTRACTION_SYSTEM_PROMPT },
        {
          role: 'user',
          content: JSON.stringify({ message, currentLocalDateTime: now, timezone, locale }),
        },
      ],
      temperature: 0,
      max_tokens: 1024,
      response_format: { type: 'json_object' },
    });

    const content = completion.choices[0]?.message?.content;
    if (!content) {
      logger.error('NVIDIA model returned an empty response');
      throw new Error('Assistant model returned an empty response');
    }

    // Strip <think>...</think> blocks that some reasoning models emit
    const cleaned = content.replace(/<think>[\s\S]*?<\/think>/g, '').trim();

    let parsed: unknown;
    try {
      parsed = JSON.parse(cleaned);
    } catch {
      logger.error({ raw: cleaned }, 'NVIDIA model returned invalid JSON');
      throw new Error('Assistant model returned invalid JSON');
    }
    return extractionSchema.parse(parsed);
  }
}

export const assistantLlm = new AssistantLlm();
