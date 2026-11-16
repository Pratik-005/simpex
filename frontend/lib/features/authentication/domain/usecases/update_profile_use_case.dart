import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../models/auth_user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileParams {
  final String? name;
  final String? phone;
  final String? currency;
  final String? locale;
  final String? avatarUrl;

  const UpdateProfileParams({
    this.name,
    this.phone,
    this.currency,
    this.locale,
    this.avatarUrl,
  });
}

class UpdateProfileUseCase implements UseCase<AuthUser, UpdateProfileParams> {
  final AuthRepository repository;

  UpdateProfileUseCase({required this.repository});

  @override
  Future<Either<Failure, AuthUser>> call(UpdateProfileParams params) {
    return repository.updateProfile(
      name: params.name,
      phone: params.phone,
      currency: params.currency,
      locale: params.locale,
      avatarUrl: params.avatarUrl,
    );
  }
}
