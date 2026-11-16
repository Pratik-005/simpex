import mongoose, { Document, Schema } from 'mongoose';

export type SyncAction = 'create' | 'update' | 'delete';
export type SyncResultStatus = 'synced' | 'duplicate' | 'failed' | 'conflict';

export interface ISyncOperation extends Document {
  userId: mongoose.Types.ObjectId;
  operationId: string;
  action: SyncAction;
  status: SyncResultStatus;
  resultEntityId?: mongoose.Types.ObjectId;
  error?: string;
  createdAt: Date;
}

const syncOperationSchema = new Schema<ISyncOperation>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    operationId: {
      type: String,
      required: true,
      index: true,
    },
    action: {
      type: String,
      enum: ['create', 'update', 'delete'],
      required: true,
    },
    status: {
      type: String,
      enum: ['synced', 'duplicate', 'failed', 'conflict'],
      required: true,
    },
    resultEntityId: {
      type: Schema.Types.ObjectId,
      ref: 'Expense',
    },
    error: {
      type: String,
    },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    versionKey: false,
  }
);

// Compound index to ensure uniqueness per user and operation
syncOperationSchema.index({ userId: 1, operationId: 1 }, { unique: true });

// TTL index to automatically prune audit logs older than 30 days
syncOperationSchema.index({ createdAt: 1 }, { expireAfterSeconds: 30 * 24 * 60 * 60 });

export const SyncOperation = mongoose.model<ISyncOperation>('SyncOperation', syncOperationSchema);
