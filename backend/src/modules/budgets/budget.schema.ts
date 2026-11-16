import { z } from 'zod';

export const createBudgetSchema = z.object({
  amountMinor: z
    .number()
    .int('Amount must be an integer in minor units (paise)')
    .positive('Amount must be greater than zero'),
  month: z
    .number()
    .int()
    .min(1, 'Month must be between 1 and 12')
    .max(12, 'Month must be between 1 and 12')
    .default(() => new Date().getMonth() + 1),
  year: z
    .number()
    .int()
    .min(2020, 'Year must be valid')
    .max(2100, 'Year must be valid')
    .default(() => new Date().getFullYear()),
});

export const updateBudgetSchema = z.object({
  amountMinor: z
    .number()
    .int('Amount must be an integer in minor units (paise)')
    .positive('Amount must be greater than zero'),
});

export const queryBudgetSchema = z.object({
  month: z.coerce.number().int().min(1).max(12).optional(),
  year: z.coerce.number().int().min(2020).max(2100).optional(),
});

export type CreateBudgetDto = z.infer<typeof createBudgetSchema>;
export type UpdateBudgetDto = z.infer<typeof updateBudgetSchema>;
export type QueryBudgetDto = z.infer<typeof queryBudgetSchema>;
