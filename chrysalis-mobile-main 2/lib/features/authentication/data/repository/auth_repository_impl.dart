import 'package:chrysalis_mobile/features/authentication/data/model/login_request_model.dart';
import 'package:chrysalis_mobile/features/authentication/data/model/logout_model.dart';
import 'package:chrysalis_mobile/features/authentication/data/remote/auth_remote_service.dart';
import 'package:chrysalis_mobile/features/authentication/domain/entity/login_request_entity.dart';
import 'package:chrysalis_mobile/features/authentication/domain/entity/login_response_entity.dart';
import 'package:chrysalis_mobile/features/authentication/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.remoteService);
  final AuthRemoteService remoteService;

  @override
  Future<LoginResponseEntity> login(LoginRequestEntity request) async {
    final model = LoginRequestModel(
      login: request.login,
      password: request.password,
      fcmToken: request.fcmToken,

      deviceId: request.deviceId,
    );
    final response = await remoteService.login(model);
    return response;
  }

  @override
  Future<LogoutResponseModel> logout(
    LogoutRequestModel request,
    String accessToken,
  ) async {
    return remoteService.logout(request, accessToken);
  }

  @override
  Future<void> registerKey({
    required String publicKeyPem,
    required String privateKeyEnc,
    required String deviceId,
  }) async {
    await remoteService.registerKey(
      publicKeyPem: publicKeyPem,
      privateKeyEnc: privateKeyEnc,
      deviceId: deviceId,
    );
  }
}
