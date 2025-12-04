import 'package:chrysalis_mobile/features/notifications/domain/entity/notification_entity.dart';

abstract class NotificationRepository {
  Future<void> saveNotification(NotificationEntity notification);
  Future<List<NotificationEntity>> getNotifications();
  Future<void> clearNotifications();
}
