import 'dart:convert';
import 'dart:developer' as developer;

import 'package:chrysalis_mobile/features/chat_detail/data/model/message_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class ChatDetailLocalDataSource {
  Future<void> cacheMessages({
    required String type,
    required String id,
    required List<MessageModel> messages,
    required int page,
  });

  Future<List<MessageModel>> getCachedMessages({
    required String type,
    required String id,
    int? page,
  });

  Future<void> upsertMessage({
    required String type,
    required String id,
    required MessageModel message,
  });

  Future<void> clearChat({required String type, required String id});
}

class ChatDetailLocalDataSourceImpl implements ChatDetailLocalDataSource {
  ChatDetailLocalDataSourceImpl(this._box);
  final Box<String> _box;

  String _key(String type, String id, [int? page]) =>
      'chat:$type:$id${page != null ? ':page:$page' : ''}';

  @override
  Future<void> cacheMessages({
    required String type,
    required String id,
    required List<MessageModel> messages,
    required int page,
  }) async {
    final key = _key(type, id, page);
    final jsonList = messages
        .map((m) => jsonEncode({
              'id': m.id,
              'conversationId': m.conversationId,
              'groupId': m.groupId,
              'senderId': m.senderId,
              'encryptedText': m.encryptedText,
              'type': m.type,
              'status': m.status,
              'fileUrl': m.fileUrl,
              'createdAt': m.createdAt,
              'senderAvatar': m.avatar,
              'senderName': m.senderName,
              'isSenderYou': m.isSenderYou,
              'iv': m.iv,
              'aesKeyEncB64Url': m.encryptedGroupKey,
              'thumbnail': {
                'fileName': m.fileName,
                'fileType': m.fileType,
                'fileSize': m.fileSize,
                'filePages': m.filePages,
              }
            }))
        .toList();
    await _box.put(key, jsonEncode(jsonList));
    developer.log('[Hive][cacheMessages] key=$key, saved=${messages.length}');
  }

  @override
  Future<List<MessageModel>> getCachedMessages({
    required String type,
    required String id,
    int? page,
  }) async {
    final key = _key(type, id, page);
    final raw = _box.get(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    final list = decoded
        .whereType<String>()
        .map((s) => jsonDecode(s) as Map<String, dynamic>)
        .map(MessageModel.fromJson)
        .toList();
    developer.log('[Hive][getCachedMessages] key=$key, found=${list.length}');
    return list;
  }

  @override
  Future<void> upsertMessage({
    required String type,
    required String id,
    required MessageModel message,
  }) async {
    // Store latest messages under page 1 key; prepend for simplicity
    final existing = await getCachedMessages(type: type, id: id, page: 1);
    final updated = [message, ...existing];
    await cacheMessages(type: type, id: id, messages: updated, page: 1);
    developer.log('[Hive][upsertMessage] type=$type, id=$id, newCount=${updated.length}');
  }

  @override
  Future<void> clearChat({required String type, required String id}) async {
    final keys = _box.keys.whereType<String>().where(
          (k) => k.startsWith('chat:$type:$id'),
        );
    final toDelete = keys.toList();
    await _box.deleteAll(toDelete);
    developer.log('[Hive][clearChat] type=$type, id=$id, deleted=${toDelete.length}');
  }
}
