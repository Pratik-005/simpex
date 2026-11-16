import { Request, Response, NextFunction } from 'express';
import { expenseService } from './expense.service.js';
import {
  createExpenseSchema,
  updateExpenseSchema,
  queryExpenseSchema,
} from './expense.schema.js';
import { UnauthorizedError } from '../../core/errors/app-error.js';

export class ExpenseController {
  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();

      const idempotencyKey = (req.headers['idempotency-key'] as string) || req.body.idempotencyKey;
      const validated = createExpenseSchema.parse(req.body);

      const { expense, isDuplicate } = await expenseService.createExpense(
        req.user.id,
        validated,
        idempotencyKey
      );

      res.status(isDuplicate ? 200 : 201).json({
        success: true,
        data: expense,
        meta: {
          isDuplicate,
        },
      });
    } catch (err) {
      next(err);
    }
  }

  async getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const validatedQuery = queryExpenseSchema.parse(req.query);
      const result = await expenseService.getExpenses(req.user.id, validatedQuery);

      res.status(200).json({
        success: true,
        data: result.expenses,
        pagination: result.pagination,
      });
    } catch (err) {
      next(err);
    }
  }

  async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const expense = await expenseService.getExpenseById(req.user.id, id);

      res.status(200).json({
        success: true,
        data: expense,
      });
    } catch (err) {
      next(err);
    }
  }

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const validated = updateExpenseSchema.parse(req.body);
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const updated = await expenseService.updateExpense(req.user.id, id, validated);

      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      await expenseService.deleteExpense(req.user.id, id);

      res.status(200).json({
        success: true,
        message: 'Expense deleted successfully',
      });
    } catch (err) {
      next(err);
    }
  }
}

export const expenseController = new ExpenseController();
