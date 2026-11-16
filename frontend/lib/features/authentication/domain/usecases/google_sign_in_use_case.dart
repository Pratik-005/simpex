import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../models/auth_user.dart';
import '../repositories/auth_repository.dart';

class GoogleSignInParams {
  final String? explicitIdToken;

  const GoogleSignInParams({this.explicitIdToken});
}

class GoogleSignInUseCase implements UseCase<AuthUser, GoogleSignInParams> {
  final AuthRepository repository;

  GoogleSignInUseCase({required this.repository});

  @override
  Future<Either<Failure, AuthUser>> call(GoogleSignInParams params) {
    return repository.signInWithGoogle(
      explicitIdToken: params.explicitIdToken,
    );
  }
}
