import mongoose from 'mongoose';
import { Expense } from '../expenses/expense.model.js';
import { expenseService } from '../expenses/expense.service.js';
import { Category } from '../categories/category.model.js';
import { analyticsService } from '../analytics/analytics.service.js';
import type { TransactionDraft } from './assistant.types.js';
import { BadRequestError } from '../../core/errors/app-error.js';

export class AssistantTools {

  async getCategories(userId: string) {
    const userObjectId = new mongoose.Types.ObjectId(userId);
    return Category.find({
      isActive: true,
      $or: [{ isDefault: true }, { userId: userObjectId }],
    }).select('_id name');
  }

  async resolveCategory(userId: string, name: string) {
    const categories = await this.getCategories(userId);
    const normalized = name.trim().toLowerCase();
    const exact = categories.find((category) => category.name.toLowerCase() === normalized);
    if (exact) return exact;

    const aliases: Record<string, string[]> = {
      Groceries: ['grocery', 'vegetables', 'fruits', 'milk', 'kirana', 'supermarket'],
      'Food and dining': ['food', 'restaurant', 'lunch', 'dinner', 'breakfast', 'coffee', 'zomato', 'swiggy'],
      Transportation: ['uber', 'ola', 'petrol', 'fuel', 'metro', 'bus', 'taxi', 'auto'],
      Shopping: ['clothes', 'amazon', 'flipkart', 'shoes'],
      'Housing and utilities': ['rent', 'electricity', 'water', 'wifi', 'internet', 'gas'],
      Healthcare: ['doctor', 'medicine', 'pharmacy', 'hospital'],
      Education: ['course', 'tuition', 'school', 'college', 'books'],
      Entertainment: ['movie', 'netflix', 'spotify', 'gaming'],
      Travel: ['flight', 'hotel', 'trip', 'train'],
      'Personal care': ['salon', 'haircut', 'grooming'],
      'Bills and subscriptions': ['recharge', 'subscription', 'bill'],
    };

    for (const category of categories) {
      const synonyms = aliases[category.name] ?? [];
      if (synonyms.some((word) => normalized.includes(word) || word.includes(normalized))) return category;
    }
    return null;
  }

  async saveExpense(userId: string, draft: TransactionDraft) {
    if (!draft.amountMinor || !draft.categoryId || !draft.description?.trim()) {
      throw new BadRequestError('The expense is incomplete and cannot be saved');
    }

    const idempotencyKey = `assistant-${draft.draftId}`;
    try {
      const { expense } = await expenseService.createExpense(userId, {
        amountMinor: draft.amountMinor,
        currency: draft.currency || 'INR',
        categoryId: draft.categoryId,
        description: draft.description.trim(),
        transactionDate: draft.transactionDate ? new Date(draft.transactionDate) : new Date(),
        paymentMethod: draft.paymentMethod || 'UPI',
        notes: draft.notes,
      }, idempotencyKey);
      return expense;
    } catch (error) {
      // A concurrent retry can pass the service's pre-check at the same time.
      // The unique (userId, idempotencyKey) index is the final guard.
      if (typeof error === 'object' && error !== null && 'code' in error && error.code === 11000) {
        const existing = await Expense.findOne({
          userId: new mongoose.Types.ObjectId(userId),
          idempotencyKey,
        }).populate('categoryId', 'name color icon');
        if (existing) return existing;
      }
      throw error;
    }
  }

  async spendingSummary(userId: string) {
    return analyticsService.getSpendingSummary(userId);
  }

  async categoryBreakdown(userId: string) {
    return analyticsService.getCategoryBreakdown(userId);
  }

  async largestExpenses(userId: string, limit = 5) {
    return Expense.find({ userId: new mongoose.Types.ObjectId(userId), status: 'active' })
      .sort({ amountMinor: -1, transactionDate: -1 })
      .limit(Math.min(limit, 10))
      .populate('categoryId', 'name');
  }

  async searchExpenses(userId: string, searchTerm: string) {
    const escaped = searchTerm.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return Expense.find({
      userId: new mongoose.Types.ObjectId(userId),
      status: 'active',
      description: { $regex: escaped, $options: 'i' },
    }).sort({ transactionDate: -1 }).limit(10).populate('categoryId', 'name');
  }
}

export const assistantTools = new AssistantTools();
