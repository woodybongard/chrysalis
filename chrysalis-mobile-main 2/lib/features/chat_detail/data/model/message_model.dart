import 'package:chrysalis_mobile/features/chat_detail/domain/entity/message_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/data/model/reaction_model.dart';

class PaginatedMessagesModel {
  PaginatedMessagesModel({required this.messages, required this.pagination});

  factory PaginatedMessagesModel.fromJson(Map<String, dynamic> json) {
    final messages = MessageModel.listFromJson(json['data']);
    final pagination = MessagePaginationModel.fromJson(
      (json['pagination'] as Map<String, dynamic>?) ?? {},
    );
    return PaginatedMessagesModel(messages: messages, pagination: pagination);
  }
  final List<MessageModel> messages;
  final MessagePaginationModel pagination;
}

class MessagePaginationModel extends MessagePaginationEntity {
  const MessagePaginationModel({
    required super.page,
    required super.limit,
    required super.totalPages,
    required super.total,
  });

  factory MessagePaginationModel.fromJson(Map<String, dynamic> json) {
    return MessagePaginationModel(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 1,
      total: json['total'] as int? ?? 0,
    );
  }
}

class MessageModel extends MessageEntity {
  MessageModel({
    required super.id,
    required super.senderId,
    required super.encryptedText,
    required super.type,
    required super.status,
    required super.createdAt,
    required super.avatar,
    required super.senderName,
    required super.isSenderYou,
    required super.iv,
    required super.encryptedGroupKey,
    required super.decryptGroupKey,
    super.conversationId,
    super.groupId,
    super.fileUrl,
    super.fileName,
    super.fileType,
    super.fileSize,
    super.filePages,
    super.reactions,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final thumbnail =
        (json['thumbnail'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final reactionsJson = json['reactions'] as List<dynamic>? ?? [];
    final reactions = ReactionModel.listFromJson(reactionsJson);
    
    return MessageModel(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String?,
      groupId: json['groupId'] as String?,
      senderId: json['senderId'] as String? ?? '',
      encryptedText: json['encryptedText'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      fileUrl: json['fileUrl'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      avatar: json['senderAvatar'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      isSenderYou: json['isSenderYou'] == true,
      iv: json['iv'] as String? ?? '',
      encryptedGroupKey: json['aesKeyEncB64Url'] as String? ?? '',
      decryptGroupKey: null, // This will be set later during decryption process
      fileName: thumbnail['fileName'] as String?,
      fileType: thumbnail['fileType'] as String?,
      fileSize: thumbnail['fileSize']?.toString(),
      filePages: thumbnail['filePages']?.toString(),
      reactions: reactions,
    );
  }

  /// Converts a JSON list to a List<MessageModel>
  static List<MessageModel> listFromJson(dynamic jsonList) {
    if (jsonList is List) {
      return jsonList
          .whereType<Map<String, dynamic>>()
          .map(MessageModel.fromJson)
          .toList();
    }
    return [];
  }
}
