import { Response } from 'express';

export interface PaginationMeta {
  page: number;
  limit: number;
  totalCount: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPrevPage: boolean;
}

export class ApiResponse {
  static success<T>(
    res: Response,
    data: T,
    statusCode = 200,
    meta?: Record<string, unknown>,
    pagination?: PaginationMeta
  ): void {
    res.status(statusCode).json({
      success: true,
      data,
      ...(meta && { meta }),
      ...(pagination && { pagination }),
    });
  }
}
