import mongoose from 'mongoose';
import { z } from 'zod';
import { ExpenseDraft, IExpenseDraft } from '../draft.model.js';
import { Category } from '../../categories/category.model.js';
import { expenseService } from '../../expenses/expense.service.js';
import { analyticsService } from '../../analytics/analytics.service.js';
import { BadRequestError } from '../../../core/errors/app-error.js';

// Helper: Category Resolver with Synonym and Alias Mapping
export const resolveCategory = async (
  userId: string,
  categoryName?: string
): Promise<{ id: mongoose.Types.ObjectId; name: string } | null> => {
  if (!categoryName || categoryName.trim().length === 0) return null;
  if (mongoose.connection.readyState !== 1) return null;

  const userObjId = mongoose.Types.ObjectId.isValid(userId)
    ? new mongoose.Types.ObjectId(userId)
    : undefined;

  const baseFilter = {
    $or: [
      { isDefault: true, isActive: true },
      ...(userObjId ? [{ userId: userObjId, isActive: true }] : []),
    ],
  };

  const cleanInput = categoryName.trim();

  // 1. Exact case-insensitive match
  let matched = await Category.findOne({
    ...baseFilter,
    name: { $regex: new RegExp(`^${cleanInput}$`, 'i') },
  });

  if (matched) {
    return { id: matched._id as mongoose.Types.ObjectId, name: matched.name };
  }

  // 2. Substring & Synonym mapping
  const lower = cleanInput.toLowerCase();
  const synonyms: Record<string, string[]> = {
    groceries: ['grocery', 'supermarket', 'vegetables', 'fruits', 'milk', 'bread', 'veggies', 'kirana', 'provisions'],
    'food & dining': ['food', 'dining', 'dinner', 'lunch', 'breakfast', 'restaurant', 'cafe', 'coffee', 'tea', 'swiggy', 'zomato', 'fast food', 'snack', 'snacks', 'starbucks', 'biryani'],
    transportation: ['transport', 'uber', 'ola', 'fuel', 'petrol', 'diesel', 'cab', 'taxi', 'auto', 'metro', 'bus', 'flight', 'railway', 'train', 'toll'],
    bills: ['bill', 'electricity', 'water', 'wifi', 'broadband', 'internet', 'mobile', 'recharge', 'rent', 'utility', 'utilities', 'gas', 'dth'],
    shopping: ['shop', 'clothes', 'amazon', 'flipkart', 'myntra', 'shoes', 'electronics', 'gadget'],
    entertainment: ['movie', 'movies', 'cinema', 'netflix', 'prime', 'spotify', 'concert', 'game', 'gaming'],
    health: ['doctor', 'medicine', 'pharmacy', 'hospital', 'clinic', 'medical', 'gym', 'fitness'],
    education: ['book', 'books', 'course', 'tuition', 'fee', 'school', 'college', 'exam'],
  };

  for (const [targetName, keywords] of Object.entries(synonyms)) {
    if (keywords.some((k) => lower.includes(k) || k.includes(lower))) {
      matched = await Category.findOne({
        ...baseFilter,
        name: { $regex: new RegExp(targetName, 'i') },
      });
      if (matched) {
        return { id: matched._id as mongoose.Types.ObjectId, name: matched.name };
      }
    }
  }

  // 3. Fallback partial regex search across user/default categories
  matched = await Category.findOne({
    ...baseFilter,
    name: { $regex: new RegExp(cleanInput, 'i') },
  });

  if (matched) {
    return { id: matched._id as mongoose.Types.ObjectId, name: matched.name };
  }

  return null;
};

// 1. Tool: Get Active Expense Categories
export const getCategoriesTool = async (userId: string) => {
  const userObjId = mongoose.Types.ObjectId.isValid(userId)
    ? new mongoose.Types.ObjectId(userId)
    : undefined;

  const categories = await Category.find({
    $or: [
      { isDefault: true, isActive: true },
      ...(userObjId ? [{ userId: userObjId, isActive: true }] : []),
    ],
  }).select('name color icon');

  return categories.map((c) => ({
    id: c._id.toString(),
    name: c.name,
    color: c.color,
    icon: c.icon,
  }));
};

// 2. Tool: Create Expense Draft
export const createDraftSchema = z.object({
  amountMinor: z.number().int().positive().optional(),
  categoryName: z.string().optional(),
  description: z.string().optional(),
  transactionDate: z.coerce.date().optional(),
  paymentMethod: z
    .enum(['UPI', 'Cash', 'Credit Card', 'Debit Card', 'Card', 'Apple Pay', 'Net Banking', 'Other'])
    .default('UPI'),
});

export const createDraftTool = async (
  userId: string,
  conversationId: string,
  args: z.infer<typeof createDraftSchema>
): Promise<IExpenseDraft> => {
  const resolved = await resolveCategory(userId, args.categoryName);
  const categoryId = resolved?.id;
  const resolvedCategoryName = resolved?.name || args.categoryName;

  const missingFields: string[] = [];
  if (!args.amountMinor) missingFields.push('amount');
  if (!categoryId) missingFields.push('category');

  const userObjectId = new mongoose.Types.ObjectId(userId);

  // Cancel any existing pending/drafts for this conversation to prevent stale duplicates
  await ExpenseDraft.updateMany(
    {
      userId: userObjectId,
      conversationId,
      status: { $in: ['draft', 'awaiting_confirmation'] },
    },
    { $set: { status: 'cancelled' } }
  );

  return ExpenseDraft.create({
    userId: userObjectId,
    conversationId,
    amountMinor: args.amountMinor,
    currency: 'INR',
    categoryId,
    categoryName: resolvedCategoryName,
    description: args.description || resolvedCategoryName || 'Expense',
    transactionDate: args.transactionDate || new Date(),
    paymentMethod: args.paymentMethod || 'UPI',
    missingFields,
    status: missingFields.length === 0 ? 'awaiting_confirmation' : 'draft',
  });
};

