import { describe, it, expect } from 'vitest';
import {
  registerSchema,
  loginSchema,
  googleOAuthSchema,
  updateProfileSchema,
} from '../../src/modules/auth/auth.schema.js';

describe('Auth Validation Schemas', () => {
  describe('registerSchema', () => {
    it('accepts valid registration with firstName, lastName, phone, currency', () => {
      const valid = registerSchema.safeParse({
        email: 'alex@example.com',
        password: 'Password123',
        firstName: 'Alex',
        lastName: 'Sharma',
        phone: '+919876543210',
        currency: 'INR',
      });

      expect(valid.success).toBe(true);
      if (valid.success) {
        expect(valid.data.firstName).toBe('Alex');
        expect(valid.data.currency).toBe('INR');
      }
    });

    it('rejects registration with weak password', () => {
      const invalid = registerSchema.safeParse({
        email: 'alex@example.com',
        password: 'weak',
        firstName: 'Alex',
      });

      expect(invalid.success).toBe(false);
    });

    it('rejects registration without firstName or name', () => {
      const invalid = registerSchema.safeParse({
        email: 'alex@example.com',
        password: 'Password123',
      });

      expect(invalid.success).toBe(false);
    });
  });

  describe('googleOAuthSchema', () => {
    it('accepts valid Google OAuth payload', () => {
      const valid = googleOAuthSchema.safeParse({
        email: 'alex.google@gmail.com',
        googleId: 'google-oauth-sub-12345',
        firstName: 'Alex',
        lastName: 'Sharma',
        avatarUrl: 'https://lh3.googleusercontent.com/photo.jpg',
        currency: 'INR',
      });

      expect(valid.success).toBe(true);
      if (valid.success) {
        expect(valid.data.googleId).toBe('google-oauth-sub-12345');
        expect(valid.data.email).toBe('alex.google@gmail.com');
      }
    });

    it('rejects invalid email in Google OAuth payload', () => {
      const invalid = googleOAuthSchema.safeParse({
        email: 'not-an-email',
        googleId: '12345',
      });

      expect(invalid.success).toBe(false);
    });
  });

  describe('updateProfileSchema', () => {
    it('accepts valid profile updates with firstName, lastName, phone, and currency', () => {
      const valid = updateProfileSchema.safeParse({
        firstName: 'Rahul',
        lastName: 'Verma',
        phone: '+919876543210',
        currency: 'USD',
      });

      expect(valid.success).toBe(true);
      if (valid.success) {
        expect(valid.data.firstName).toBe('Rahul');
        expect(valid.data.currency).toBe('USD');
      }
    });

    it('rejects invalid phone number format', () => {
      const invalid = updateProfileSchema.safeParse({
        phone: '123-abc-not-valid',
      });

      expect(invalid.success).toBe(false);
    });

    it('rejects invalid currency code length', () => {
      const invalid = updateProfileSchema.safeParse({
        currency: 'INDIAN_RUPEE',
      });

      expect(invalid.success).toBe(false);
    });
  });
});
