import 'package:chrysalis_mobile/core/crypto_services/crypto_service.dart';
import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/chat_detail_args.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

class NotificationNavigator {
  static Future<void> handleNotificationNavigation(
    RemoteMessage message,
  ) async {
    final data = message.data;
    final route = data['route'];
    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;

    if (route == 'chat_detail') {
      final crypto = CryptoService();
      await crypto.loadKeys();
      final decryptGroupKey = await crypto.decryptGroupSenderKey(
        data['groupKey'] as String? ?? '',
      );

      if (decryptGroupKey.length != 16 &&
          decryptGroupKey.length != 24 &&
          decryptGroupKey.length != 32) {
        throw Exception('Invalid AES key length: ${decryptGroupKey.length}');
      }
      await navContext.push(
        AppRoutes.chatDetail,
        extra: ChatDetailArgs(
          id: data['id'] as String? ?? '',
          type: data['type'] as String? ?? '',
          title: data['title'] as String? ?? '',
          isGroup: data['isGroup'] == 'true',
          avatar: data['avatar'] as String? ?? '',
          unReadMessage: int.parse((data['unreadCount'] as String?) ?? '0'),
          encryptedGroupKey: (data['groupKey'] as String?) ?? '',
          decryptGroupKey: decryptGroupKey,
          version: int.parse((data['version'] as String?) ?? '1'),
        ),
      );
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      // Default: go to home or splash
      navContext.go(AppRoutes.home);
    }
  }
}
