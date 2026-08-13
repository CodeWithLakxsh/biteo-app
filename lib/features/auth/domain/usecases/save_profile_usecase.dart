import '../repositories/i_auth_repository.dart';
import '../entities/user_entity.dart';

class SaveProfileUseCase {
  final IAuthRepository repo;

  SaveProfileUseCase(this.repo);

  Future<void> call(UserEntity user) async {
    await repo.saveUserProfile(
      uid: user.uid,
      phone: user.phone,
      fullName: user.fullName ?? '',
      foodPreference: user.foodPreference,
      email: user.email,
    );
  }
}