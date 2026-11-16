import 'package:luthor/luthor.dart';

class AuthValidators {
  AuthValidators._();

  static final _emailSchema = l
      .string()
      .email(message: 'Please enter a valid email address')
      .required(message: 'Email address is required');

  static final _passwordSchema = l
      .string()
      .min(8, message: 'Password must be at least 8 characters')
      .regex(RegExp(r'[A-Z]'),
          message: 'Password must contain at least one uppercase letter')
      .regex(RegExp(r'[a-z]'),
          message: 'Password must contain at least one lowercase letter')
      .regex(RegExp(r'[0-9]'),
          message: 'Password must contain at least one number')
      .required(message: 'Password is required');

  static final _loginPasswordSchema =
      l.string().required(message: 'Password is required');

  static final _nameSchema = l
      .string()
      .min(2, message: 'Full name must be at least 2 characters')
      .required(message: 'Full name is required');

  static String? _extractError(ValidationResult result) {
    if (result.isValid) return null;
    final errors = result.errors;
    if (errors.isEmpty) return null;
    final firstVal = errors.values.first;
    if (firstVal.isNotEmpty) {
      return firstVal.first;
    }
    return null;
  }

  /// Validate email address format and presence
  static String? validateEmail(String? value) {
    final trimmed = value?.trim();
    final result = _emailSchema.validate(trimmed);
    return _extractError(result);
  }

  /// Validate strong password for registration
  static String? validatePassword(String? value) {
    final result = _passwordSchema.validate(value);
    return _extractError(result);
  }

  /// Validate presence for login password
  static String? validateLoginPassword(String? value) {
    final result = _loginPasswordSchema.validate(value);
    return _extractError(result);
  }

  /// Validate name for registration
  static String? validateName(String? value) {
    final trimmed = value?.trim();
    final result = _nameSchema.validate(trimmed);
    return _extractError(result);
  }

  /// Validate matching confirm password
  static String? validateConfirmPassword(
      String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}
