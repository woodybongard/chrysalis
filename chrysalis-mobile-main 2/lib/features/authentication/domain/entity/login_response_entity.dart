import 'package:chrysalis_mobile/features/authentication/domain/entity/key_entity.dart';
import 'package:chrysalis_mobile/features/authentication/domain/entity/tokens_entity.dart';
import 'package:chrysalis_mobile/features/authentication/domain/entity/user_entity.dart';

class LoginResponseEntity {
  const LoginResponseEntity({
    required this.user,
    required this.tokens,
    required this.keys,
  });
  final UserEntity user;
  final TokensEntity tokens;
  final KeyEntity keys;
}
