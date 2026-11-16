import { z } from 'zod';

export const assistantRequestSchema = z.object({
  conversationId: z.string().trim().min(1).max(100),
  message: z.string().trim().min(1).max(1000),
  timezone: z.string().trim().optional(),
  locale: z.string().trim().max(20).optional(),
});

export const isValidTimezone = (timezone: string): boolean => {
  try {
    Intl.DateTimeFormat('en-US', { timeZone: timezone });
    return true;
  } catch {
    return false;
  }
};
