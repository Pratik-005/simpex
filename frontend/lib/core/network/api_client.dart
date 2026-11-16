import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/auth_storage.dart';

class ApiClient {
  final Dio dio;
  final AuthStorage authStorage;
  void Function()? onUnauthenticated;

  ApiClient({required this.authStorage, Dio? customDio, this.onUnauthenticated})
    : dio =
          customDio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach Bearer Access Token if present and not already specified
          if (!options.headers.containsKey('Authorization')) {
            final token = await authStorage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final is401 = error.response?.statusCode == 401;
          final isAuthEndpoint =
              error.requestOptions.path.contains('/login') ||
              error.requestOptions.path.contains('/register') ||
              error.requestOptions.path.contains('/refresh') ||
              error.requestOptions.path.contains('/logout');

          // Attempt token refresh on 401 for authenticated endpoints
          if (is401 && !isAuthEndpoint) {
            final refreshToken = await authStorage.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Separate Dio instance to avoid recursive interceptor loops
                final refreshDio = Dio(
                  BaseOptions(
                    baseUrl: ApiConstants.baseUrl,
                    headers: {'Content-Type': 'application/json'},
                  ),
                );

                final response = await refreshDio.post(
                  ApiConstants.refresh,
                  data: {'refreshToken': refreshToken},
                );

                if (response.statusCode == 200 && response.data != null) {
                  final data = response.data['data'] as Map<String, dynamic>;
                  final newAccessToken = data['accessToken'] as String;
                  final newRefreshToken = data['refreshToken'] as String;

                  await authStorage.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                  );

                  // Retry the original request with new token
                  final retryOptions = error.requestOptions;
                  retryOptions.headers['Authorization'] =
                      'Bearer $newAccessToken';

                  final retryResponse = await dio.fetch(retryOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (_) {
                // Refresh failed; clear storage and signal unauthenticated
                await authStorage.clearAll();
                onUnauthenticated?.call();
              }
            } else {
              await authStorage.clearAll();
              onUnauthenticated?.call();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }
}
