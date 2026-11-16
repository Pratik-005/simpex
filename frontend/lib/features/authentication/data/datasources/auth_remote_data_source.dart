import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/auth_user.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthResult> login({
    required String email,
    required String password,
  });

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String currency = 'INR',
    String locale = 'en_IN',
  });

  Future<AuthResult> signInWithGoogle({String? explicitIdToken});

  Future<AuthUser> getProfile();

  Future<AuthUser> updateProfile({
    String? name,
    String? phone,
    String? currency,
    String? locale,
    String? avatarUrl,
  });

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final Logger logger;
  bool _isGoogleSignInInitialized = false;

  AuthRemoteDataSourceImpl({
    required this.apiClient,
    Logger? logger,
  }) : logger = logger ?? Logger();

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? ApiConstants.googleClientId : null,
        serverClientId: ApiConstants.googleClientId,
      );
      _isGoogleSignInInitialized = true;
    } catch (e) {
      logger.e('SERVER ERROR :: GOOGLE SIGN IN INITIALIZATION FAILED', error: e);
      _isGoogleSignInInitialized = true;
    }
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.login,
        data: {'email': email.trim().toLowerCase(), 'password': password},
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return AuthResult.fromJson(data);
    } on DioException catch (e) {
      final parsed = _parseDioError(e);
      logger.e('SERVER ERROR :: ERROR LOGGING IN', error: parsed.message);
      throw parsed;
    } catch (e) {
      logger.e('SERVER ERROR :: ERROR LOGGING IN', error: e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String currency = 'INR',
    String locale = 'en_IN',
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.register,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
          'name': name.trim(),
          'currency': currency,
          'locale': locale,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return AuthResult.fromJson(data);
    } on DioException catch (e) {
      final parsed = _parseDioError(e);
      logger.e('SERVER ERROR :: ERROR REGISTERING USER', error: parsed.message);
      throw parsed;
    } catch (e) {
      logger.e('SERVER ERROR :: ERROR REGISTERING USER', error: e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<AuthResult> signInWithGoogle({String? explicitIdToken}) async {
    try {
      String? token = explicitIdToken;

      if (token == null || token.isEmpty) {
        await _ensureGoogleSignInInitialized();

        GoogleSignInAccount? account;
        try {
          account = await GoogleSignIn.instance.authenticate();
        } on GoogleSignInException catch (e) {
          logger.e(
            'SERVER ERROR :: GOOGLE SIGN IN USER CANCELLED OR FAILED',
            error: e.description ?? e.toString(),
          );
          throw ServerException(
            'Google Sign-In cancelled or failed: ${e.description ?? e.toString()}',
            400,
          );
        } catch (e) {
          logger.e('SERVER ERROR :: GOOGLE SIGN IN AUTHENTICATE ERROR', error: e);
          throw ServerException(
            'Google Sign-In failed: $e',
            400,
          );
        }

        final tokenData = account.authentication;
        token = tokenData.idToken;

        logger.i('GOOGLE SIGN IN :: Account authenticated for ${account.email}');
        logger.i('GOOGLE SIGN IN :: ID Token received: ${token != null && token.isNotEmpty ? 'YES (length: ${token.length})' : 'NO (null or empty)'}');

        if (token == null || token.isEmpty) {
          logger.e(
            'SERVER ERROR :: EMPTY GOOGLE ID TOKEN RECEIVED. '
            'Note: On Android, serverClientId MUST be an OAuth "Web application" Client ID from Google Cloud Console, not an "Android" Client ID.',
          );
          throw const ServerException(
            'Google ID Token was not returned by Google Play Services. '
            'Ensure serverClientId is set to a "Web application" Client ID in Google Cloud Console.',
            401,
          );
        }
      }

      final response = await apiClient.dio.post(
        ApiConstants.googleAuth,
        data: {'idToken': token},
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return AuthResult.fromJson(data);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final parsed = _parseDioError(e);
      logger.e('SERVER ERROR :: ERROR GOOGLE AUTHENTICATION BACKEND CALL', error: parsed.message);
      throw parsed;
    } catch (e) {
      logger.e('SERVER ERROR :: ERROR GOOGLE AUTHENTICATION', error: e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<AuthUser> getProfile() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.me);
      final data = response.data['data'] as Map<String, dynamic>;
      return AuthUser.fromJson(data);
    } on DioException catch (e) {
      final parsed = _parseDioError(e);
      logger.e('SERVER ERROR :: ERROR FETCHING USER PROFILE', error: parsed.message);
      throw parsed;
    } catch (e) {
      logger.e('SERVER ERROR :: ERROR FETCHING USER PROFILE', error: e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<AuthUser> updateProfile({
    String? name,
    String? phone,
    String? currency,
    String? locale,
    String? avatarUrl,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name;
      if (phone != null) payload['phone'] = phone;
      if (currency != null) payload['currency'] = currency;
      if (locale != null) payload['locale'] = locale;
      if (avatarUrl != null) payload['avatarUrl'] = avatarUrl;

      final response = await apiClient.dio.patch(
        ApiConstants.me,
        data: payload,
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return AuthUser.fromJson(data);
    } on DioException catch (e) {
      final parsed = _parseDioError(e);
      logger.e('SERVER ERROR :: ERROR UPDATING USER PROFILE', error: parsed.message);
      throw parsed;
    } catch (e) {
      logger.e('SERVER ERROR :: ERROR UPDATING USER PROFILE', error: e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.dio.post(ApiConstants.logout);
    } on DioException catch (e) {
      final parsed = _parseDioError(e);
      logger.i('REMOTE LOGOUT NOTICE: ${parsed.message}');
    } catch (e) {
      logger.i('REMOTE LOGOUT NOTICE: $e');
    }

    try {
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (e) {
      logger.i('GOOGLE SIGN-OUT NOTICE: $e');
    }
  }

  ServerException _parseDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        (e.message != null && e.message!.toLowerCase().contains('connection refused'))) {
      return ServerException(
        'Unable to connect to the backend server. Please verify the server is running and accessible.',
        e.response?.statusCode ?? 503,
      );
    }

    final response = e.response;
    final statusCode = response?.statusCode;
    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;
      String? msg = data['message'] as String?;
      if (msg == null && data['error'] is Map<String, dynamic>) {
        msg = (data['error'] as Map<String, dynamic>)['message'] as String?;
      }
      return ServerException(
        msg ?? e.message ?? 'An unexpected error occurred',
        statusCode,
      );
    }
    return ServerException(e.message ?? 'A network error occurred', statusCode);
  }
}
