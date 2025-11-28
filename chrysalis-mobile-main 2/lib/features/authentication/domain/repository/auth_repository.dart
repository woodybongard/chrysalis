// import '../entity/auth_error_entity.dart';
import 'package:chrysalis_mobile/features/authentication/data/model/logout_model.dart';
import 'package:chrysalis_mobile/features/authentication/domain/entity/login_request_entity.dart';
import 'package:chrysalis_mobile/features/authentication/domain/entity/login_response_entity.dart';

abstract class AuthRepository {
  Future<LoginResponseEntity> login(LoginRequestEntity request);
  Future<LogoutResponseModel> logout(
    LogoutRequestModel request,
    String accessToken,
  );

  Future<void> registerKey({
    required String publicKeyPem,
    required String privateKeyEnc,
    required String deviceId,
  });
}
