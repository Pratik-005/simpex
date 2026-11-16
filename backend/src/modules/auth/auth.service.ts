import { OAuth2Client } from 'google-auth-library';
import { User, IUser } from './user.model.js';
import { RegisterDto, LoginDto, UpdateProfileDto, GoogleAuthDto } from './auth.schema.js';
import { hashPassword, verifyPassword, generateTokens, verifyRefreshToken } from './token.util.js';
import { ConflictError, UnauthorizedError, NotFoundError, BadRequestError } from '../../core/errors/app-error.js';

const googleClient = new OAuth2Client();

export class AuthService {
  async register(dto: RegisterDto) {
    const existing = await User.findOne({ email: dto.email });
    if (existing) {
      throw new ConflictError('User with this email already exists');
    }

    const name = dto.name || [dto.firstName, dto.lastName].filter(Boolean).join(' ') || 'User';
    const passwordHash = await hashPassword(dto.password);
    const user = await User.create({
      email: dto.email,
      name,
      passwordHash,
      authProvider: 'email',
      currency: dto.currency ?? 'INR',
      locale: dto.locale ?? 'en_IN',
    });

    const tokens = generateTokens(user._id.toString(), user.email);
    const refreshTokenHash = await hashPassword(tokens.refreshToken);

    await User.findByIdAndUpdate(user._id, { refreshTokenHash });

    return {
      user: this.sanitizeUser(user),
      tokens,
    };
  }

  async login(dto: LoginDto) {
    const user = await User.findOne({ email: dto.email }).select('+passwordHash');
    if (!user) {
      throw new UnauthorizedError('Invalid email or password');
    }

    if (!user.passwordHash) {
      throw new UnauthorizedError(
        'This account was created with Google Sign-In. Please sign in with Google.'
      );
    }

    const isMatch = await verifyPassword(user.passwordHash, dto.password);
    if (!isMatch) {
      throw new UnauthorizedError('Invalid email or password');
    }

    const tokens = generateTokens(user._id.toString(), user.email);
    const refreshTokenHash = await hashPassword(tokens.refreshToken);

    await User.findByIdAndUpdate(user._id, { refreshTokenHash });

    return {
      user: this.sanitizeUser(user),
      tokens,
    };
  }

  async googleAuth(dto: GoogleAuthDto | string) {
    let email: string;
    let name: string;
    let googleId: string;
    let avatarUrl: string | undefined;

    if (typeof dto === 'object' && 'googleId' in dto && dto.googleId) {
      email = dto.email.toLowerCase().trim();
      googleId = dto.googleId;
      name = dto.name || [dto.firstName, dto.lastName].filter(Boolean).join(' ') || email.split('@')[0];
      avatarUrl = dto.avatarUrl;
    } else {
      const idToken = typeof dto === 'string' ? dto : dto.idToken;
      if (!idToken) {
        throw new BadRequestError('Google ID token is required');
      }
      // Handle mock token for dev / testing if provided
      if (idToken.startsWith('mock-google-token')) {
        const parts = idToken.split('-');
        email = parts[3] ? `${parts[3]}@gmail.com` : 'alex.rivera@gmail.com';
        name = parts[3] ? parts[3] : 'Alex Rivera';
        googleId = `mock-google-id-${email}`;
        avatarUrl = 'https://lh3.googleusercontent.com/aida/mock-avatar';
      } else {
        try {
          const ticket: any = await googleClient.verifyIdToken({
            idToken,
          });
          const payload = ticket?.getPayload?.();
          if (!payload || !payload.email) {
            throw new UnauthorizedError('Invalid Google authentication token');
          }
          email = payload.email.toLowerCase().trim();
          name = payload.name || payload.given_name || email.split('@')[0];
          googleId = payload.sub;
          avatarUrl = payload.picture;
        } catch (err: any) {
          throw new UnauthorizedError(err?.message || 'Google token verification failed');
        }
      }
    }

    // Find or create user
    let user = await User.findOne({ $or: [{ googleId }, { email }] });
    if (!user) {
      user = await User.create({
        email,
        name,
        authProvider: 'google',
        googleId,
        avatarUrl,
        currency: 'INR',
        locale: 'en_IN',
      });
    } else {
      if (!user.googleId) user.googleId = googleId;
      if (avatarUrl && !user.avatarUrl) user.avatarUrl = avatarUrl;
      await user.save();
    }

    const tokens = generateTokens(user._id.toString(), user.email);
    const refreshTokenHash = await hashPassword(tokens.refreshToken);
    await User.findByIdAndUpdate(user._id, { refreshTokenHash });

    return {
      user: this.sanitizeUser(user),
      tokens,
    };
  }

  async refreshTokens(refreshToken: string) {
    const payload = verifyRefreshToken(refreshToken);
    const user = await User.findById(payload.sub).select('+refreshTokenHash');

    if (!user || !user.refreshTokenHash) {
      throw new UnauthorizedError('Invalid session. Please log in again.');
    }

    const isMatch = await verifyPassword(user.refreshTokenHash, refreshToken);
    if (!isMatch) {
      throw new UnauthorizedError('Revoked or invalid refresh token');
    }

    // Token rotation
    const tokens = generateTokens(user._id.toString(), user.email);
    const newRefreshHash = await hashPassword(tokens.refreshToken);

    await User.findByIdAndUpdate(user._id, { refreshTokenHash: newRefreshHash });

    return tokens;
  }

  async logout(userId: string) {
    await User.findByIdAndUpdate(userId, { $unset: { refreshTokenHash: 1 } });
  }

  async getProfile(userId: string) {
    const user = await User.findById(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }
    return this.sanitizeUser(user);
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const updateData: any = { ...dto };
    if (updateData.onboardingCompleted === undefined) {
      updateData.onboardingCompleted = true;
    }
    if (!updateData.name && (dto.firstName || dto.lastName)) {
      updateData.name = [dto.firstName, dto.lastName].filter(Boolean).join(' ');
    }
    const user = await User.findByIdAndUpdate(
      userId,
      { $set: updateData },
      { new: true, runValidators: true }
    );

    if (!user) {
      throw new NotFoundError('User not found');
    }

    return this.sanitizeUser(user);
  }

  private sanitizeUser(user: IUser) {
    return {
      id: user._id.toString(),
      email: user.email,
      name: user.name,
      currency: user.currency,
      locale: user.locale,
      authProvider: user.authProvider ?? 'email',
      avatarUrl: user.avatarUrl,
      phone: user.phone,
      onboardingCompleted: user.onboardingCompleted ?? false,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }
}

export const authService = new AuthService();
