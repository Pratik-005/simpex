import { Router } from 'express';
import { authController } from './auth.controller.js';
import { verifyAccessToken } from './token.util.js';
import { requireAuth } from '../../core/middlewares/auth.middleware.js';

export const authRouter = Router();

// Registration & Login Endpoints
authRouter.post('/register', (req, res, next) => authController.register(req, res, next));
authRouter.post('/login', (req, res, next) => authController.login(req, res, next));
authRouter.post('/google', (req, res, next) => authController.googleAuth(req, res, next));
authRouter.post('/oauth/google', (req, res, next) => authController.googleAuth(req, res, next));

// Token Session Management
authRouter.post('/refresh', (req, res, next) => authController.refreshTokens(req, res, next));
authRouter.post('/logout', (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    if (token) {
      try {
        const payload = verifyAccessToken(token);
        req.user = { id: payload.sub, email: payload.email };
      } catch (_) {}
    }
  }
  return authController.logout(req, res, next);
});

// Profile Endpoints
authRouter.get('/me', requireAuth, (req, res, next) => authController.getMe(req, res, next));
authRouter.patch('/me', requireAuth, (req, res, next) => authController.updateMe(req, res, next));
authRouter.put('/me', requireAuth, (req, res, next) => authController.updateMe(req, res, next));
authRouter.patch('/profile', requireAuth, (req, res, next) => authController.updateMe(req, res, next));
