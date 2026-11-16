import { Request, Response, NextFunction } from 'express';
import { budgetService } from './budget.service.js';
import {
  createBudgetSchema,
  updateBudgetSchema,
  queryBudgetSchema,
} from './budget.schema.js';
import { UnauthorizedError } from '../../core/errors/app-error.js';

export class BudgetController {
  async getCurrent(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const validated = queryBudgetSchema.parse(req.query);

      const budget = await budgetService.getCurrentBudget(
        req.user.id,
        validated.month,
        validated.year
      );

      res.status(200).json({
        success: true,
        data: budget,
      });
    } catch (err) {
      next(err);
    }
  }

  async setBudget(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const validated = createBudgetSchema.parse(req.body);

      const budget = await budgetService.setBudget(req.user.id, validated);

      res.status(200).json({
        success: true,
        data: budget,
        message: 'Budget set successfully',
      });
    } catch (err) {
      next(err);
    }
  }

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const validated = updateBudgetSchema.parse(req.body);
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;

      const updated = await budgetService.updateBudget(req.user.id, id, validated);

      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }
}

export const budgetController = new BudgetController();
