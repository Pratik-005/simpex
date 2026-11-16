import mongoose, { FilterQuery } from 'mongoose';
import { Expense, IExpense } from './expense.model.js';
import { Category } from '../categories/category.model.js';
import { CreateExpenseDto, UpdateExpenseDto, QueryExpenseDto } from './expense.schema.js';
import { NotFoundError, BadRequestError } from '../../core/errors/app-error.js';

export class ExpenseService {
  async createExpense(
    userId: string,
    dto: CreateExpenseDto,
    idempotencyKey?: string
  ): Promise<{ expense: IExpense; isDuplicate: boolean }> {
    const effectiveKey = idempotencyKey ?? dto.idempotencyKey;

    // 1. Check idempotency key to prevent duplicates
    if (effectiveKey) {
      const existing = await Expense.findOne({
        userId: new mongoose.Types.ObjectId(userId),
        idempotencyKey: effectiveKey,
      }).populate('categoryId', 'name color icon');

      if (existing) {
        return { expense: existing, isDuplicate: true };
      }
    }

    // 2. Verify or resolve category
    const cleanCat = dto.categoryId.replace(/_/g, ' ').trim();
    const isObjectId = mongoose.Types.ObjectId.isValid(dto.categoryId);

    let targetCategory = null;
    if (isObjectId) {
      targetCategory = await Category.findOne({
        _id: new mongoose.Types.ObjectId(dto.categoryId),
        $or: [
          { isDefault: true },
          { userId: new mongoose.Types.ObjectId(userId) },
        ],
        isActive: true,
      });
    }

    if (!targetCategory) {
      const searchTerms = [
        cleanCat,
        cleanCat.replace(/&/g, 'and'),
        cleanCat.replace(/and/g, '&'),
      ];
      targetCategory = await Category.findOne({
        $and: [
          {
            $or: searchTerms.flatMap((term) => [
              { name: new RegExp(`^${term}$`, 'i') },
              { name: new RegExp(term, 'i') },
            ]),
          },
          {
            $or: [
              { isDefault: true },
              { userId: new mongoose.Types.ObjectId(userId) },
            ],
          },
        ],
        isActive: true,
      });
    }

    if (!targetCategory) {
      targetCategory = await Category.findOne({ isDefault: true, isActive: true });
    }

    if (!targetCategory) {
      targetCategory = await Category.create({
        name: 'General',
        color: '#10B981',
        icon: 'payments',
        isDefault: true,
        isActive: true,
      });
    }

    // 3. Create Expense
    const expense = await Expense.create({
      ...dto,
      userId: new mongoose.Types.ObjectId(userId),
      categoryId: targetCategory._id,
      idempotencyKey: effectiveKey,
      status: 'active',
    });

    await expense.populate('categoryId', 'name color icon');

    return { expense, isDuplicate: false };
  }

  async getExpenses(userId: string, query: QueryExpenseDto) {
    const filter: FilterQuery<IExpense> = {
      userId: new mongoose.Types.ObjectId(userId),
      status: 'active',
    };

    if (query.categoryId && mongoose.Types.ObjectId.isValid(query.categoryId)) {
      filter.categoryId = new mongoose.Types.ObjectId(query.categoryId);
    }

    if (query.startDate || query.endDate) {
      filter.transactionDate = {};
      if (query.startDate) filter.transactionDate.$gte = query.startDate;
      if (query.endDate) filter.transactionDate.$lte = query.endDate;
    }

    if (query.minAmount || query.maxAmount) {
      filter.amountMinor = {};
      if (query.minAmount) filter.amountMinor.$gte = query.minAmount;
      if (query.maxAmount) filter.amountMinor.$lte = query.maxAmount;
    }

    if (query.search) {
      filter.description = { $regex: query.search, $options: 'i' };
    }

    const skip = (query.page - 1) * query.limit;

    const [expenses, total] = await Promise.all([
      Expense.find(filter)
        .populate('categoryId', 'name color icon')
        .sort({ transactionDate: -1, createdAt: -1 })
        .skip(skip)
        .limit(query.limit),
      Expense.countDocuments(filter),
    ]);

    const totalPages = Math.ceil(total / query.limit);
    const hasMore = query.page < totalPages;
    const nextPage = hasMore ? query.page + 1 : null;

    return {
      expenses,
      pagination: {
        page: query.page,
        limit: query.limit,
        total,
        totalPages,
        hasMore,
        nextPage,
      },
    };
  }

  async getExpenseById(userId: string, expenseId: string): Promise<IExpense> {
    const expense = await Expense.findOne({
      _id: new mongoose.Types.ObjectId(expenseId),
      userId: new mongoose.Types.ObjectId(userId),
      status: 'active',
    }).populate('categoryId', 'name color icon');

    if (!expense) {
      throw new NotFoundError('Expense not found');
    }

    return expense;
  }

  async updateExpense(
    userId: string,
    expenseId: string,
    dto: UpdateExpenseDto
  ): Promise<IExpense> {
    const expense = await Expense.findOne({
      _id: new mongoose.Types.ObjectId(expenseId),
      userId: new mongoose.Types.ObjectId(userId),
      status: 'active',
    });

    if (!expense) {
      throw new NotFoundError('Expense not found');
    }

    if (dto.categoryId) {
      const categoryExists = await Category.exists({
        _id: new mongoose.Types.ObjectId(dto.categoryId),
        $or: [
          { isDefault: true },
          { userId: new mongoose.Types.ObjectId(userId) },
        ],
        isActive: true,
      });

      if (!categoryExists) {
        throw new BadRequestError('Invalid or inactive category');
      }
      expense.categoryId = new mongoose.Types.ObjectId(dto.categoryId);
    }

    if (dto.amountMinor !== undefined) expense.amountMinor = dto.amountMinor;
    if (dto.description !== undefined) expense.description = dto.description;
    if (dto.transactionDate !== undefined) expense.transactionDate = dto.transactionDate;
    if (dto.paymentMethod !== undefined) expense.paymentMethod = dto.paymentMethod;
    if (dto.currency !== undefined) expense.currency = dto.currency;
    if (dto.notes !== undefined) expense.notes = dto.notes;

    await expense.save();
    await expense.populate('categoryId', 'name color icon');

    return expense;
  }

  async deleteExpense(userId: string, expenseId: string): Promise<void> {
    const result = await Expense.findOneAndUpdate(
      {
        _id: new mongoose.Types.ObjectId(expenseId),
        userId: new mongoose.Types.ObjectId(userId),
        status: 'active',
      },
      { $set: { status: 'deleted' } }
    );

    if (!result) {
      throw new NotFoundError('Expense not found');
    }
  }
}

export const expenseService = new ExpenseService();
