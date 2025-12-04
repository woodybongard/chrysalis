class MessageStatusUpdateEntity {
  MessageStatusUpdateEntity({
    required this.chatId,
    required this.type,
    required this.messages,
  });

  factory MessageStatusUpdateEntity.fromJson(Map<String, dynamic> json) {
    return MessageStatusUpdateEntity(
      chatId: json['chatId'] as String,
      type: json['type'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => MessageStatusEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  final String chatId;
  final String type;
  final List<MessageStatusEntity> messages;
}

class MessageStatusEntity {
  MessageStatusEntity({
    required this.id,
    required this.senderId,
    required this.status,
  });

  factory MessageStatusEntity.fromJson(Map<String, dynamic> json) {
    return MessageStatusEntity(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      status: json['status'] as String,
    );
  }
  final String id;
  final String senderId;
  final String status;
}
