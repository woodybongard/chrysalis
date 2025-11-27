import 'dart:async';
import 'dart:convert';

import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/bloc/chat_detail_bloc.dart';
import 'package:chrysalis_mobile/features/notifications/presentation/notification_navigator.dart';
import 'package:chrysalis_mobile/features/notifications/presentation/widget/notification_overlay.dart';
import 'package:chrysalis_mobile/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //await NotificationService.setupFlutterNotifications();
  //await NotificationService.showFlutterNotification(message);
}

final GlobalKey<ScaffoldMessengerState> notificationScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class NotificationService {
  // Track unread message count per group
  static final Map<String, int> _groupUnreadCount = {};
  static late AndroidNotificationChannel channel;
  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  static bool _initialized = false;


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
          notificationCategories: [iosCategory],
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await _handleNotificationAction(response);
      },
    );

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    _initialized = true;
  }

  /// Show notification with Reply + Mark as Read actions, grouped by chat/group
  static Future<void> showFlutterNotification(RemoteMessage message) async {
    if (!_initialized) {
      await setupFlutterNotifications();
    }

    final notification = message.notification;
    final android = message.notification?.android;

    // Use chat/group id as group key
    final groupId = (message.data['id'] as String?) ?? 'default_group';

    // Increment unread count for this group
    _groupUnreadCount[groupId] = (_groupUnreadCount[groupId] ?? 0) + 1;

    // Compose notification body with count
    var mergedBody = notification?.body ?? '';
    final count = _groupUnreadCount[groupId]!;
    if (count > 1) {
      mergedBody = 'You have $count new messages';
    }

    if (notification != null && android != null && !kIsWeb) {
      // Show individual message notification (grouped)
      await flutterLocalNotificationsPlugin.show(
        groupId.hashCode, // Use groupId for notification id to overwrite
        notification.title,
        mergedBody,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: 'launch_background',
            groupKey: groupId, // Group by chat/group
            actions: const [
              AndroidNotificationAction(
                'REPLY_ACTION',
                'Reply',
                inputs: [AndroidNotificationActionInput(label: 'Type message')],
              ),
              AndroidNotificationAction('MARK_AS_READ_ACTION', 'Mark as Read'),
            ],
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'chatCategory',
            threadIdentifier: groupId, // iOS grouping
            subtitle: count > 1 ? '$count new messages' : null,
          ),
        ),
        payload: jsonEncode(message.data),
      );

      // Show group summary notification (Android only)
      await flutterLocalNotificationsPlugin.show(
        groupId.hashCode + 1, // Different id for summary
        'New messages',
        'You have $count new messages in this chat',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: 'launch_background',
            groupKey: groupId,
            setAsGroupSummary: true, // This is the summary notification
          ),
        ),
      );
    }
  }

  static Future<void> _handleNotificationAction(
    NotificationResponse response,
  ) async {
    final payload = response.payload != null
        ? jsonDecode(response.payload!) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.actionId == 'REPLY_ACTION') {
      final replyText = response.input;
      debugPrint('User replied: $replyText to chat ${payload['id']}');

      // TODO(developer): Call your sendMessage API here
      // sendMessage(chatId: payload['id'], text: replyText);
    } else if (response.actionId == 'MARK_AS_READ_ACTION') {
      debugPrint('User marked chat ${payload['id']} as read');

      // TODO(developer): Call your markAsRead API here
      // markMessageAsRead(chatId: payload['id']);
      // Reset unread count for this group
      if (payload['id'] != null) {
        _groupUnreadCount[payload['id'] as String] = 0;
      }
    } else {
      // Regular tap on notification
      await NotificationNavigator.handleNotificationNavigation(
        RemoteMessage.fromMap({'data': payload}),
      );
    }
  }

  static Future<void> initialize(BuildContext context) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Skip Firebase Messaging completely on web to avoid compatibility issues
    if (kIsWeb) {
      debugPrint('Firebase Messaging disabled on web platform');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await setupFlutterNotifications();
    
    //_ensureFCMToken();
    // Foreground handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      try {
        final navContext = navigatorKey.currentContext;

        // 🔹 Check if user is inside chat detail
        var isOnChatDetail = false;
        if (navContext != null && navContext.mounted) {
          final router = GoRouter.of(navContext);
          if (router.routeInformationProvider.value.uri.path ==
              AppRoutes.chatDetail) {
            final chatDetailState = navContext.read<ChatDetailBloc>().state;
            if (chatDetailState is ChatDetailLoaded) {
              isOnChatDetail =
                  chatDetailState.messages.isNotEmpty &&
                  (chatDetailState.messages.first.conversationId ==
                          message.data['id'] ||
                      chatDetailState.messages.first.groupId ==
                          message.data['id']);
            }
          }
        }

        if (isOnChatDetail) {
          // 👇 Suppress iOS foreground notification
          await FirebaseMessaging.instance
              .setForegroundNotificationPresentationOptions();
          // Do nothing (chat is open)
          return;
        } else {
          // 👇 Allow iOS foreground notification OR show custom banner
          await FirebaseMessaging.instance
              .setForegroundNotificationPresentationOptions(
                alert: true,
                badge: true,
                sound: true,
              );
          _showInAppBanner(
            message,
          ); // in-app banner (instead of system notif if you want)
        }
      } catch (e) {
        debugPrint('Error handling foreground message: $e');
        _showInAppBanner(message);
      }
    });

    // App opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(
      NotificationNavigator.handleNotificationNavigation,
    );
  }

  static OverlayEntry? _bannerOverlay;

  /// Show a simple in-app notification banner (replace with custom widget if needed)
  static void _showInAppBanner(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Remove any existing banner
    _bannerOverlay?.remove();

    // Use the navigatorKey's overlay context
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      debugPrint('No overlay found for in-app notification banner.');
      return;
    }

    _bannerOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: InAppNotificationBanner(
          title: notification.title,
          body: notification.body,
          avatar: (message.data['avatar'] as String?) ?? '',
          onTap: () {
            NotificationNavigator.handleNotificationNavigation(message);
            _bannerOverlay?.remove();
            _bannerOverlay = null;
          },
        ),
      ),
    );

    overlay.insert(_bannerOverlay!);

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      _bannerOverlay?.remove();
      _bannerOverlay = null;
    });
  }

  static Future<void> handleInitialMessage(BuildContext context) async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    await Future<void>.delayed(const Duration(seconds: 2));

    if (initialMessage != null) {
      await NotificationNavigator.handleNotificationNavigation(initialMessage);
    }
  }
}
