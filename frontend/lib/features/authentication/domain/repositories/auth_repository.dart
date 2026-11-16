import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../models/auth_user.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, AuthUser>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthUser>> register({
    required String email,
    required String password,
    required String name,
    String currency = 'INR',
    String locale = 'en_IN',
  });

  Future<Either<Failure, AuthUser>> signInWithGoogle({
    String? explicitIdToken,
  });

  Future<Either<Failure, AuthUser>> getProfile();

  Future<Either<Failure, AuthUser>> updateProfile({
    String? name,
    String? phone,
    String? currency,
    String? locale,
    String? avatarUrl,
  });

  AuthUser? getCachedUser();

  Future<bool> hasSession();

  Future<Either<Failure, void>> logout();
}
