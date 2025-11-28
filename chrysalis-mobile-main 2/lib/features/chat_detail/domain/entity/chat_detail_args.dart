import 'package:encrypt/encrypt.dart';

class ChatDetailArgs {
  ChatDetailArgs({
    required this.id,
    required this.type,
    required this.title,
    required this.isGroup,
    required this.version,
    this.avatar,
    this.unReadMessage,
    this.decryptGroupKey,
    this.encryptedGroupKey,
  });
  final String id;
  final String type; // 'group' or 'conversation'
  final String title;
  final bool isGroup;
  final String? avatar;
  final int? unReadMessage;
  final int? version;
  final Key? decryptGroupKey;
  final String? encryptedGroupKey;
}
