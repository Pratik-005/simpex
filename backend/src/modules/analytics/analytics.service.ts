import mongoose from 'mongoose';
import { Expense } from '../expenses/expense.model.js';

export interface SpendingSummary {
  monthTotalMinor: number;
  todayTotalMinor: number;
  previousMonthTotalMinor: number;
  monthOverMonthChangePercent: number;
  monthTransactionCount: number;
}

export interface CategoryBreakdownItem {
  categoryId: string;
  categoryName: string;
  color: string;
  icon: string;
  totalMinor: number;
  transactionCount: number;
  percentageOfTotal: number;
}

export class AnalyticsService {
  async getSpendingSummary(userId: string): Promise<SpendingSummary> {
    const userObjectId = new mongoose.Types.ObjectId(userId);
    const now = new Date();

    // Start of current month & end of current month
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfNextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);

    // Start of today & end of today
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    // Start of previous month & end of previous month
    const startOfPrevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const endOfPrevMonth = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);

    const [monthAgg, todayAgg, prevMonthAgg] = await Promise.all([
      // Current Month
      Expense.aggregate([
        {
          $match: {
            userId: userObjectId,
            status: 'active',
            transactionDate: { $gte: startOfMonth, $lt: startOfNextMonth },
          },
        },
        {
          $group: {
            _id: null,
            totalMinor: { $sum: '$amountMinor' },
            count: { $sum: 1 },
          },
        },
      ]),

      // Today
      Expense.aggregate([
        {
          $match: {
            userId: userObjectId,
            status: 'active',
            transactionDate: { $gte: startOfToday, $lte: endOfToday },
          },
        },
        {
          $group: {
            _id: null,
            totalMinor: { $sum: '$amountMinor' },
          },
        },
      ]),

      // Previous Month
      Expense.aggregate([
        {
          $match: {
            userId: userObjectId,
            status: 'active',
            transactionDate: { $gte: startOfPrevMonth, $lte: endOfPrevMonth },
          },
        },
        {
          $group: {
            _id: null,
            totalMinor: { $sum: '$amountMinor' },
          },
        },
      ]),
    ]);

    const monthTotalMinor = monthAgg[0]?.totalMinor ?? 0;
    const monthTransactionCount = monthAgg[0]?.count ?? 0;
    const todayTotalMinor = todayAgg[0]?.totalMinor ?? 0;
    const previousMonthTotalMinor = prevMonthAgg[0]?.totalMinor ?? 0;

    let monthOverMonthChangePercent = 0;
    if (previousMonthTotalMinor > 0) {
      monthOverMonthChangePercent = Math.round(
        ((monthTotalMinor - previousMonthTotalMinor) / previousMonthTotalMinor) * 100
      );
    }

    return {
      monthTotalMinor,
      todayTotalMinor,
      previousMonthTotalMinor,
      monthOverMonthChangePercent,
      monthTransactionCount,
    };
  }

  async getCategoryBreakdown(
    userId: string,
    startDate?: Date,
    endDate?: Date
  ): Promise<CategoryBreakdownItem[]> {
    const userObjectId = new mongoose.Types.ObjectId(userId);
    const now = new Date();

    const start = startDate ?? new Date(now.getFullYear(), now.getMonth(), 1);
    const end = endDate ?? new Date(now.getFullYear(), now.getMonth() + 1, 1);

    const breakdown = await Expense.aggregate([
      {
        $match: {
          userId: userObjectId,
          status: 'active',
          transactionDate: { $gte: start, $lt: end },
        },
      },
      {
        $group: {
          _id: '$categoryId',
          totalMinor: { $sum: '$amountMinor' },
          count: { $sum: 1 },
        },
      },
      {
        $lookup: {
          from: 'categories',
          localField: '_id',
          foreignField: '_id',
          as: 'category',
        },
      },
      {
        $unwind: '$category',
      },
      {
        $project: {
          categoryId: { $toString: '$_id' },
          categoryName: '$category.name',
          color: '$category.color',
          icon: '$category.icon',
          totalMinor: 1,
          transactionCount: '$count',
        },
      },
      {
        $sort: { totalMinor: -1 },
      },
    ]);

    const grandTotal = breakdown.reduce((acc, cur) => acc + cur.totalMinor, 0);

    return breakdown.map((item) => ({
      ...item,
      percentageOfTotal:
        grandTotal > 0 ? Number(((item.totalMinor / grandTotal) * 100).toFixed(1)) : 0,
    }));
  }
}

export const analyticsService = new AnalyticsService();
