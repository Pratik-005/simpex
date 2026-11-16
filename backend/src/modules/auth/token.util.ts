import argon2 from 'argon2';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env.config.js';
import { UnauthorizedError } from '../../core/errors/app-error.js';

export interface TokenPayload {
  sub: string;
  email: string;
}

export const hashPassword = async (password: string): Promise<string> => {
  return argon2.hash(password, {
    type: argon2.argon2id,
    memoryCost: 2 ** 16, // 64 MB
    timeCost: 3,
    parallelism: 1,
  });
};

export const verifyPassword = async (hash: string, plain: string): Promise<boolean> => {
  return argon2.verify(hash, plain);
};

export const generateTokens = (userId: string, email: string) => {
  const payload: TokenPayload = { sub: userId, email };

  const accessToken = jwt.sign(payload, env.JWT_SECRET, {
    expiresIn: env.JWT_EXPIRES_IN as jwt.SignOptions['expiresIn'],
  });

  const refreshToken = jwt.sign({ sub: userId }, env.REFRESH_TOKEN_SECRET, {
    expiresIn: env.REFRESH_TOKEN_EXPIRES_IN as jwt.SignOptions['expiresIn'],
  });

  return { accessToken, refreshToken };
};

export const verifyAccessToken = (token: string): TokenPayload => {
  try {
    return jwt.verify(token, env.JWT_SECRET) as TokenPayload;
  } catch (err) {
    throw new UnauthorizedError('Invalid or expired access token');
  }
};

export const verifyRefreshToken = (token: string): { sub: string } => {
  try {
    return jwt.verify(token, env.REFRESH_TOKEN_SECRET) as { sub: string };
  } catch (err) {
    throw new UnauthorizedError('Invalid or expired refresh token');
  }
};
