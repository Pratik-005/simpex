import { describe, it, expect } from 'vitest';
import {
  hashPassword,
  verifyPassword,
  generateTokens,
  verifyAccessToken,
  verifyRefreshToken,
} from '../../src/modules/auth/token.util.js';

describe('Token and Password Utilities', () => {
  it('hashes password with Argon2id and verifies successfully', async () => {
    const password = 'StrongPassword123';
    const hash = await hashPassword(password);

    expect(hash).toBeDefined();
    expect(hash).not.toBe(password);
    expect(hash.startsWith('$argon2id$')).toBe(true);

    const isMatch = await verifyPassword(hash, password);
    expect(isMatch).toBe(true);

    const isFalseMatch = await verifyPassword(hash, 'WrongPassword456');
    expect(isFalseMatch).toBe(false);
  });

  it('generates and verifies JWT tokens', () => {
    const userId = '64e8b3941a2e5d1234567890';
    const email = 'user@example.com';

    const { accessToken, refreshToken } = generateTokens(userId, email);

    expect(accessToken).toBeDefined();
    expect(refreshToken).toBeDefined();

    const accessPayload = verifyAccessToken(accessToken);
    expect(accessPayload.sub).toBe(userId);
    expect(accessPayload.email).toBe(email);

    const refreshPayload = verifyRefreshToken(refreshToken);
    expect(refreshPayload.sub).toBe(userId);
  });
});
