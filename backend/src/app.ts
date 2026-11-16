import express, { Express, Request, Response } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { env } from './config/env.config.js';
import { errorHandler } from './core/middlewares/error.middleware.js';
import { ApiResponse } from './core/utils/api-response.js';
import { NotFoundError } from './core/errors/app-error.js';
import { authRouter } from './modules/auth/auth.router.js';
import { categoryRouter } from './modules/categories/category.router.js';
import { expenseRouter } from './modules/expenses/expense.router.js';
import { budgetRouter } from './modules/budgets/budget.router.js';
import { syncRouter } from './modules/sync/sync.router.js';
import { analyticsRouter } from './modules/analytics/analytics.router.js';
import { assistantRouter } from './modules/assistant/assistant.router.js';

export const createApp = (): Express => {

  const app = express();

  app.use(helmet());
  app.use(
    cors({
      origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(','),
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'Idempotency-Key'],
    })
  );
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true, limit: '1mb' }));

  app.get('/', (_req: Request, res: Response) => {
    const uptime = process.uptime();
    const timestamp = new Date().toISOString();
    res.status(200).json({
      success: true,
      data: {
        status: 'UP',
        timestamp,
        uptime,
      },
    });
  });

  app.get(env.API_PREFIX, (_req: Request, res: Response) => {
    ApiResponse.success(res, {
      name: 'Simpex API',
      version: '1.0.0',
      description: 'AI-Powered Voice Expense Tracker API',
      documentation: `${env.API_PREFIX}/docs`,
    });
  });

  app.use(`${env.API_PREFIX}/auth`, authRouter);
  app.use(`${env.API_PREFIX}/categories`, categoryRouter);
  app.use(`${env.API_PREFIX}/expenses`, expenseRouter);
  app.use(`${env.API_PREFIX}/budgets`, budgetRouter);
  app.use(`${env.API_PREFIX}/sync`, syncRouter);
  app.use(`${env.API_PREFIX}/analytics`, analyticsRouter);
  app.use(`${env.API_PREFIX}/assistant`, assistantRouter);

  app.use((req: Request) => {
    throw new NotFoundError(`Endpoint '${req.method} ${req.originalUrl}' not found`);
  });

  app.use(errorHandler);

  return app;
};
