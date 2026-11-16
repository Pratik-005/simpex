import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/authentication/domain/models/auth_user.dart';

class AuthStorage {
  static const String _accessTokenKey = 'simpex_access_token';
  static const String _refreshTokenKey = 'simpex_refresh_token';
  static const String _userProfileKey = 'simpex_user_profile';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  AuthStorage({
    FlutterSecureStorage? secureStorage,
    required SharedPreferences prefs,
  }) : _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(resetOnError: true),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock,
             ),
           ),
       _prefs = prefs;

  /// Save JWT tokens securely
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  /// Retrieve the current Access Token
  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: _accessTokenKey);
  }

  /// Retrieve the current Refresh Token
  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  /// Save user profile data
  Future<void> saveUser(AuthUser user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs.setString(_userProfileKey, userJson);
  }

  /// Retrieve cached user profile data
  AuthUser? getUser() {
    final raw = _prefs.getString(_userProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AuthUser.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Check if an active session exists
  Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static const String _onboardingCompletedKey = 'simpex_onboarding_completed';

  String _userOnboardingKey(String userId) => '${_onboardingCompletedKey}_$userId';

  /// Check whether the current user has completed onboarding profile setup
  bool hasCompletedOnboarding([String? userId]) {
    final user = getUser();
    if (user == null) return false;

    // 1. Explicit model field from backend or local cache
    if (user.onboardingCompleted) return true;

    // 2. User-specific local preference
    final specificId = userId ?? user.id;
    if (specificId.isNotEmpty) {
      final flag = _prefs.getBool(_userOnboardingKey(specificId));
      if (flag != null) return flag;
    }

    // 3. Fallback: verified existing phone number
    return user.phone != null && user.phone!.trim().isNotEmpty;
  }

  /// Mark onboarding as completed or reset
  Future<void> setCompletedOnboarding(bool completed) async {
    final user = getUser();
    if (user != null && user.id.isNotEmpty) {
      await _prefs.setBool(_userOnboardingKey(user.id), completed);
      await saveUser(user.copyWith(onboardingCompleted: completed));
    }
    await _prefs.setBool(_onboardingCompletedKey, completed);
  }

  /// Clear all stored tokens and user session data
  Future<void> clearAll() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _prefs.remove(_userProfileKey),
      _prefs.remove(_onboardingCompletedKey),
    ]);
  }
}
