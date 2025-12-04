import 'package:firebase_messaging/firebase_messaging.dart';

abstract class NotificationEvent {}

class NotificationReceived extends NotificationEvent {
  NotificationReceived(this.message);
  final RemoteMessage message;
}

class NotificationClear extends NotificationEvent {}
