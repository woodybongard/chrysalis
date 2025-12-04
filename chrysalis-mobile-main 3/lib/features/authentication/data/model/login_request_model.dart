import 'package:chrysalis_mobile/features/authentication/domain/entity/login_request_entity.dart';

class LoginRequestModel extends LoginRequestEntity {
  const LoginRequestModel({
    required super.login,
    required super.password,
    required super.deviceId,
    super.fcmToken,
  });

  Map<String, dynamic> toJson() => {
    'login': login,
    'password': password,
    // Only include fcmToken if it has a valid value (not null or empty)
    // This prevents web logins from overwriting mobile FCM tokens
    if (fcmToken != null && fcmToken!.isNotEmpty) 'fcmToken': fcmToken,
    'deviceId': deviceId,
  };
}
