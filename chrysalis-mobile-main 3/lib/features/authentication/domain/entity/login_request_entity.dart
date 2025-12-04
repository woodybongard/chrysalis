class LoginRequestEntity {
  const LoginRequestEntity({
    required this.login,
    required this.password,
    required this.deviceId,
    this.fcmToken,
  });
  final String login;
  final String password;
  final String? fcmToken;
  final String deviceId;
}
