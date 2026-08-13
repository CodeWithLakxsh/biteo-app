import '../repositories/i_auth_repository.dart';
import '../entities/user_entity.dart';

class VerifyOtpUseCase {
  final IAuthRepository repo;

  VerifyOtpUseCase(this.repo);

  Future<UserEntity?> call({
    required String verificationId,
    required String otp,
  }) async {
    final result = await repo.verifyOtpAndSignIn(
      verificationId: verificationId,
      otp: otp,
    );

    return result.fold((_) => null, (user) => user);
  }
}