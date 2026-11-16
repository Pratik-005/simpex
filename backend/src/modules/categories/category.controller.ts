import { Request, Response, NextFunction } from 'express';
import { categoryService } from './category.service.js';
import { createCategorySchema, updateCategorySchema } from './category.schema.js';
import { UnauthorizedError } from '../../core/errors/app-error.js';

export class CategoryController {
  async getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const categories = await categoryService.getCategories(req.user.id);

      res.status(200).json({
        success: true,
        data: categories,
      });
    } catch (err) {
      next(err);
    }
  }

  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const validated = createCategorySchema.parse(req.body);
      const category = await categoryService.createCategory(req.user.id, validated);

      res.status(201).json({
        success: true,
        data: category,
      });
    } catch (err) {
      next(err);
    }
  }

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const validated = updateCategorySchema.parse(req.body);
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const category = await categoryService.updateCategory(req.user.id, id, validated);

      res.status(200).json({
        success: true,
        data: category,
      });
    } catch (err) {
      next(err);
    }
  }

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      await categoryService.deleteCategory(req.user.id, id);

      res.status(200).json({
        success: true,
        data: null,
        message: 'Category deleted successfully',
      });
    } catch (err) {
      next(err);
    }
  }
}

export const categoryController = new CategoryController();
