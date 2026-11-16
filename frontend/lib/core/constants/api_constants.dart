class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://192.168.0.102:5000/api/v1';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleAuth = '/auth/google';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Category endpoints
  static const String categories = '/categories';

  // Expense endpoints
  static const String expenses = '/expenses';

  // Budget endpoints
  static const String budgets = '/budgets';
  static const String currentBudget = '/budgets/current';

  // Sync endpoints
  static const String syncBatch = '/sync/batch';

  // OAuth Credentials (Web application Client ID used as serverClientId for token generation)
  static const String googleClientId =
      '207878718489-2ohhaj56d8ldegeuu28fvrfgp41mnj6s.apps.googleusercontent.com';
}
