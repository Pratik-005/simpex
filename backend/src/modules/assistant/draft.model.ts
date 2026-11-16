import mongoose, { Document, Schema } from 'mongoose';

export type DraftStatus = 'draft' | 'awaiting_confirmation' | 'confirmed' | 'cancelled';

export interface IExpenseDraft extends Document {
  userId: mongoose.Types.ObjectId;
  conversationId: string;
  amountMinor?: number;
  currency: string;
  categoryId?: mongoose.Types.ObjectId;
  categoryName?: string;
  description?: string;
  transactionDate: Date; 
  paymentMethod: string;
  status: DraftStatus;
  missingFields: string[];
  expiresAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const expenseDraftSchema = new Schema<IExpenseDraft>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    conversationId: {
      type: String,
      required: true,
      index: true,
    },
    amountMinor: {
      type: Number,
      validate: {
        validator: (val: number) => val === undefined || Number.isInteger(val),
        message: 'amountMinor must be an integer (paise)',
      },
    },
    currency: {
      type: String,
      default: 'INR',
    },
    categoryId: {
      type: Schema.Types.ObjectId,
      ref: 'Category',
    },
    categoryName: {
      type: String,
    },
    description: {
      type: String,
      maxlength: 200,
    },
    transactionDate: {
      type: Date,
      default: Date.now,
    },
    paymentMethod: {
      type: String,
      default: 'UPI',
    },
    status: {
      type: String,
      enum: ['draft', 'awaiting_confirmation', 'confirmed', 'cancelled'],
      default: 'draft',
      index: true,
    },
    missingFields: {
      type: [String],
      default: [],
    },
    expiresAt: {
      type: Date,
      default: () => new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// TTL index to automatically purge expired drafts after 24 hours
expenseDraftSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export const ExpenseDraft = mongoose.model<IExpenseDraft>('ExpenseDraft', expenseDraftSchema);
