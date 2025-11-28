import 'package:encrypt/encrypt.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/reaction_entity.dart';

class MessageEntity {
  MessageEntity({
    required this.id,
    required this.senderId,
    required this.encryptedText,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.avatar,
    required this.senderName,
    required this.isSenderYou,
    required this.iv,
    required this.encryptedGroupKey,
    this.conversationId,
    this.groupId,
    this.fileUrl,
    this.fileSize,
    this.fileName,
    this.fileType,
    this.filePages,
    this.showAvatarImage = false,
    this.showSenderName = false,
    this.decryptGroupKey,
    this.reactions = const [],
  });
  final String id;
  final String? conversationId;
  final String? groupId;
  final String senderId;
  final String encryptedText;
  final String iv;
  final String encryptedGroupKey;
  final String type;
  final Key? decryptGroupKey;
  final String status;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final String? fileSize;
  final String? filePages;
  final String createdAt;
  final String avatar;
  final String senderName;
  final bool isSenderYou;
  final bool showAvatarImage;
  final bool showSenderName;
  final List<ReactionEntity> reactions;

  @override
  String toString() {
    return 'MessageEntity{id: $id, conversationId: $conversationId,decryptGroupKey :$decryptGroupKey groupId: $groupId, senderId: $senderId, encryptedText: $encryptedText, type: $type, status: $status, fileUrl: $fileUrl, createdAt: $createdAt, avatar: $avatar, senderName: $senderName, isSenderYou: $isSenderYou, showAvatarImage: $showAvatarImage, showSenderName: $showSenderName}';
  }

  MessageEntity copyWith({
    String? id,
    String? conversationId,
    String? groupId,
    String? senderId,
    String? encryptedText,
    String? iv,
    String? c,
    String? type,

    String? status,
    String? fileUrl,
    String? createdAt,
    String? avatar,
    String? fileName,
    String? fileType,
    String? fileSize,
    String? filePages,
    bool? isSenderYou,
    bool? showAvatarImage,
    bool? showSenderName,
    String? encryptedGroupKey,
    Key? decryptGroupKey,
    List<ReactionEntity>? reactions,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      filePages: filePages ?? this.filePages,
      fileType: fileType ?? this.fileType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      encryptedText: encryptedText ?? this.encryptedText,
      iv: iv ?? this.iv,
      encryptedGroupKey: encryptedGroupKey ?? this.encryptedGroupKey,
      type: type ?? this.type,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
      avatar: avatar ?? this.avatar,
      senderName: senderName,
      isSenderYou: isSenderYou ?? this.isSenderYou,
      showAvatarImage: showAvatarImage ?? this.showAvatarImage,
      showSenderName: showSenderName ?? this.showSenderName,
      decryptGroupKey: decryptGroupKey ?? this.decryptGroupKey,
      reactions: reactions ?? this.reactions,
    );
  }
}

class MessagePaginationEntity {
  const MessagePaginationEntity({
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.total,
  });
  final int page;
  final int limit;
  final int totalPages;
  final int total;
}

class PaginatedMessagesEntity {
  const PaginatedMessagesEntity({
    required this.messages,
    required this.pagination,
  });
  final List<MessageEntity> messages;
  final MessagePaginationEntity pagination;
}
