import 'package:chrysalis_mobile/features/profile/domain/repository/profile_repository.dart';

class ToggleNotificationsUsecase {
  ToggleNotificationsUsecase(this.repository);
  final ProfileRepository repository;

  Future<String> call(bool isNotification) async {
    return repository.toggleNotifications(isNotification);
  }
}