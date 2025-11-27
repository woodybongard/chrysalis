import 'package:chrysalis_mobile/features/authentication/data/model/logout_model.dart';
import 'package:chrysalis_mobile/features/authentication/domain/repository/auth_repository.dart';

class LogoutUseCase {
  LogoutUseCase(this.repository);
  final AuthRepository repository;

  Future<LogoutResponseModel> call(
    LogoutRequestModel request,
    String accessToken,
  ) {
    return repository.logout(request, accessToken);
  }
}
