import { z } from 'zod';

const phoneRegex = /^\+?[1-9]\d{6,14}$/;

export const registerSchema = z
  .object({
    email: z.string().email('Invalid email address').toLowerCase().trim(),
    password: z
      .string()
      .min(8, 'Password must be at least 8 characters')
      .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
      .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
      .regex(/[0-9]/, 'Password must contain at least one number'),
    name: z.string().min(2, 'Name must be at least 2 characters').trim().optional(),
    firstName: z.string().min(1, 'First name is required').trim().optional(),
    lastName: z.string().trim().optional(),
    phone: z.string().regex(phoneRegex, 'Invalid phone number format').optional(),
    currency: z.string().length(3, 'Currency must be a 3-letter ISO code').default('INR'),
    locale: z.string().default('en_IN'),
  })
  .refine((data) => data.name || data.firstName, {
    message: 'First name or name is required',
    path: ['firstName'],
  });

export const loginSchema = z.object({
  email: z.string().email('Invalid email address').toLowerCase().trim(),
  password: z.string().min(1, 'Password is required'),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
});

export const googleOAuthSchema = z.object({
  email: z.string().email('Invalid email address').toLowerCase().trim(),
  googleId: z.string().min(1, 'Google ID is required'),
  idToken: z.string().optional(),
  firstName: z.string().optional(),
  lastName: z.string().optional(),
  name: z.string().optional(),
  avatarUrl: z.string().url('Invalid avatar URL').optional(),
  currency: z.string().length(3, 'Currency must be a 3-letter ISO code').default('INR'),
  locale: z.string().default('en_IN'),
});

export const googleAuthSchema = z.union([
  googleOAuthSchema,
  z.object({
    idToken: z.string().min(1, 'ID token is required'),
    email: z.string().email().optional(),
    name: z.string().optional(),
  }),
]);

export const updateProfileSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').trim().optional(),
  firstName: z.string().min(1).trim().optional(),
  lastName: z.string().trim().optional(),
  phone: z.string().regex(phoneRegex, 'Invalid phone number format').optional(),
  currency: z.string().length(3, 'Currency must be a 3-letter ISO code').optional(),
  locale: z.string().optional(),
  onboardingCompleted: z.boolean().optional(),
  avatarUrl: z.string().optional(),
});

export type RegisterDto = z.infer<typeof registerSchema>;
export type LoginDto = z.infer<typeof loginSchema>;
export type RefreshTokenDto = z.infer<typeof refreshTokenSchema>;
export type UpdateProfileDto = z.infer<typeof updateProfileSchema>;
export type GoogleOAuthDto = z.infer<typeof googleOAuthSchema>;
export type GoogleAuthDto = z.infer<typeof googleAuthSchema>;

