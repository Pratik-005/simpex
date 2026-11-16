import { Router } from 'express';
import { budgetController } from './budget.controller.js';
import { requireAuth } from '../../core/middlewares/auth.middleware.js';

export const budgetRouter = Router();

budgetRouter.use(requireAuth);

budgetRouter.get('/current', (req, res, next) => budgetController.getCurrent(req, res, next));
budgetRouter.post('/', (req, res, next) => budgetController.setBudget(req, res, next));
budgetRouter.patch('/:id', (req, res, next) => budgetController.update(req, res, next));
