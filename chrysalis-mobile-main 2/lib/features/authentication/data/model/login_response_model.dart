import 'package:chrysalis_mobile/features/authentication/data/model/keys_model.dart';
import 'package:chrysalis_mobile/features/authentication/data/model/tokens_model.dart';
import 'package:chrysalis_mobile/features/authentication/data/model/user_model.dart';
import 'package:chrysalis_mobile/features/authentication/domain/entity/login_response_entity.dart';

class LoginResponseModel extends LoginResponseEntity {
  const LoginResponseModel({
    required super.user,
    required super.tokens,
    required super.keys,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      user: UserModel.fromJson((json['user'] as Map<String, dynamic>?) ?? {}),
      tokens: TokensModel.fromJson(
        (json['tokens'] as Map<String, dynamic>?) ?? {},
      ),
      keys: KeysModel.fromJson((json['keys'] as Map<String, dynamic>?) ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'user': (user as UserModel).toJson(),
    'tokens': (tokens as TokensModel).toJson(),
    'keys': (tokens as KeysModel).toJson(),
  };
}
