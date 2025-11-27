import 'dart:convert';
import 'dart:developer' as logger;

import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';
import 'package:chrysalis_mobile/core/network/socket_service.dart';
import 'package:chrysalis_mobile/core/socket/entities/message_status_update_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/data/model/message_model.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/message_entity.dart';
import 'package:chrysalis_mobile/features/homepage/data/model/home_model.dart';
import 'package:chrysalis_mobile/features/homepage/domain/entity/home_entity.dart';

/// 🔥 Colorful Socket Logger
class SocketLogger {
  static void log(String event, dynamic data) {
    final now = DateTime.now().toIso8601String();
    logger.log('[SOCKET][$event][$now]: $data');
  }
}

class ChatListHelper {
  ChatListHelper({SocketService? socketService, LocalStorage? localStorage})
    : _socketService = socketService ?? SocketService(),
      _localStorage = localStorage ?? LocalStorage();
  final SocketService _socketService;
  final LocalStorage _localStorage;

  /// Listens for 'chatlist_update' events
  void listenForChatListUpdate(
    void Function({
      required String chatId,
      required String lastMessageId,
      required String lastMessageStatus,
    })
    onUpdate,
  ) {
    _socketService.socket?.off('chatlist_update');
    _socketService.socket?.on('chatlist_update', (data) {
      final mapData = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      final chatId = mapData['chatId'] as String? ?? '';
      final lastMessageId = mapData['lastMessageId'] as String? ?? '';
      final lastMessageStatus = mapData['lastMessageStatus'] as String? ?? '';
      SocketLogger.log('chatlist_update', mapData);
      onUpdate(
        chatId: chatId,
        lastMessageId: lastMessageId,
        lastMessageStatus: lastMessageStatus,
      );
    });
  }

  /// Listens for 'messages_update_status'
  void listenForMessagesUpdateStatus(
    void Function(MessageStatusUpdateEntity) onUpdate,
  ) {
    _socketService.socket?.off('messages_update_status');
    _socketService.socket?.on('messages_update_status', (data) {
      final mapData = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      SocketLogger.log('messages_update_status', mapData);
      final updateEntity = MessageStatusUpdateEntity.fromJson(mapData);
      onUpdate(updateEntity);
    });
  }

  /// Listens for 'user_stop_typing'
  void listenForUserStopTyping(
    void Function({required String userId, required String conversationId})
    onUserStopTyping,
  ) {
    _socketService.socket?.off('user_stop_typing');
    _socketService.socket?.on('user_stop_typing', (data) {
      final mapData = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      SocketLogger.log('stop_typing', mapData);
      final userId = mapData['userId'] as String? ?? '';
      final conversationId = mapData['conversationId'] as String? ?? '';
      onUserStopTyping(userId: userId, conversationId: conversationId);
    });
  }

  /// Listens for 'user_typing'
  void listenForUserTyping(
    void Function({
      required String userId,
      required String conversationId,
      required String name,
    })
    onUserTyping,
  ) {
    _socketService.socket?.off('user_typing');
    _socketService.socket?.on('user_typing', (data) {
      final mapData = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      SocketLogger.log('typing', mapData);
      final userId = mapData['userId'] as String? ?? '';
      final conversationId = mapData['conversationId'] as String? ?? '';
      final name = mapData['name'] as String? ?? '';
      onUserTyping(userId: userId, conversationId: conversationId, name: name);
    });
  }

  void listenForUserTypingList(
    void Function({
      required String userId,
      required String conversationId,
      required String name,
    })
    onUserTyping,
  ) {
    _socketService.socket?.off('user_typing_list');
    _socketService.socket?.on('user_typing_list', (data) {
      final mapData = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      SocketLogger.log('typing', mapData);
      final userId = mapData['userId'] as String? ?? '';
      final conversationId = mapData['conversationId'] as String? ?? '';
      final name = mapData['name'] as String? ?? '';
      onUserTyping(userId: userId, conversationId: conversationId, name: name);
    });
  }

  void listenForUserStopTypingList(
    void Function({
      required String userId,
      required String conversationId,
      required String name,
    })
    onUserTyping,
  ) {
    _socketService.socket?.off('user_stop_typing_list');
    _socketService.socket?.on('user_stop_typing_list', (data) {
      final mapData = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      SocketLogger.log('stop_typing', mapData);
      final userId = mapData['userId'] as String? ?? '';
      final conversationId = mapData['conversationId'] as String? ?? '';
      final name = mapData['name'] as String? ?? '';
      onUserTyping(userId: userId, conversationId: conversationId, name: name);
    });
  }

