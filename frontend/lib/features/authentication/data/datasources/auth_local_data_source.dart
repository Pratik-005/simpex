import 'package:logger/logger.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../domain/models/auth_user.dart';

abstract interface class AuthLocalDataSource {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> saveUser(AuthUser user);

  AuthUser? getUser();

  Future<bool> hasSession();

  Future<void> clearAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final AuthStorage authStorage;
  final Logger logger;

  AuthLocalDataSourceImpl({
    required this.authStorage,
    Logger? logger,
  }) : logger = logger ?? Logger();

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await authStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (e) {
      logger.e('LOCAL CACHE ERROR :: ERROR SAVING TOKENS', error: e);
      rethrow;
    }
  }

  @override
  Future<String?> getAccessToken() {
    return authStorage.getAccessToken();
  }

  @override
  Future<String?> getRefreshToken() {
    return authStorage.getRefreshToken();
  }

  @override
  Future<void> saveUser(AuthUser user) async {
    try {
      await authStorage.saveUser(user);
    } catch (e) {
      logger.e('LOCAL CACHE ERROR :: ERROR SAVING USER INFO', error: e);
      rethrow;
    }
  }

  @override
  AuthUser? getUser() {
    return authStorage.getUser();
  }

  @override
  Future<bool> hasSession() {
    return authStorage.hasSession();
  }

  @override
  Future<void> clearAll() async {
    try {
      await authStorage.clearAll();
    } catch (e) {
      logger.e('LOCAL CACHE ERROR :: ERROR CLEARING CACHE', error: e);
      rethrow;
    }
  }
}
