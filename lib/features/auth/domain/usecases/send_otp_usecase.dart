import '../repositories/i_auth_repository.dart';

class SendOtpUseCase {
  final IAuthRepository repo;

  SendOtpUseCase(this.repo);

  Future<void> call(String phone) async {
    await repo.sendOtp(phone);
  }
}