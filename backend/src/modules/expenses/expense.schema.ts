import { z } from 'zod';

const objectIdRegex = /^[0-9a-fA-F]{24}$/;

export const createExpenseSchema = z.object({
  amountMinor: z
    .number()
    .int('Amount must be an integer in minor units (paise)')
    .positive('Amount must be greater than zero'),
  currency: z.string().length(3).default('INR'),
  categoryId: z.string().regex(objectIdRegex, 'Invalid category ID format'),
  description: z.string().min(1, 'Description is required').max(200).trim(),
  transactionDate: z.coerce.date().default(() => new Date()),
  paymentMethod: z
    .enum(['UPI', 'Cash', 'Credit Card', 'Debit Card', 'Apple Pay', 'Other'])
    .default('UPI'),
  idempotencyKey: z.string().trim().optional(),
  notes: z.string().max(500).trim().optional(),
});

export const updateExpenseSchema = z.object({
  amountMinor: z.number().int().positive().optional(),
  currency: z.string().length(3).optional(),
  categoryId: z.string().regex(objectIdRegex, 'Invalid category ID format').optional(),
  description: z.string().min(1).max(200).trim().optional(),
  transactionDate: z.coerce.date().optional(),
  paymentMethod: z
    .enum(['UPI', 'Cash', 'Credit Card', 'Debit Card', 'Apple Pay', 'Other'])
    .optional(),
  notes: z.string().max(500).trim().optional(),
});

export const queryExpenseSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  startDate: z.coerce.date().optional(),
  endDate: z.coerce.date().optional(),
  categoryId: z.string().regex(objectIdRegex).optional(),
  minAmount: z.coerce.number().int().positive().optional(),
  maxAmount: z.coerce.number().int().positive().optional(),
  search: z.string().trim().optional(),
});

export type CreateExpenseDto = z.infer<typeof createExpenseSchema>;
export type UpdateExpenseDto = z.infer<typeof updateExpenseSchema>;
export type QueryExpenseDto = z.infer<typeof queryExpenseSchema>;
