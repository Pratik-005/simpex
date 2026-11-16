import { Router } from 'express';
import { syncController } from './sync.controller.js';
import { requireAuth } from '../../core/middlewares/auth.middleware.js';

export const syncRouter = Router();

syncRouter.use(requireAuth);

syncRouter.post('/batch', (req, res, next) => syncController.batchSync(req, res, next));
