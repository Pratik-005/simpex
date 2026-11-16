import { describe, it, expect } from 'vitest';
import { createExpenseSchema } from '../../src/modules/expenses/expense.schema.js';

describe('Expense Schema Validation', () => {
  const validCategoryId = '64e8b3941a2e5d1234567890';

  it('accepts integer minor units (paise)', () => {
    const valid = {
      amountMinor: 50000, // ₹500.00
      categoryId: validCategoryId,
      description: 'Groceries at Whole Foods',
      paymentMethod: 'UPI',
    };

    const parsed = createExpenseSchema.safeParse(valid);
    expect(parsed.success).toBe(true);
    if (parsed.success) {
      expect(parsed.data.amountMinor).toBe(50000);
      expect(parsed.data.currency).toBe('INR');
    }
  });

  it('rejects floating-point numbers for amountMinor', () => {
    const invalid = {
      amountMinor: 500.5,
      categoryId: validCategoryId,
      description: 'Invalid float',
    };

    const parsed = createExpenseSchema.safeParse(invalid);
    expect(parsed.success).toBe(false);
    if (!parsed.success) {
      const err = parsed.error.errors.find((e) => e.path.includes('amountMinor'));
      expect(err).toBeDefined();
    }
  });

  it('rejects negative or zero amounts', () => {
    const zero = {
      amountMinor: 0,
      categoryId: validCategoryId,
      description: 'Zero amount',
    };

    const parsed = createExpenseSchema.safeParse(zero);
    expect(parsed.success).toBe(false);
  });

  it('rejects invalid category ID format', () => {
    const invalid = {
      amountMinor: 1000,
      categoryId: 'invalid-id-not-24-hex',
      description: 'Invalid category',
    };

    const parsed = createExpenseSchema.safeParse(invalid);
    expect(parsed.success).toBe(false);
    if (!parsed.success) {
      const err = parsed.error.errors.find((e) => e.path.includes('categoryId'));
      expect(err).toBeDefined();
    }
  });
});
