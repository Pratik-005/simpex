import { Router } from 'express';
import { analyticsController } from './analytics.controller.js';
import { requireAuth } from '../../core/middlewares/auth.middleware.js';

export const analyticsRouter = Router();

analyticsRouter.use(requireAuth);

analyticsRouter.get('/summary', (req, res, next) => analyticsController.getSummary(req, res, next));
analyticsRouter.get('/category-breakdown', (req, res, next) =>
  analyticsController.getCategoryBreakdown(req, res, next)
);
