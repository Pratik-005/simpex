import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String currency;
  final String locale;

  const AuthSignUpSubmitted({
    required this.email,
    required this.password,
    required this.name,
    this.currency = 'INR',
    this.locale = 'en_IN',
  });

  @override
  List<Object?> get props => [email, password, name, currency, locale];
}

class AuthGoogleSignInSubmitted extends AuthEvent {
  final String? explicitIdToken;

  const AuthGoogleSignInSubmitted({this.explicitIdToken});

  @override
  List<Object?> get props => [explicitIdToken];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthUpdateProfileSubmitted extends AuthEvent {
  final String? name;
  final String? phone;
  final String? currency;
  final String? locale;
  final String? avatarUrl;

  const AuthUpdateProfileSubmitted({
    this.name,
    this.phone,
    this.currency,
    this.locale,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [name, phone, currency, locale, avatarUrl];
}
