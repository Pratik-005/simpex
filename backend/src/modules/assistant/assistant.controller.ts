import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { assistantService } from './assistant.service.js';
import { UnauthorizedError } from '../../core/errors/app-error.js';
import { isValidTimezone } from './assistant.validation.js';

const chatMessageSchema = z.object({
  conversationId: z.string().trim().min(1, 'conversationId is required').max(100),
  message: z.string().trim().min(1, 'message is required').max(500),
  timezone: z.string().trim().refine(isValidTimezone, 'timezone must be a valid IANA name such as Asia/Kolkata').optional(),
});

export class AssistantController {
  async handleChat(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {

      if (!req.user) throw new UnauthorizedError();
      const validated = chatMessageSchema.parse(req.body);

      const response = await assistantService.run({
        userId: req.user.id,
        conversationId: validated.conversationId,
        message: validated.message,
        timezone: validated.timezone,
      });

      res.status(200).json({
        success: true,
        data: response,
      });

    } catch (err) {
      next(err);
    }
  }
}

export const assistantController = new AssistantController();

