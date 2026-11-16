import mongoose from 'mongoose';
import { Category, DEFAULT_CATEGORIES, ICategory } from './category.model.js';
import { CreateCategoryDto, UpdateCategoryDto } from './category.schema.js';
import { NotFoundError, ForbiddenError } from '../../core/errors/app-error.js';

export class CategoryService {
  async seedDefaults(): Promise<void> {
    for (const cat of DEFAULT_CATEGORIES) {
      await Category.findOneAndUpdate(
        { name: cat.name, isDefault: true },
        {
          $set: { isActive: true, color: cat.color, icon: cat.icon },
          $setOnInsert: cat,
        },
        { upsert: true }
      );
    }
  }

  async getCategories(userId: string): Promise<ICategory[]> {
    const userFilter = mongoose.Types.ObjectId.isValid(userId)
      ? { userId: new mongoose.Types.ObjectId(userId), isActive: { $ne: false } }
      : { userId: null, isActive: { $ne: false } };

    return Category.find({
      $or: [
        { isDefault: true, isActive: { $ne: false } },
        userFilter,
      ],
    }).sort({ isDefault: -1, name: 1 });
  }

  async createCategory(userId: string, dto: CreateCategoryDto): Promise<ICategory> {
    return Category.create({
      ...dto,
      userId: new mongoose.Types.ObjectId(userId),
      isDefault: false,
      isActive: true,
    });
  }

  async updateCategory(userId: string, categoryId: string, dto: UpdateCategoryDto): Promise<ICategory> {
    const query = mongoose.Types.ObjectId.isValid(categoryId)
      ? { _id: categoryId }
      : { name: new RegExp(`^${categoryId}$`, 'i') };

    const category = await Category.findOne(query);
    if (!category) {
      throw new NotFoundError('Category not found');
    }

    if (category.userId && category.userId.toString() !== userId) {
      throw new ForbiddenError('You do not have permission to modify this category');
    }

    Object.assign(category, dto);
    if (category.isDefault) {
      category.isDefault = false;
      category.userId = new mongoose.Types.ObjectId(userId);
    }
    return category.save();
  }

  async deleteCategory(userId: string, categoryId: string): Promise<void> {
    const query = mongoose.Types.ObjectId.isValid(categoryId)
      ? { _id: categoryId }
      : { name: new RegExp(`^${categoryId}$`, 'i') };

    const category = await Category.findOne(query);
    if (!category) {
      return;
    }

    if (category.userId && category.userId.toString() !== userId) {
      throw new ForbiddenError('You do not have permission to delete this category');
    }

    category.isActive = false;
    await category.save();
  }
}

export const categoryService = new CategoryService();
