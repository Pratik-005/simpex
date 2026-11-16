import { Router } from 'express';
import { categoryController } from './category.controller.js';
import { requireAuth } from '../../core/middlewares/auth.middleware.js';

export const categoryRouter = Router();

categoryRouter.use(requireAuth);

categoryRouter.get('/', (req, res, next) => categoryController.getAll(req, res, next));
categoryRouter.post('/', (req, res, next) => categoryController.create(req, res, next));
categoryRouter.patch('/:id', (req, res, next) => categoryController.update(req, res, next));
categoryRouter.delete('/:id', (req, res, next) => categoryController.delete(req, res, next));
