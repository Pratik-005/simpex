import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'A server error occurred. Please try again.',
    super.statusCode,
  ]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message =
        'Unable to connect to the server. Please check your internet connection.',
  ]);
}

class AuthFailureError extends Failure {
  const AuthFailureError([
    super.message = 'Authentication failed. Please verify your credentials.',
    super.statusCode,
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Unable to read or write cached data.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
