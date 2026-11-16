import mongoose from 'mongoose';
import { SyncOperation } from './sync-operation.model.js';
import { BatchSyncDto, SyncOperationItemDto } from './sync.schema.js';
import { expenseService } from '../expenses/expense.service.js';
import { createExpenseSchema, updateExpenseSchema } from '../expenses/expense.schema.js';
import { logger } from '../../core/utils/logger.js';

export interface SyncItemResult {
  operationId: string;
  action: string;
  status: 'synced' | 'duplicate' | 'failed';
  entityId?: string;
  error?: string;
}

export class SyncService {
  async processBatch(userId: string, dto: BatchSyncDto) {
    const results: SyncItemResult[] = [];
    let syncedCount = 0;
    let duplicateCount = 0;
    let failedCount = 0;

    for (const op of dto.operations) {
      try {
        const itemResult = await this.processSingleOperation(userId, op);
        results.push(itemResult);

        if (itemResult.status === 'synced') syncedCount++;
        else if (itemResult.status === 'duplicate') duplicateCount++;
        else failedCount++;
      } catch (err: unknown) {
        const errorMessage = err instanceof Error ? err.message : 'Unknown sync processing error';
        logger.error({ err, operationId: op.operationId }, 'Failed to process sync item');

        results.push({
          operationId: op.operationId,
          action: op.action,
          status: 'failed',
          error: errorMessage,
        });
        failedCount++;
      }
    }

    return {
      total: dto.operations.length,
      synced: syncedCount,
      duplicates: duplicateCount,
      failed: failedCount,
      results,
    };
  }

  private async processSingleOperation(
    userId: string,
    op: SyncOperationItemDto
  ): Promise<SyncItemResult> {
    const userObjectId = new mongoose.Types.ObjectId(userId);

    // 1. Check idempotency: If this operationId has already been recorded for this user
    const existingOp = await SyncOperation.findOne({
      userId: userObjectId,
      operationId: op.operationId,
    });

    if (existingOp) {
      return {
        operationId: op.operationId,
        action: op.action,
        status: 'duplicate',
        entityId: existingOp.resultEntityId?.toString(),
      };
    }

    // 2. Execute Action
    let entityId: string | undefined;

    switch (op.action) {
      case 'create': {
        const validated = createExpenseSchema.parse(op.data);
        const { expense } = await expenseService.createExpense(
          userId,
          validated,
          op.operationId
        );
        entityId = expense._id.toString();
        break;
      }

      case 'update': {
        const expenseId = op.data.id || op.data._id;
        if (!expenseId) {
          throw new Error('Expense ID is required for update action');
        }
        const validated = updateExpenseSchema.parse(op.data);
        const expense = await expenseService.updateExpense(userId, expenseId, validated);
        entityId = expense._id.toString();
        break;
      }

      case 'delete': {
        const expenseId = op.data.id || op.data._id;
        if (!expenseId) {
          throw new Error('Expense ID is required for delete action');
        }
        await expenseService.deleteExpense(userId, expenseId);
        entityId = expenseId;
        break;
      }
    }

    // 3. Record SyncOperation Audit
    await SyncOperation.create({
      userId: userObjectId,
      operationId: op.operationId,
      action: op.action,
      status: 'synced',
      resultEntityId: entityId ? new mongoose.Types.ObjectId(entityId) : undefined,
    });

    return {
      operationId: op.operationId,
      action: op.action,
      status: 'synced',
      entityId,
    };
  }
}

export const syncService = new SyncService();
