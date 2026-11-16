import { Router } from 'express';
import { expenseController } from './expense.controller.js';
import { requireAuth } from '../../core/middlewares/auth.middleware.js';

export const expenseRouter = Router();

expenseRouter.use(requireAuth);

expenseRouter.post('/', (req, res, next) => expenseController.create(req, res, next));
expenseRouter.get('/', (req, res, next) => expenseController.getAll(req, res, next));
expenseRouter.get('/:id', (req, res, next) => expenseController.getById(req, res, next));
expenseRouter.put('/:id', (req, res, next) => expenseController.update(req, res, next));
expenseRouter.delete('/:id', (req, res, next) => expenseController.delete(req, res, next));
