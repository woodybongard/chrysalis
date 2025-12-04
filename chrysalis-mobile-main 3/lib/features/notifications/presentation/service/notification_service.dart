import 'dart:async';
import 'dart:convert';

import 'package:chrysalis_mobile/core/socket/chat_list_helper.dart';
import 'package:chrysalis_mobile/features/notifications/presentation/notification_navigator.dart';
import 'package:chrysalis_mobile/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

final GlobalKey<ScaffoldMessengerState> notificationScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class NotificationService {
  // Track unread message count per group
  static final Map<String, int> _groupUnreadCount = {};
  static late AndroidNotificationChannel channel;
  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  static bool _initialized = false;

  // Track which chat is currently being viewed
  static String? _currentlyViewingChatId;

  static void setCurrentlyViewingChat(String? chatId) {
    _currentlyViewingChatId = chatId;
    _updateForegroundNotificationOptions();
  }

  static Future<void> _updateForegroundNotificationOptions() async {
    if (_currentlyViewingChatId != null) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
    } else {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }


  static Future<void> setupFlutterNotifications() async {
    if (_initialized) return;

     channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android notification channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // iOS: register categories for reply/mark actions
    final iosCategory = DarwinNotificationCategory(
      'chatCategory',
      actions: [
        DarwinNotificationAction.text(
          'REPLY_ACTION',
          'Reply',
          buttonTitle: 'Send',
          placeholder: 'Type message...',
        ),
        DarwinNotificationAction.plain('MARK_AS_READ_ACTION', 'Mark as Read'),
      ],
    );

    await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          notificationCategories: [iosCategory],
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await _handleNotificationAction(response);
      },
    );

    // Request iOS local notification permissions
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static Future<void> showFlutterNotification(RemoteMessage message) async {
    if (!_initialized) {
      await setupFlutterNotifications();
    }

    final notification = message.notification;
    final android = message.notification?.android;
    final groupId = (message.data['id'] as String?) ?? 'default_group';

    _groupUnreadCount[groupId] = (_groupUnreadCount[groupId] ?? 0) + 1;

    var mergedBody = notification?.body ?? '';
    final count = _groupUnreadCount[groupId]!;
    final isGrouped = count > 1;
    
    if (isGrouped) {
      mergedBody = 'You have $count new messages';
    }

    if (notification != null && !kIsWeb) {
      final title = notification.title ?? message.data['title'] as String?;
      final body = isGrouped ? mergedBody : (notification.body ?? '');

      // Create enhanced payload with grouping information
      final enhancedData = Map<String, dynamic>.from(message.data);
      enhancedData['isGrouped'] = isGrouped.toString();
      enhancedData['messageCount'] = count.toString();
      
      // Show individual notification
      await flutterLocalNotificationsPlugin.show(
        groupId.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: 'launch_background',
            groupKey: groupId,
            // Only show actions for individual messages, not grouped ones
            actions: !isGrouped ? const [
              AndroidNotificationAction(
                'REPLY_ACTION',
                'Reply',
                inputs: [AndroidNotificationActionInput(label: 'Type message')],
              ),
              AndroidNotificationAction('MARK_AS_READ_ACTION', 'Mark as Read'),
            ] : const [],
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'chatCategory',
            threadIdentifier: groupId,
            subtitle: isGrouped ? '$count new messages' : null,
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(enhancedData),
      );

      // For Android: Create summary notification only when grouped
      if (android != null && isGrouped) {
        await flutterLocalNotificationsPlugin.show(
          groupId.hashCode + 1,
          '$title',
          'You have $count new messages in this conversation',
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: 'launch_background',
              groupKey: groupId,
              setAsGroupSummary: true,
              actions: const [
                AndroidNotificationAction('VIEW_ALL_ACTION', 'View All'),
              ],
            ),
          ),
          payload: jsonEncode({
            ...enhancedData,
            'isSummary': 'true',
          }),
        );
      }
    }
  }

  static Future<void> _handleNotificationAction(
    NotificationResponse response,
  ) async {
    final payload = response.payload != null
        ? jsonDecode(response.payload!) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.actionId == 'MARK_AS_READ_ACTION') {
      if (payload['id'] != null) {
        _groupUnreadCount[payload['id'] as String] = 0;
      }
    } else {
      await NotificationNavigator.handleNotificationNavigation(
        RemoteMessage.fromMap({'data': payload}),
      );
    }
  }

  static Future<void> initialize(BuildContext context) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kIsWeb) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await setupFlutterNotifications();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Emit message:delivered when push notification is received
      final messageId = message.data['messageId'] as String?;
      if (messageId != null && messageId.isNotEmpty) {
        await ChatListHelper().emitMessageDelivered(messageId: messageId);
      }
    });

    // App opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      // Emit message:delivered when app is opened from notification
      final messageId = message.data['messageId'] as String?;
      if (messageId != null && messageId.isNotEmpty) {
        await ChatListHelper().emitMessageDelivered(messageId: messageId);
      }
      await NotificationNavigator.handleNotificationNavigation(message);
    });
  }

  static Future<void> clearNotificationsForChat(String chatId) async {
    if (!_initialized) return;
    _groupUnreadCount[chatId] = 0;
    await flutterLocalNotificationsPlugin.cancel(chatId.hashCode);
    await flutterLocalNotificationsPlugin.cancel(chatId.hashCode + 1);
  }

  static Future<void> handleInitialMessage(BuildContext context) async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    await Future<void>.delayed(const Duration(seconds: 2));

    if (initialMessage != null) {
      await NotificationNavigator.handleNotificationNavigation(initialMessage);
    }
  }
}
