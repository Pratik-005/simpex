import mongoose from 'mongoose';
import { Budget, IBudget } from './budget.model.js';
import { User } from '../auth/user.model.js';
import { CreateBudgetDto, UpdateBudgetDto } from './budget.schema.js';
import { NotFoundError } from '../../core/errors/app-error.js';

export class BudgetService {
  async getCurrentBudget(
    userId: string,
    month?: number,
    year?: number
  ): Promise<IBudget | null> {
    const now = new Date();
    const targetMonth = month ?? now.getMonth() + 1;
    const targetYear = year ?? now.getFullYear();

    const budget = await Budget.findOne({
      userId: new mongoose.Types.ObjectId(userId),
      month: targetMonth,
      year: targetYear,
    });

    return budget;
  }

  async setBudget(userId: string, dto: CreateBudgetDto): Promise<IBudget> {
    const now = new Date();
    const month = dto.month ?? now.getMonth() + 1;
    const year = dto.year ?? now.getFullYear();

    // Start date is first day of the month at 00:00:00.000
    const startDate = new Date(Date.UTC(year, month - 1, 1, 0, 0, 0, 0));
    // End date is last day of the month at 23:59:59.999
    const endDate = new Date(Date.UTC(year, month, 0, 23, 59, 59, 999));

    // Inherit default currency from user profile
    const user = await User.findById(userId).select('currency');
    const currency = user?.currency || 'INR';

    const budget = await Budget.findOneAndUpdate(
      {
        userId: new mongoose.Types.ObjectId(userId),
        month,
        year,
      },
      {
        $set: {
          amountMinor: dto.amountMinor,
          currency,
          startDate,
          endDate,
        },
      },
      {
        upsert: true,
        new: true,
        setDefaultsOnInsert: true,
      }
    );

    return budget;
  }

  async updateBudget(
    userId: string,
    budgetId: string,
    dto: UpdateBudgetDto
  ): Promise<IBudget> {
    const budget = await Budget.findOne({
      _id: new mongoose.Types.ObjectId(budgetId),
      userId: new mongoose.Types.ObjectId(userId),
    });

    if (!budget) {
      throw new NotFoundError('Budget not found');
    }

    if (dto.amountMinor !== undefined) {
      budget.amountMinor = dto.amountMinor;
    }

    await budget.save();
    return budget;
  }
}

export const budgetService = new BudgetService();
