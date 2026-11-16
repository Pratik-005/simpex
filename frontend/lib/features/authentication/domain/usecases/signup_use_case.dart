import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../models/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignUpParams {
  final String email;
  final String password;
  final String name;
  final String currency;
  final String locale;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.name,
    this.currency = 'INR',
    this.locale = 'en_IN',
  });
}

class SignUpUseCase implements UseCase<AuthUser, SignUpParams> {
  final AuthRepository repository;

  SignUpUseCase({required this.repository});

  @override
  Future<Either<Failure, AuthUser>> call(SignUpParams params) {
    return repository.register(
      email: params.email,
      password: params.password,
      name: params.name,
      currency: params.currency,
      locale: params.locale,
    );
  }
}
