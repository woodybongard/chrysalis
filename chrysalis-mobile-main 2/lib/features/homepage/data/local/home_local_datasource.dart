import 'dart:convert';
import 'dart:developer' as developer;

import 'package:chrysalis_mobile/features/homepage/data/model/home_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class HomeLocalDataSource {
  Future<void> cacheChatList({
    required List<GroupModel> groups,
    required int page,
    required int limit,
  });

  Future<List<GroupModel>> getCachedChatList({
    required int page,
    required int limit,
  });

  Future<void> clearChatList();
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  HomeLocalDataSourceImpl(this._box);
  final Box<String> _box;

  String _key(int page, int limit) => 'home:page:$page:limit:$limit';

  @override
  Future<void> cacheChatList({
    required List<GroupModel> groups,
    required int page,
    required int limit,
  }) async {
    final key = _key(page, limit);
    final jsonList = groups
        .map((g) => jsonEncode({
              'type': g.type,
              'groupId': g.groupId,
              'name': g.name,
              'avatar': g.avatar,
              'isGroup': g.isGroup,
              'unreadCount': g.unreadCount,
              'groupKey': g.groupKey,
              'version': g.version,
              if (g.lastMessage != null)
                'lastMessage': {
                  'id': g.lastMessage!.id,
                  'type': g.lastMessage!.type,
                  'content': g.lastMessage!.content,
                  'createdAt': g.lastMessage!.createdAt,
                  'isSenderYou': g.lastMessage!.isSenderYou,
                  'status': g.lastMessage!.status,
                  'sender': {
                    'id': g.lastMessage!.sender.id,
                    'name': g.lastMessage!.sender.name,
                  },
                  'iv': g.lastMessage!.iv,
                  'encryptedGroupKey': g.lastMessage!.encryptedGroupKey,
                  'decryptedGroupKey': g.lastMessage!.decryptedGroupKey,
                },
            }))
        .toList();
    await _box.put(key, jsonEncode(jsonList));
    developer.log('[Hive][Home][cache] key=$key saved=${groups.length}');
  }

  @override
  Future<List<GroupModel>> getCachedChatList({
    required int page,
    required int limit,
  }) async {
    final key = _key(page, limit);
    final raw = _box.get(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    final list = decoded
        .whereType<String>()
        .map((s) => jsonDecode(s) as Map<String, dynamic>)
        .map(GroupModel.fromJson)
        .toList();
    developer.log('[Hive][Home][get] key=$key found=${list.length}');
    return list;
  }

  @override
  Future<void> clearChatList() async {
    final keys = _box.keys.whereType<String>().where((k) => k.startsWith('home:'));
    final toDelete = keys.toList();
    await _box.deleteAll(toDelete);
    developer.log('[Hive][Home][clear] deleted=${toDelete.length}');
  }
}


