class TokensEntity {
  const TokensEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });
  final String accessToken;
  final String refreshToken;
  final String expiresAt;
}
