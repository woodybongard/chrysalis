import 'package:chrysalis_mobile/features/homepage/data/model/home_model.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/entity/search_result_entity.dart';

class SearchResultModel extends SearchResultEntity {
  SearchResultModel({
    required super.type,
    required super.id,
    required super.name,
    super.avatar,
    super.isGroup,
    super.lastMessage,
    super.unreadCount,
    super.groupKey,
    super.convoKeyEnc,
    super.version,
    super.otherUserId,
    super.username,
    super.publicKey,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    return SearchResultModel(
      type: type,
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      isGroup: json['isGroup'] as bool?,
      lastMessage: json['lastMessage'] != null
          ? LastMessageModel.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            )
          : null,
      unreadCount: json['unreadCount'] as int?,
      groupKey: json['groupKey'] as String?,
      convoKeyEnc: json['convoKeyEnc'] as String?,
      version: json['version'] as int?,
      otherUserId: json['otherUserId'] as String?,
      username: json['username'] as String?,
      publicKey: json['publicKey'] as String?,
    );
  }
}
