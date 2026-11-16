import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:frontend/core/errors/failure.dart';
import 'package:frontend/features/authentication/domain/models/auth_user.dart';
import 'package:frontend/features/authentication/domain/repositories/auth_repository.dart';
import 'package:frontend/features/authentication/domain/usecases/get_current_user_use_case.dart';
import 'package:frontend/features/authentication/domain/usecases/google_sign_in_use_case.dart';
import 'package:frontend/features/authentication/domain/usecases/login_use_case.dart';
import 'package:frontend/features/authentication/domain/usecases/logout_use_case.dart';
import 'package:frontend/features/authentication/domain/usecases/signup_use_case.dart';
import 'package:frontend/features/authentication/domain/usecases/update_profile_use_case.dart';
import 'package:frontend/features/authentication/domain/validation/auth_validators.dart';
import 'package:frontend/features/authentication/presentation/bloc/auth_bloc.dart';

class _FakeAuthRepository implements AuthRepository {
  bool shouldFail = false;
  AuthUser? cachedUser;
  bool sessionActive = false;

  final sampleUser = const AuthUser(
    id: 'user_123',
    email: 'alex@example.com',
    name: 'Alex Morgan',
    currency: 'INR',
    locale: 'en_IN',
  );

  @override
  Future<bool> hasSession() async => sessionActive;

  @override
  AuthUser? getCachedUser() => cachedUser;

  @override
  Future<Either<Failure, AuthUser>> login({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      return const Left(ServerFailure('Invalid email or password'));
    }
    cachedUser = sampleUser;
    sessionActive = true;
    return Right(sampleUser);
  }

  @override
  Future<Either<Failure, AuthUser>> register({
    required String email,
    required String password,
    required String name,
    String currency = 'INR',
    String locale = 'en_IN',
  }) async {
    if (shouldFail) {
      return const Left(ServerFailure('User already registered'));
    }
    final newUser = AuthUser(
      id: 'new_user',
      email: email,
      name: name,
      currency: currency,
      locale: locale,
    );
    cachedUser = newUser;
    sessionActive = true;
    return Right(newUser);
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle({
    String? explicitIdToken,
  }) async {
    if (shouldFail) {
      return const Left(ServerFailure('Google auth failed'));
    }
    cachedUser = sampleUser;
    sessionActive = true;
    return Right(sampleUser);
  }

  @override
  Future<Either<Failure, AuthUser>> getProfile() async {
    if (shouldFail) {
      return const Left(ServerFailure('Session expired'));
    }
    return Right(sampleUser);
  }

  @override
  Future<Either<Failure, AuthUser>> updateProfile({
    String? name,
    String? phone,
    String? currency,
    String? locale,
    String? avatarUrl,
  }) async {
    if (shouldFail) {
      return const Left(ServerFailure('Profile update failed'));
    }
    final updated = sampleUser.copyWith(
      name: name,
      currency: currency,
      locale: locale,
      phone: phone,
      avatarUrl: avatarUrl,
    );
    cachedUser = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failure, void>> logout() async {
    cachedUser = null;
    sessionActive = false;
    return const Right(null);
  }
}

void main() {
  group('AuthValidators (Luthor)', () {
    test('validates email addresses properly', () {
      expect(AuthValidators.validateEmail(''), isNotNull);
      expect(AuthValidators.validateEmail('invalid-email'), isNotNull);
      expect(AuthValidators.validateEmail('alex@example.com'), isNull);
    });

    test('validates registration passwords properly', () {
      expect(AuthValidators.validatePassword('short'), isNotNull);
      expect(AuthValidators.validatePassword('alllowercase123'), isNotNull);
      expect(AuthValidators.validatePassword('ALLUPPERCASE123'), isNotNull);
      expect(AuthValidators.validatePassword('NoNumbersHere!'), isNotNull);
      expect(AuthValidators.validatePassword('ValidPass123!'), isNull);
    });

    test('validates names properly', () {
      expect(AuthValidators.validateName(''), isNotNull);
      expect(AuthValidators.validateName('A'), isNotNull);
      expect(AuthValidators.validateName('Alex Morgan'), isNull);
    });
  });

  group('AuthBloc state machine with Clean Architecture UseCases', () {
    late _FakeAuthRepository fakeRepo;
    late AuthBloc authBloc;

    setUp(() {
      fakeRepo = _FakeAuthRepository();
      authBloc = AuthBloc(
        loginUseCase: LoginUseCase(repository: fakeRepo),
        signUpUseCase: SignUpUseCase(repository: fakeRepo),
        googleSignInUseCase: GoogleSignInUseCase(repository: fakeRepo),
        logoutUseCase: LogoutUseCase(repository: fakeRepo),
        getCurrentUserUseCase: GetCurrentUserUseCase(repository: fakeRepo),
        updateProfileUseCase: UpdateProfileUseCase(repository: fakeRepo),
      );
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    test('emits [AuthLoading, Authenticated] on successful login', () async {
      final expected = [
        isA<AuthLoading>(),
        isA<Authenticated>()
            .having((s) => s.user.email, 'email', 'alex@example.com'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));

      authBloc.add(
        const AuthLoginSubmitted(
          email: 'alex@example.com',
          password: 'Password123',
        ),
      );
    });

    test('emits [AuthLoading, AuthFailure] on failed login', () async {
      fakeRepo.shouldFail = true;

      final expected = [
        isA<AuthLoading>(),
        isA<AuthFailure>().having(
          (s) => s.message,
          'message',
          contains('Invalid email or password'),
        ),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));

      authBloc.add(
        const AuthLoginSubmitted(
          email: 'wrong@example.com',
          password: 'WrongPassword123',
        ),
      );
    });

    test('emits [AuthLoading, Authenticated] on signup submission', () async {
      final expected = [
        isA<AuthLoading>(),
        isA<Authenticated>()
            .having((s) => s.user.name, 'name', 'Alex Morgan'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));

      authBloc.add(
        const AuthSignUpSubmitted(
          email: 'alex@example.com',
          password: 'Password123',
          name: 'Alex Morgan',
        ),
      );
    });

    test('emits [AuthLoading, Unauthenticated] on logout', () async {
      expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Unauthenticated>(),
        ]),
      );

      authBloc.add(const AuthLogoutRequested());
    });

    test('emits [AuthLoading, Authenticated] on profile update submission', () async {
      final expected = [
        isA<AuthLoading>(),
        isA<Authenticated>()
            .having((s) => s.user.name, 'name', 'Alex Updated')
            .having((s) => s.user.phone, 'phone', '+919876543210'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));

      authBloc.add(
        const AuthUpdateProfileSubmitted(
          name: 'Alex Updated',
          phone: '+919876543210',
          currency: 'INR',
        ),
      );
    });
  });
}