  Future<void> joinUserRoom() async {
    final userId = await _localStorage.read(key: AppKeys.userID);
    if (userId == null || userId.isEmpty) {
      SocketLogger.log('join', 'No userId found in local storage.');
      return;
    }
    final joinData = {'userId': userId};
    SocketLogger.log('join', joinData);
    _socketService.socket?.emit('join_user_room', joinData);
  }

  GroupEntity _mapGroupModelToEntity(GroupModel g) {
    return GroupEntity(
      type: g.type,
      groupId: g.groupId,
      name: g.name,
      avatar: g.avatar,
      isGroup: g.isGroup,
      lastMessage: g.lastMessage != null
          ? LastMessageEntity(
              id: g.lastMessage!.id,
              type: g.lastMessage!.type,
              content: g.lastMessage!.content,
              createdAt: g.lastMessage!.createdAt,
              isSenderYou: g.lastMessage!.isSenderYou,
              status: g.lastMessage!.status,
              sender: SenderEntity(
                id: g.lastMessage!.sender.id,
                name: g.lastMessage!.sender.name,
              ),
              iv: g.lastMessage!.iv,
              encryptedGroupKey: g.lastMessage!.encryptedGroupKey,
              decryptedGroupKey: g.lastMessage!.decryptedGroupKey,
            )
          : null,
      unreadCount: g.unreadCount,
      groupKey: g.groupKey,
      version: g.version,
    );
  }

  Future<void> joinConversation({
    required String conversationId,
    required bool isGroup,
  }) async {
    final userId = await _localStorage.read(key: AppKeys.userID);
    if (userId == null || userId.isEmpty) {
      SocketLogger.log('join', 'No userId found in local storage.');
      return;
    }
    final joinData = {
      'userId': userId,
      'conversationId': conversationId,
      'isgroup': isGroup,
    };
    SocketLogger.log('join_conversation', joinData);
    _socketService.socket?.emit('join_conversation', joinData);
  }

  Future<void> leaveConversation({
    required String conversationId,
    required bool isGroup,
  }) async {
    final userId = await _localStorage.read(key: AppKeys.userID);
    if (userId == null || userId.isEmpty) {
      SocketLogger.log('leave', 'No userId found in local storage.');
      return;
    }
    final joinData = {
      'userId': userId,
      'conversationId': conversationId,
      'isgroup': isGroup,
    };
    SocketLogger.log('leave', joinData);
    _socketService.socket?.emit('leave_conversation', joinData);
  }

  Future<void> emitTyping({
    required String conversationId,
    required bool isGroup,
  }) async {
    final userId = await _localStorage.read(key: AppKeys.userID);
    if (userId == null || userId.isEmpty) {
      SocketLogger.log('typing', 'No userId found in local storage.');
      return;
    }
    final typingData = {
      'userId': userId,
      'conversationId': conversationId,
      'isgroup': isGroup,
    };
    SocketLogger.log('typing', typingData);
    _socketService.socket?.emit('typing', typingData);
  }

  Future<void> stopTyping({
    required String conversationId,
    required bool isGroup,
  }) async {
    final userId = await _localStorage.read(key: AppKeys.userID);
    if (userId == null || userId.isEmpty) {
      SocketLogger.log('stop_typing', 'No userId found in local storage.');
      return;
    }
    final typingData = {
      'userId': userId,
      'conversationId': conversationId,
      'isgroup': isGroup,
    };
    SocketLogger.log('stop_typing', typingData);
    _socketService.socket?.emit('stop_typing', typingData);
  }

  void listenForNewMessages(void Function(GroupEntity) onNewMessage) {
    _socketService.socket?.off('new_message');
    _socketService.socket?.on('new_message', (data) {
      final mapData = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      SocketLogger.log('new_message', mapData);
      final groupModel = GroupModel.fromJson(mapData);
      final groupEntity = _mapGroupModelToEntity(groupModel);
      onNewMessage(groupEntity);
    });
  }

