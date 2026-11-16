import mongoose, { Document, Schema } from 'mongoose';

export type PaymentMethod = 'UPI' | 'Cash' | 'Credit Card' | 'Debit Card' | 'Apple Pay' | 'Other';
export type ExpenseStatus = 'active' | 'archived' | 'deleted';

export interface IExpense extends Document {
  userId: mongoose.Types.ObjectId;
  amountMinor: number;
  currency: string;
  categoryId: mongoose.Types.ObjectId;
  description: string;
  transactionDate: Date;
  paymentMethod: PaymentMethod;
  status: ExpenseStatus;
  idempotencyKey?: string;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const expenseSchema = new Schema<IExpense>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    amountMinor: {
      type: Number,
      required: true,
      validate: {
        validator: Number.isInteger,
        message: 'amountMinor must be an integer (minor currency units)',
      },
      min: [1, 'amountMinor must be greater than zero'],
      index: true,
    },
    currency: {
      type: String,
      default: 'INR',
      trim: true,
      uppercase: true,
    },
    categoryId: {
      type: Schema.Types.ObjectId,
      ref: 'Category',
      required: true,
      index: true,
    },
    description: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    transactionDate: {
      type: Date,
      required: true,
      default: Date.now,
      index: true,
    },
    paymentMethod: {
      type: String,
      enum: ['UPI', 'Cash', 'Credit Card', 'Debit Card', 'Apple Pay', 'Other'],
      default: 'UPI',
    },
    status: {
      type: String,
      enum: ['active', 'deleted'],
      default: 'active',
      index: true,
    },
    idempotencyKey: {
      type: String,
      trim: true,
    },
    notes: {
      type: String,
      trim: true,
      maxlength: 500,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// Compound Indexes for fast querying and idempotency
expenseSchema.index({ userId: 1, transactionDate: -1 });
expenseSchema.index({ userId: 1, status: 1, transactionDate: -1, createdAt: -1 });
expenseSchema.index({ userId: 1, categoryId: 1 });
expenseSchema.index(
  { userId: 1, idempotencyKey: 1 },
  {
    unique: true,
    partialFilterExpression: { idempotencyKey: { $type: 'string' } },
  }
);

export const Expense = mongoose.model<IExpense>('Expense', expenseSchema);
