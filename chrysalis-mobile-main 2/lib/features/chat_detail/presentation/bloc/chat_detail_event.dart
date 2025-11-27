part of 'chat_detail_bloc.dart';

/// Event to update a message's file path after download/decrypt
class UpdateMessageFilePathEvent extends ChatDetailEvent {
  const UpdateMessageFilePathEvent({
    required this.messageId,
    required this.filePath,
  });
  final String messageId;
  final String filePath;

  @override
  List<Object?> get props => [messageId, filePath];
}

// Event for updating message statuses from socket
class ChatMessagesStatusUpdatedEvent extends ChatDetailEvent {
  const ChatMessagesStatusUpdatedEvent(this.update);
  final MessageStatusUpdateEntity update;

  @override
  List<Object?> get props => [update];
}

/// Event to retry sending a file message
class RetrySendFileMessageEvent extends ChatDetailEvent {
  const RetrySendFileMessageEvent(this.message, this.version);
  final MessageEntity message;
  final int version;
  @override
  List<Object?> get props => [message, version];
}

abstract class ChatDetailEvent extends Equatable {
  const ChatDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadChatMessagesEvent extends ChatDetailEvent {
  const LoadChatMessagesEvent({
    required this.type,
    required this.id,
    this.page = 1,
    this.limit = 20,
  });
  final String type; // 'group' or 'conversation'
  final String id;
  final int page;
  final int limit;

  @override
  List<Object?> get props => [type, id, page, limit];
}

class LoadMoreChatMessagesEvent extends ChatDetailEvent {
  const LoadMoreChatMessagesEvent();
}

class PrependNewMessageEvent extends ChatDetailEvent {
  const PrependNewMessageEvent(this.chatMessages);
  final MessageEntity chatMessages;

  @override
  List<Object?> get props => [chatMessages];
}

class SendMessageEvent extends ChatDetailEvent {
  const SendMessageEvent({
    required this.isGroup,
    required this.id,
    required this.content,
    required this.currentUserId,
    required this.encryptedGroupKey,
    required this.iv,
    required this.version,
  });
  final bool isGroup;
  final String id;
  final String content;
  final String currentUserId;
  final String encryptedGroupKey;
  final String iv;
  final int version;

  @override
  List<Object?> get props => [
    isGroup,
    id,
    content,
    currentUserId,
    encryptedGroupKey,
    iv,
    version,
  ];
}

/// Event for sending a file message
class SendFileMessageEvent extends ChatDetailEvent {
  const SendFileMessageEvent({
    required this.isGroup,
    required this.groupId,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.currentUserId,
    required this.encryptedGroupKey,
    required this.fileSize,
    required this.filePages,
    required this.version,
    required this.iv,
    required this.content,
  });
  final bool isGroup;
  final String groupId;
  final String filePath;
  final String fileName;
  final String fileType;
  final String currentUserId;
  final String encryptedGroupKey;
  final String fileSize;
  final int filePages;
  final int version;
  final String iv;
  final String content;

  @override
  List<Object?> get props => [
    isGroup,
    groupId,
    filePath,
    content,
    fileName,
    fileType,
    iv,
    currentUserId,
    encryptedGroupKey,
    fileSize,
    filePages,
    version,
  ];
}

/// Event to retry sending an existing message instance (not a new copy)
class RetrySendMessageEvent extends ChatDetailEvent {
  const RetrySendMessageEvent(this.message, this.version);
  final MessageEntity message;
  final int version;

  @override
  List<Object?> get props => [message];
}

class AddReactionEvent extends ChatDetailEvent {
  const AddReactionEvent({
    required this.messageId,
    required this.emoji,
    required this.chatId,
    required this.isGroup,
  });
  final String messageId;
  final String emoji;
  final String chatId;
  final bool isGroup;

  @override
  List<Object?> get props => [messageId, emoji, chatId, isGroup];
}

class RemoveReactionEvent extends ChatDetailEvent {
  const RemoveReactionEvent({
    required this.messageId,
    required this.chatId,
    required this.isGroup,
  });
  final String messageId;
  final String chatId;
  final bool isGroup;

  @override
  List<Object?> get props => [messageId, chatId, isGroup];
}

class ReactionAddedEvent extends ChatDetailEvent {
  const ReactionAddedEvent({
    required this.messageId,
    required this.reaction,
  });
  final String messageId;
  final Map<String, dynamic> reaction;

  @override
  List<Object?> get props => [messageId, reaction];
}

class ReactionRemovedEvent extends ChatDetailEvent {
  const ReactionRemovedEvent({
    required this.messageId,
    required this.userId,
  });
  final String messageId;
  final String userId;

  @override
  List<Object?> get props => [messageId, userId];
}
