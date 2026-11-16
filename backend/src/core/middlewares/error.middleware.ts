import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import mongoose from 'mongoose';
import { AppError } from '../errors/app-error.js';
import { logger } from '../utils/logger.js';

export const errorHandler = (
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): void => {
  const requestContext = {
    method: req.method,
    url: req.originalUrl,
  };

  // 1. Handled AppError instances (400, 401, 403, 404, 409, 422, etc.)
  if (err instanceof AppError) {
    if (err.statusCode >= 500) {
      logger.error({ ...requestContext, err, code: err.errorCode }, err.message);
    }
    res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.errorCode,
        message: err.message,
        details: err.details ?? null,
      },
    });
    return;
  }

  // 2. Zod validation errors (422)
  if (err instanceof ZodError) {
    const formattedDetails = err.errors.map((e) => ({
      field: e.path.join('.'),
      message: e.message,
      code: e.code,
    }));

    res.status(422).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Request payload validation failed',
        details: formattedDetails,
      },
    });
    return;
  }

  // 3. Mongoose CastError (e.g. invalid ObjectId format)
  if (err instanceof mongoose.Error.CastError) {

    res.status(400).json({
      success: false,
      error: {
        code: 'INVALID_ID',
        message: `Invalid format for field '${err.path}'`,
        details: null,
      },
    });
    return;
  }

  // 4. Mongoose Duplicate Key Error (Code 11000)
  if ('code' in err && (err as { code: unknown }).code === 11000) {

    res.status(409).json({
      success: false,
      error: {
        code: 'DUPLICATE_KEY_CONFLICT',
        message: 'A resource with this key already exists',
        details: null,
      },
    });
    return;
  }

  // 5. Unhandled unexpected errors (500)
  logger.error({ ...requestContext, err }, 'Unhandled application exception');

  res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: 'Internal server error occurred',
      details: null,
    },
  });
};
