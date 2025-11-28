import 'package:chrysalis_mobile/features/homepage/domain/entity/home_entity.dart';

class HomeModel extends HomeEntity {
  HomeModel({required super.data, required super.pagination});

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    return HomeModel(
      data: (json['data'] as List<dynamic>)
          .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationModel.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}

class GroupModel extends GroupEntity {
  GroupModel({
    required super.type,
    required super.groupId,
    required super.name,
    required super.unreadCount,
    required super.groupKey,
    required super.version,
    super.isGroup = false,
    super.avatar,
    super.lastMessage,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      type: json['type'] as String,
      groupId: json['id'] as String,
      name: json['name'] as String,
      isGroup: json['isGroup'] as bool? ?? false,
      avatar: json['avatar'] as String?,
      lastMessage: json['lastMessage'] != null
          ? LastMessageModel.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            )
          : null,
      unreadCount: json['unreadCount'] as int,
      groupKey: json['groupKey'] as String? ?? '',
      version: json['version'] as int? ?? 0,
    );
  }
}

class LastMessageModel extends LastMessageEntity {
  LastMessageModel({
    required super.id,
    required super.type,
    required super.content,
    required super.createdAt,
    required super.isSenderYou,
    required super.status,
    required super.sender,
    super.iv,
    required super.encryptedGroupKey,
    super.decryptedGroupKey,
  });

  factory LastMessageModel.fromJson(Map<String, dynamic> json) {
    return LastMessageModel(
      id: json['id'] as String,
      type: json['type'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] as String,
      isSenderYou: json['isSenderYou'] as bool,
      status: json['status'] as String,
      sender: SenderModel.fromJson(json['sender'] as Map<String, dynamic>),
      iv: json['iv'] as String?,
      encryptedGroupKey: json['aesKeyEncB64Url'] as String,
    );
  }
}

class SenderModel extends SenderEntity {
  SenderModel({required super.id, required super.name});

  factory SenderModel.fromJson(Map<String, dynamic> json) {
    return SenderModel(id: json['id'] as String, name: json['name'] as String);
  }
}

class PaginationModel extends PaginationEntity {
  PaginationModel({
    required super.page,
    required super.limit,
    required super.total,
    required super.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
