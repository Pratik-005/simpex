import { Request, Response, NextFunction } from 'express';
import { syncService } from './sync.service.js';
import { batchSyncSchema } from './sync.schema.js';
import { UnauthorizedError } from '../../core/errors/app-error.js';

export class SyncController {
  async batchSync(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const validated = batchSyncSchema.parse(req.body);
      const result = await syncService.processBatch(req.user.id, validated);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }
}

export const syncController = new SyncController();
