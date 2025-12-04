import 'package:chrysalis_mobile/features/authentication/domain/entity/tokens_entity.dart';

class TokensModel extends TokensEntity {
  const TokensModel({
    required super.accessToken,
    required super.refreshToken,
    required super.expiresAt,
  });

  factory TokensModel.fromJson(Map<String, dynamic> json) {
    return TokensModel(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresAt: json['expiresAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt,
  };
}