  void listenForChatMessages(void Function(MessageEntity) onNewMessage) {
    _socketService.socket?.off('group_message');
    _socketService.socket?.on('group_message', (data) {
      final mapData = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      SocketLogger.log('group_message', mapData);
      final msgModel = MessageModel.fromJson(mapData);
      final msgEntity = _mapMessageModelToEntity(msgModel);
      onNewMessage(msgEntity);
      markRead(
        conversationId: msgEntity.groupId!,
        messageId: msgEntity.id,
        type: msgEntity.type == 'group',
      );
    });
  }

  MessageEntity _mapMessageModelToEntity(MessageModel m) {
    return MessageEntity(
      id: m.id,
      conversationId: m.conversationId,
      groupId: m.groupId,
      senderId: m.senderId,
      encryptedText: m.encryptedText,
      type: m.type,
      status: m.status,
      fileUrl: m.fileUrl,
      createdAt: m.createdAt,
      avatar: m.avatar,
      senderName: m.senderName,
      isSenderYou: m.isSenderYou,
      iv: m.iv,
      encryptedGroupKey: m.encryptedGroupKey,
      decryptGroupKey: m.decryptGroupKey,
      fileSize: m.fileSize,
      fileType: m.fileType,
      fileName: m.fileName,
      filePages: m.filePages,
    );
  }

  void listenForConversationalMessages(
    void Function(MessageEntity) onNewMessage,
  ) {
    _socketService.socket?.off('conv_message');
    _socketService.socket?.on('conv_message', (data) {
      final mapData = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      SocketLogger.log('conv_message', mapData);
      final messageModel = MessageModel.fromJson(mapData);
      final messageEntity = _mapMessageModelToEntity(messageModel);
      onNewMessage(messageEntity);
      markRead(
        conversationId: messageEntity.groupId!,
        messageId: messageEntity.id,
        type: messageEntity.type == 'group',
      );
    });
  }

  Future<void> markRead({
    required String conversationId,
    required String messageId,
    required bool type,
  }) async {
    final userId = await _localStorage.read(key: AppKeys.userID);
    if (userId == null || userId.isEmpty) {
      SocketLogger.log('mark_read', 'No userId found in local storage.');
      return;
    }
    final typingData = {
      'userId': userId,
      'chatId': conversationId,
      'type': 'group',
      'messageId': messageId,
    };
    SocketLogger.log('mark_read', typingData);
    _socketService.socket?.emit('mark_read', typingData);
  }

  Future<void> addReaction({
    required String messageId,
    required String emoji,
    required String chatId,
    required bool isGroup,
  }) async {
    final userId = await _localStorage.read(key: AppKeys.userID);
    if (userId == null || userId.isEmpty) {
      SocketLogger.log('add_reaction', 'No userId found in local storage.');
      return;
    }
    final reactionData = {
      'messageId': messageId,
      'emoji': emoji,
      'userId': userId,
      'chatId': chatId,
      'isGroup': isGroup,
    };
    SocketLogger.log('add_reaction', reactionData);
    _socketService.socket?.emit('add_reaction', reactionData);
  }

  Future<void> removeReaction({
    required String messageId,
    required String chatId,
    required bool isGroup,
  }) async {
    final userId = await _localStorage.read(key: AppKeys.userID);
    if (userId == null || userId.isEmpty) {
      SocketLogger.log('remove_reaction', 'No userId found in local storage.');
      return;
    }
    final reactionData = {
      'messageId': messageId,
      'userId': userId,
      'chatId': chatId,
      'isGroup': isGroup,
    };
    SocketLogger.log('remove_reaction', reactionData);
    _socketService.socket?.emit('remove_reaction', reactionData);
  }

  void listenForReactionAdded(void Function(Map<String, dynamic>) onReactionAdded) {
    _socketService.socket?.off('reaction_added');
    _socketService.socket?.on('reaction_added', (data) {
      final mapData = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      SocketLogger.log('reaction_added', mapData);
      onReactionAdded(mapData);
    });
  }

  void listenForReactionRemoved(void Function(Map<String, dynamic>) onReactionRemoved) {
    _socketService.socket?.off('reaction_removed');
    _socketService.socket?.on('reaction_removed', (data) {
      final mapData = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      SocketLogger.log('reaction_removed', mapData);
      onReactionRemoved(mapData);
    });
  }
}
