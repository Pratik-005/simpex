import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../../modules/auth/token.util.js';
import { UnauthorizedError } from '../errors/app-error.js';

export const requireAuth = (req: Request, _res: Response, next: NextFunction): void => {

  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new UnauthorizedError('Authorization header with Bearer token is required');
  }

  const token = authHeader.split(' ')[1];
  if (!token) {
    throw new UnauthorizedError('Authentication token missing');
  }

  const payload = verifyAccessToken(token);
  req.user = {
    id: payload.sub,
    email: payload.email,
  };

  next();
};
