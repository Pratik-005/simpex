import { Request, Response, NextFunction } from 'express';
import { analyticsService } from './analytics.service.js';
import { UnauthorizedError } from '../../core/errors/app-error.js';
import { z } from 'zod';

const dateRangeQuerySchema = z.object({
  startDate: z.coerce.date().optional(),
  endDate: z.coerce.date().optional(),
});

export class AnalyticsController {
  async getSummary(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const summary = await analyticsService.getSpendingSummary(req.user.id);

      res.status(200).json({
        success: true,
        data: summary,
      });
    } catch (err) {
      next(err);
    }
  }

  async getCategoryBreakdown(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const query = dateRangeQuerySchema.parse(req.query);
      const breakdown = await analyticsService.getCategoryBreakdown(
        req.user.id,
        query.startDate,
        query.endDate
      );

      res.status(200).json({
        success: true,
        data: breakdown,
      });
    } catch (err) {
      next(err);
    }
  }
}

export const analyticsController = new AnalyticsController();
