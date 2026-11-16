import { describe, it, expect } from 'vitest';
import { batchSyncSchema } from '../../src/modules/sync/sync.schema.js';

describe('Sync Schema Validation', () => {
  it('accepts valid batch sync payload', () => {
    const valid = {
      operations: [
        {
          operationId: 'op-12345',
          action: 'create',
          timestamp: new Date().toISOString(),
          data: {
            amountMinor: 15000,
            categoryId: '64e8b3941a2e5d1234567890',
            description: 'Metro ticket',
          },
        },
        {
          operationId: 'op-67890',
          action: 'delete',
          timestamp: new Date().toISOString(),
          data: {
            id: '64e8b3941a2e5d1234567891',
          },
        },
      ],
    };

    const parsed = batchSyncSchema.safeParse(valid);
    expect(parsed.success).toBe(true);
    if (parsed.success) {
      expect(parsed.data.operations.length).toBe(2);
    }
  });

  it('rejects batch exceeding 100 operations', () => {
    const largeBatch = {
      operations: Array.from({ length: 101 }, (_, i) => ({
        operationId: `op-${i}`,
        action: 'create',
        data: {},
      })),
    };

    const parsed = batchSyncSchema.safeParse(largeBatch);
    expect(parsed.success).toBe(false);
  });
});
