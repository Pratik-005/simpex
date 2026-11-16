import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { assistantController } from './assistant.controller.js';
import { requireAuth } from '../../core/middlewares/auth.middleware.js';

export const assistantRouter = Router();

const aiRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 30, // 30 requests per minute per IP/user
  message: {
    success: false,
    error: {
      code: 'TOO_MANY_REQUESTS',
      message: 'Too many voice assistant requests. Please wait a moment before trying again.',
      details: null,
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

assistantRouter.use(requireAuth);
assistantRouter.use(aiRateLimiter);

assistantRouter.post('/chat', (req, res, next) => assistantController.handleChat(req, res, next));


