import mongoose, { Document, Schema } from 'mongoose';

export interface ICategory extends Document {
  name: string;
  userId?: mongoose.Types.ObjectId;
  isDefault: boolean;
  isActive: boolean;
  color: string;
  icon: string;
  createdAt: Date;
  updatedAt: Date;
}

const categorySchema = new Schema<ICategory>(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    isDefault: {
      type: Boolean,
      default: false,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    color: {
      type: String,
      default: '#10B981',
    },
    icon: {
      type: String,
      default: 'category',
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

categorySchema.index({ userId: 1, isActive: 1 });

export const Category = mongoose.model<ICategory>('Category', categorySchema);

export const DEFAULT_CATEGORIES = [
  { _id: new mongoose.Types.ObjectId('6ad469f73965bcc8647ee771'), name: 'Groceries', color: '#10B981', icon: 'shopping_cart', isDefault: true, isActive: true },
  { _id: new mongoose.Types.ObjectId('6ad469f73965bcc8647ee772'), name: 'Food and dining', color: '#FFB95F', icon: 'restaurant', isDefault: true, isActive: true },
  { _id: new mongoose.Types.ObjectId('6ad469f73965bcc8647ee773'), name: 'Transportation', color: '#4EDEA3', icon: 'local_taxi', isDefault: true, isActive: true },
  { _id: new mongoose.Types.ObjectId('6ad469f73965bcc8647ee774'), name: 'Shopping', color: '#6366F1', icon: 'shopping_bag', isDefault: true, isActive: true },
  { _id: new mongoose.Types.ObjectId('6ad469f73965bcc8647ee775'), name: 'Housing and utilities', color: '#C0C1FF', icon: 'bolt', isDefault: true, isActive: true },
  { _id: new mongoose.Types.ObjectId('6ad469f73965bcc8647ee776'), name: 'Healthcare', color: '#FFB4AB', icon: 'medical_services', isDefault: true, isActive: true },
  { _id: new mongoose.Types.ObjectId('6ad469f73965bcc8647ee777'), name: 'Education', color: '#38BDF8', icon: 'school', isDefault: true, isActive: true },
  { _id: new mongoose.Types.ObjectId('6ad469f73965bcc8647ee778'), name: 'Entertainment', color: '#A855F7', icon: 'movie', isDefault: true, isActive: true },
  { _id: new mongoose.Types.ObjectId('6ad469f73965bcc8647ee779'), name: 'Travel', color: '#F43F5E', icon: 'flight', isDefault: true, isActive: true },
  { _id: new mongoose.Types.ObjectId('6ad469f73965bcc8647ee77a'), name: 'Personal care', color: '#EC4899', icon: 'spa', isDefault: true, isActive: true },
  { _id: new mongoose.Types.ObjectId('6ad469f73965bcc8647ee77b'), name: 'Bills and subscriptions', color: '#06B6D4', icon: 'receipt_long', isDefault: true, isActive: true },
  { _id: new mongoose.Types.ObjectId('6ad469f73965bcc8647ee77c'), name: 'Other', color: '#94A3B8', icon: 'payments', isDefault: true, isActive: true },
];
