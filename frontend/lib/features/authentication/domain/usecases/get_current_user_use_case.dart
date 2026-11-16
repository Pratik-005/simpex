import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../models/auth_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase implements UseCase<AuthUser, NoParams> {
  final AuthRepository repository;

  GetCurrentUserUseCase({required this.repository});

  @override
  Future<Either<Failure, AuthUser>> call(NoParams params) {
    return repository.getProfile();
  }

  AuthUser? getCachedUser() => repository.getCachedUser();

  Future<bool> hasSession() => repository.hasSession();
}
