import 'package:chrysalis_mobile/features/authentication/domain/entity/login_request_entity.dart';
import 'package:chrysalis_mobile/features/authentication/domain/entity/login_response_entity.dart';
import 'package:chrysalis_mobile/features/authentication/domain/repository/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this.repository);
  final AuthRepository repository;

  Future<LoginResponseEntity> call(LoginRequestEntity request) async {
    return repository.login(request);
  }
}
