class AuthErrorEntity implements Exception {
  const AuthErrorEntity({required this.message, this.details});
  final String message;
  final List<dynamic>? details;
}