// 3. Tool: Update Expense Draft (Handles slot-filling & live corrections)
export const updateDraftSchema = z.object({
  amountMinor: z.number().int().positive().optional(),
  categoryName: z.string().optional(),
  description: z.string().optional(),
  transactionDate: z.coerce.date().optional(),
  paymentMethod: z
    .enum(['UPI', 'Cash', 'Credit Card', 'Debit Card', 'Card', 'Apple Pay', 'Net Banking', 'Other'])
    .optional(),
});

export const updateDraftTool = async (
  userId: string,
  conversationId: string,
  args: z.infer<typeof updateDraftSchema>,
  draftId?: string
): Promise<IExpenseDraft> => {
  const userObjectId = new mongoose.Types.ObjectId(userId);
  const filter: any = {
    userId: userObjectId,
    status: { $in: ['draft', 'awaiting_confirmation'] },
  };

  if (draftId && mongoose.Types.ObjectId.isValid(draftId)) {
    filter._id = new mongoose.Types.ObjectId(draftId);
  } else {
    filter.conversationId = conversationId;
  }

  const draft = await ExpenseDraft.findOne(filter).sort({ createdAt: -1 });

  if (!draft) {
    throw new BadRequestError('No active draft found to update in this conversation');
  }

  // Selective Patch Semantics
  if (args.amountMinor !== undefined) draft.amountMinor = args.amountMinor;
  if (args.description !== undefined) draft.description = args.description;
  if (args.transactionDate !== undefined) draft.transactionDate = args.transactionDate;
  if (args.paymentMethod !== undefined) draft.paymentMethod = args.paymentMethod;

  if (args.categoryName !== undefined && args.categoryName.trim().length > 0) {
    const resolved = await resolveCategory(userId, args.categoryName);
    if (resolved) {
      draft.categoryId = resolved.id;
      draft.categoryName = resolved.name;
    } else {
      draft.categoryName = args.categoryName.trim();
    }
  }

  // Recompute missing required fields
  const missingFields: string[] = [];
  if (!draft.amountMinor) missingFields.push('amount');
  if (!draft.categoryId) missingFields.push('category');

  draft.missingFields = missingFields;
  draft.status = missingFields.length === 0 ? 'awaiting_confirmation' : 'draft';

  return draft.save();
};

// 4. Tool: Confirm & Persist Expense (Atomic & Idempotent via draftId)
export const confirmExpenseTool = async (
  userId: string,
  conversationId: string,
  draftId?: string
) => {
  const userObjectId = new mongoose.Types.ObjectId(userId);
  const filter: any = {
    userId: userObjectId,
    status: 'awaiting_confirmation',
  };

  if (draftId && mongoose.Types.ObjectId.isValid(draftId)) {
    filter._id = new mongoose.Types.ObjectId(draftId);
  } else {
    filter.conversationId = conversationId;
  }

  // Atomic conditional transition to prevent double confirmation or race conditions
  const draft = await ExpenseDraft.findOneAndUpdate(
    filter,
    { $set: { status: 'confirmed' } },
    { sort: { createdAt: -1 }, new: true }
  );

  if (!draft || !draft.amountMinor || !draft.categoryId) {
    throw new BadRequestError('No complete draft awaiting confirmation');
  }

  // Create actual verified expense in DB with deterministic idempotency key
  const idempotencyKey = `draft-${draft._id.toString()}`;
  const { expense } = await expenseService.createExpense(
    userId,
    {
      amountMinor: draft.amountMinor,
      currency: draft.currency || 'INR',
      categoryId: draft.categoryId.toString(),
      description: draft.description || draft.categoryName || 'Expense',
      transactionDate: draft.transactionDate,
      paymentMethod: (draft.paymentMethod as any) || 'UPI',
    },
    idempotencyKey
  );

  return {
    success: true,
    persistedExpense: expense,
  };
};

// 5. Tool: Cancel Draft
export const cancelDraftTool = async (
  userId: string,
  conversationId: string,
  draftId?: string
) => {
  const userObjectId = new mongoose.Types.ObjectId(userId);
  const filter: any = {
    userId: userObjectId,
    status: { $in: ['draft', 'awaiting_confirmation'] },
  };

  if (draftId && mongoose.Types.ObjectId.isValid(draftId)) {
    filter._id = new mongoose.Types.ObjectId(draftId);
  } else {
    filter.conversationId = conversationId;
  }

  await ExpenseDraft.updateMany(filter, { $set: { status: 'cancelled' } });

  return { success: true, message: 'Expense draft cancelled' };
};

// 6. Tool: Deterministic Expense Summary Query
export const getExpenseSummaryTool = async (userId: string) => {
  return analyticsService.getSpendingSummary(userId);
};
