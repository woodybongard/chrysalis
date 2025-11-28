import 'package:encrypt/encrypt.dart';

class HomeEntity {
  HomeEntity({required this.data, required this.pagination});
  final List<GroupEntity> data;
  final PaginationEntity pagination;

  Future<HomeEntity> copyWith({
    List<GroupEntity>? data,
    PaginationEntity? pagination,
  }) async {
    return HomeEntity(
      data: data ?? this.data,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  String toString() {
    return 'HomeEntity{data: $data, pagination: $pagination}';
  }
}

class GroupEntity {
  GroupEntity({
    required this.type,
    required this.groupId,
    required this.name,
    required this.isGroup,
    required this.unreadCount,
    required this.version,
    this.avatar,
    this.lastMessage,
    this.typingText,
    this.groupKey,
  });
  final String type;
  final String groupId;
  final String name;
  final String? avatar;
  final bool isGroup;
  final LastMessageEntity? lastMessage;
  final int unreadCount;
  final int version;
  final String? typingText;
  final String? groupKey;

  @override
  String toString() {
    return 'GroupEntity{type: $type, id: $groupId, name: $name, avatar: $avatar,version:$version isGroup: $isGroup, lastMessage: $lastMessage, unreadCount: $unreadCount, typingText: $typingText, groupKey: $groupKey}';
  }

  GroupEntity copyWith({required Key decryptGroupKey}) {
    return GroupEntity(
      type: type,
      groupId: groupId,
      name: name,
      avatar: avatar,
      isGroup: isGroup,
      lastMessage: lastMessage?.copyWith(decryptedGroupKey: decryptGroupKey),
      unreadCount: unreadCount,
      typingText: typingText,
      groupKey: groupKey,
      version: version,
    );
  }
}

class LastMessageEntity {
  LastMessageEntity({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
    required this.isSenderYou,
    required this.status,
    required this.sender,
    required this.iv,
    required this.encryptedGroupKey,
    this.decryptedGroupKey,
  });
  final String id;
  final String type;
  final String content;
  final String createdAt;
  final bool isSenderYou;
  final String status;
  final String iv;
  final String encryptedGroupKey;
  final Key? decryptedGroupKey;
  final SenderEntity sender;

  LastMessageEntity copyWith({Key? decryptedGroupKey}) {
    return LastMessageEntity(
      id: id,
      type: type,
      content: content,
      createdAt: createdAt,
      isSenderYou: isSenderYou,
      status: status,
      sender: sender,
      iv: iv,
      encryptedGroupKey: encryptedGroupKey,
      decryptedGroupKey: decryptedGroupKey ?? this.decryptedGroupKey,
    );
  }

  @override
  String toString() {
    return 'LastMessageEntity{id: $id, type: $type, content: $content, createdAt: $createdAt, isSenderYou: $isSenderYou, status: $status, iv: $iv, encryptedGroupKey: $encryptedGroupKey, decryptedGroupKey: $decryptedGroupKey, sender: $sender}';
  }
}

class SenderEntity {
  SenderEntity({required this.id, required this.name});
  final String id;
  final String name;

  @override
  String toString() {
    return 'SenderEntity{id: $id, name: $name}';
  }
}

class PaginationEntity {
  PaginationEntity({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  @override
  String toString() {
    return 'PaginationEntity{page: $page, limit: $limit, total: $total, totalPages: $totalPages}';
  }
}
