import 'package:firebase_messaging/firebase_messaging.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationReceivedState extends NotificationState {
  NotificationReceivedState(this.message);
  final RemoteMessage message;
}
