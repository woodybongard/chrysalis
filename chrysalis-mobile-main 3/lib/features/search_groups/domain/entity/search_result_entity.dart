import 'package:chrysalis_mobile/features/homepage/domain/entity/home_entity.dart';

/// Represents a search result which can be a group, conversation, or user
class SearchResultEntity {
  SearchResultEntity({
    required this.type,
    required this.id,
    required this.name,
    this.avatar,
    this.isGroup,
    this.lastMessage,
    this.unreadCount,
    this.groupKey,
    this.convoKeyEnc,
    this.version,
    this.otherUserId,
    this.username,
    this.publicKey,
  });

  /// Type of search result: 'group', 'conversation', or 'user'
  final String type;

  /// Unique identifier
  final String id;

  /// Display name (group name, conversation name, or user's full name)
  final String name;

  /// Avatar URL
  final String? avatar;

  /// Whether this is a group (only for group/conversation types)
  final bool? isGroup;

  /// Last message in the chat (only for group/conversation types)
  final LastMessageEntity? lastMessage;

  /// Number of unread messages (only for group/conversation types)
  final int? unreadCount;

  /// Encrypted group key (only for group type)
  final String? groupKey;

  /// Encrypted conversation key (only for conversation type)
  final String? convoKeyEnc;

  /// Key version (only for group/conversation types)
  final int? version;

  /// Other user's ID (only for conversation type)
  final String? otherUserId;

  /// Username (only for user type)
  final String? username;

  /// Public key for E2E encryption (only for user type)
  final String? publicKey;

  /// Returns true if this is a group result
  bool get isGroupType => type == 'group';

  /// Returns true if this is a conversation result
  bool get isConversationType => type == 'conversation';

  /// Returns true if this is a user result
  bool get isUserType => type == 'user';

  /// Returns the encryption key based on type
  String? get encryptionKey => isGroupType ? groupKey : convoKeyEnc;

  @override
  String toString() {
    return 'SearchResultEntity{type: $type, id: $id, name: $name, avatar: $avatar}';
  }
}
