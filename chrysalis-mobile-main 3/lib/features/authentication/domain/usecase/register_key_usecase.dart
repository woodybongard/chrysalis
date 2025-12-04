import 'package:chrysalis_mobile/features/authentication/domain/repository/auth_repository.dart';

class RegisterKeyUsecase {
  RegisterKeyUsecase(this.repository);
  final AuthRepository repository;

  Future<void> call(
    String publicKeyPem,
    String privateKeyEnc,
    String deviceId,
  ) async {
    return repository.registerKey(
      publicKeyPem: publicKeyPem,
      privateKeyEnc: privateKeyEnc,
      deviceId: deviceId,
    );
  }
}
