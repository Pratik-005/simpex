import { z } from 'zod';

export const syncOperationItemSchema = z.object({
  operationId: z.string().min(1, 'operationId is required').trim(),
  action: z.enum(['create', 'update', 'delete']),
  timestamp: z.coerce.date().default(() => new Date()),
  data: z.record(z.any()),
});

export const batchSyncSchema = z.object({
  operations: z.array(syncOperationItemSchema).max(100, 'Batch maximum is 100 operations'),
});

export type SyncOperationItemDto = z.infer<typeof syncOperationItemSchema>;
export type BatchSyncDto = z.infer<typeof batchSyncSchema>;
