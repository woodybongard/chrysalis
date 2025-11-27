import 'package:chrysalis_mobile/features/notifications/domain/entity/notification_entity.dart';
import 'package:chrysalis_mobile/features/notifications/domain/repository/notification_repository.dart';

class HandleNotificationUseCase {
  HandleNotificationUseCase(this.repository);
  final NotificationRepository repository;

  Future<void> call(NotificationEntity notification) async {
    await repository.saveNotification(notification);
    // Add additional business logic if needed
  }
}
