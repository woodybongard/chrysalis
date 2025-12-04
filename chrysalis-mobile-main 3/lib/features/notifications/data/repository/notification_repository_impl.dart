import 'package:chrysalis_mobile/features/notifications/domain/entity/notification_entity.dart';
import 'package:chrysalis_mobile/features/notifications/domain/repository/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final List<NotificationEntity> _notifications = [];

  @override
  Future<void> saveNotification(NotificationEntity notification) async {
    _notifications.add(notification);
  }

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    return _notifications;
  }

  @override
  Future<void> clearNotifications() async {
    _notifications.clear();
  }
}
