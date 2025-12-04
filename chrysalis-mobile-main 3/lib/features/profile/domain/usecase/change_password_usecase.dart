import 'package:chrysalis_mobile/features/profile/domain/repository/profile_repository.dart';

class ChangePasswordUsecase {
  ChangePasswordUsecase(this.repository);
  final ProfileRepository repository;

  Future<String> call(String userId, String currentPassword, String newPassword) async {
    if (currentPassword.isEmpty) {
      throw Exception('Current password cannot be empty');
    }
    if (newPassword.isEmpty) {
      throw Exception('New password cannot be empty');
    }
    return repository.updatePassword(userId, currentPassword, newPassword);
  }
}