import 'package:chrysalis_mobile/features/authentication/domain/entity/login_request_entity.dart';

class LoginRequestModel extends LoginRequestEntity {
  const LoginRequestModel({
    required super.login,
    required super.password,
    required super.fcmToken,
    required super.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'login': login,
    'password': password,
    'fcmToken': fcmToken,
    'deviceId': deviceId,
  };
}
