import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final Logger logger;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    Logger? logger,
  }) : logger = logger ?? Logger();

  @override
  Future<Either<Failure, AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.login(
        email: email,
        password: password,
      );

      await localDataSource.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
      );
      await localDataSource.saveUser(result.user);

      return Right(result.user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      logger.i('ERROR LOGGING IN', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> register({
    required String email,
    required String password,
    required String name,
    String currency = 'INR',
    String locale = 'en_IN',
  }) async {
    try {
      final result = await remoteDataSource.register(
        email: email,
        password: password,
        name: name,
        currency: currency,
        locale: locale,
      );

      await localDataSource.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
      );
      await localDataSource.saveUser(result.user);

      return Right(result.user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      logger.i('ERROR REGISTERING USER', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle({
    String? explicitIdToken,
  }) async {
    try {
      final result = await remoteDataSource.signInWithGoogle(
        explicitIdToken: explicitIdToken,
      );

      await localDataSource.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
      );
      await localDataSource.saveUser(result.user);

      return Right(result.user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      logger.i('ERROR GOOGLE SIGN IN', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> getProfile() async {
    try {
      final user = await remoteDataSource.getProfile();
      await localDataSource.saveUser(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      logger.i('ERROR FETCHING PROFILE', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> updateProfile({
    String? name,
    String? phone,
    String? currency,
    String? locale,
    String? avatarUrl,
  }) async {
    try {
      final user = await remoteDataSource.updateProfile(
        name: name,
        phone: phone,
        currency: currency,
        locale: locale,
        avatarUrl: avatarUrl,
      );
      await localDataSource.saveUser(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      logger.i('ERROR UPDATING PROFILE', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  AuthUser? getCachedUser() {
    return localDataSource.getUser();
  }

  @override
  Future<bool> hasSession() {
    return localDataSource.hasSession();
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (e) {
      logger.i('REMOTE LOGOUT NOTICE, CLEARING LOCAL STORAGE', error: e);
    } finally {
      await localDataSource.clearAll();
    }
    return const Right(null);
  }
}
