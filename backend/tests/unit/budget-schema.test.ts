import { describe, it, expect } from 'vitest';
import {
  createBudgetSchema,
  updateBudgetSchema,
  queryBudgetSchema,
} from '../../src/modules/budgets/budget.schema.js';

describe('Budget Schema Validation', () => {
  it('accepts valid budget data with integer amountMinor', () => {
    const valid = {
      amountMinor: 4500000, // ₹45,000.00
      month: 10,
      year: 2026,
    };

    const parsed = createBudgetSchema.safeParse(valid);
    expect(parsed.success).toBe(true);
    if (parsed.success) {
      expect(parsed.data.amountMinor).toBe(4500000);
      expect(parsed.data.month).toBe(10);
      expect(parsed.data.year).toBe(2026);
    }
  });

  it('supplies default month and year when omitted', () => {
    const valid = {
      amountMinor: 3000000,
    };

    const parsed = createBudgetSchema.safeParse(valid);
    expect(parsed.success).toBe(true);
    if (parsed.success) {
      const now = new Date();
      expect(parsed.data.month).toBe(now.getMonth() + 1);
      expect(parsed.data.year).toBe(now.getFullYear());
    }
  });

  it('rejects non-integer or negative budget amounts', () => {
    const negative = {
      amountMinor: -1000,
      month: 10,
      year: 2026,
    };
    expect(createBudgetSchema.safeParse(negative).success).toBe(false);

    const zero = {
      amountMinor: 0,
      month: 10,
      year: 2026,
    };
    expect(createBudgetSchema.safeParse(zero).success).toBe(false);

    const float = {
      amountMinor: 4500.5,
      month: 10,
      year: 2026,
    };
    expect(createBudgetSchema.safeParse(float).success).toBe(false);
  });

  it('rejects invalid months (< 1 or > 12)', () => {
    expect(
      createBudgetSchema.safeParse({ amountMinor: 100000, month: 0, year: 2026 }).success
    ).toBe(false);
    expect(
      createBudgetSchema.safeParse({ amountMinor: 100000, month: 13, year: 2026 }).success
    ).toBe(false);
  });

  it('validates updateBudgetSchema correctly', () => {
    expect(updateBudgetSchema.safeParse({ amountMinor: 5500000 }).success).toBe(true);
    expect(updateBudgetSchema.safeParse({ amountMinor: 0 }).success).toBe(false);
    expect(updateBudgetSchema.safeParse({ amountMinor: -500 }).success).toBe(false);
  });

  it('validates queryBudgetSchema correctly', () => {
    const query = queryBudgetSchema.safeParse({ month: '10', year: '2026' });
    expect(query.success).toBe(true);
    if (query.success) {
      expect(query.data.month).toBe(10);
      expect(query.data.year).toBe(2026);
    }
  });
});
