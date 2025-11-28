import 'dart:developer';
import 'dart:io';

import 'package:chrysalis_mobile/core/local_storage/chat_file_storage.dart';
import 'package:encrypt/encrypt.dart';
import 'package:chrysalis_mobile/core/socket/entities/message_status_update_entity.dart';
import 'package:chrysalis_mobile/core/socket/chat_list_helper.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/message_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/send_message_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/reaction_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/usecase/get_messages_usecase.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/usecase/send_message_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'chat_detail_event.dart';
part 'chat_detail_state.dart';

class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  ChatDetailBloc(this.getMessagesUseCase, this.sendMessageUseCase)
    : super(const ChatDetailInitial()) {
    on<LoadChatMessagesEvent>(_onLoadMessages);
    on<LoadMoreChatMessagesEvent>(_onLoadMore);
    on<PrependNewMessageEvent>(_onPrependMessage);
    on<SendMessageEvent>(_onSendMessage);
    on<SendFileMessageEvent>(_onSendFileMessage);
    on<RetrySendMessageEvent>(_onRetrySendMessage);
    on<RetrySendFileMessageEvent>(_onRetrySendFileMessage);
    on<ChatMessagesStatusUpdatedEvent>(_onMessagesStatusUpdated);
    on<UpdateMessageFilePathEvent>(_onUpdateMessageFilePath);
    on<AddReactionEvent>(_onAddReaction);
    on<RemoveReactionEvent>(_onRemoveReaction);
    on<ReactionAddedEvent>(_onReactionAdded);
    on<ReactionRemovedEvent>(_onReactionRemoved);
  }
  final GetMessagesUseCase getMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final ChatListHelper _chatListHelper = ChatListHelper();

  void _onUpdateMessageFilePath(
    UpdateMessageFilePathEvent event,
    Emitter<ChatDetailState> emit,
  ) {
    final current = state;
    if (current is! ChatDetailLoaded) return;
    final updatedMessages = current.messages.map((msg) {
      if (msg.id == event.messageId) {
        return msg.copyWith(fileUrl: event.filePath);
      }
      return msg;
    }).toList();
    final updatedList = setShowAvatarAndName(updatedMessages);
    emit(
      ChatDetailLoaded(
        messages: updatedList,
        type: current.type,
        id: current.id,
        page: current.page,
        limit: current.limit,
        totalPages: current.totalPages,
        total: current.total,
      ),
    );
  }

  Future<void> _onSendFileMessage(
    SendFileMessageEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    if (state is! ChatDetailLoaded) return;
    final current = state as ChatDetailLoaded;
    final now = DateTime.now();
    final tempId = 'file-temp-[1m${now.millisecondsSinceEpoch}[0m';

    // 1. Save file locally using ChatFileStorage
    var savedFilePath = event.filePath;
    try {
      final savedPath = await ChatFileStorage().saveFile(
        groupId: event.isGroup ? event.groupId : null,
        conversationId: tempId,
        file: File(event.filePath),
        isSent: true,
      );
      savedFilePath = savedPath;
    } catch (e) {
      // fallback to original path if saving fails
    }

    final tempMessage = MessageEntity(
      id: tempId,
      conversationId: current.id == 'conversation' ? current.id : null,
      groupId: current.type == 'group' ? current.id : null,
      senderId: event.currentUserId,
      encryptedText: '',
      type: 'FILE',
      status: 'SENDING',
      fileUrl: savedFilePath,
      createdAt: now.toUtc().toIso8601String(),
      avatar: '',
      senderName: '',
      isSenderYou: true,
      iv: '',
      encryptedGroupKey: event.encryptedGroupKey,
      decryptGroupKey: _cachedGroupKey,
      fileSize: event.fileSize,
      fileType: event.fileType,
      filePages: event.filePages.toString(),
      fileName: event.fileName,
    );

    // 3. Insert temp at index 0
    final optimisticMessages = [tempMessage, ...current.messages];
    final updatedList = setShowAvatarAndName(optimisticMessages);
    emit(
      ChatDetailLoaded(
        messages: updatedList,
        type: current.type,
        id: current.id,
        page: current.page,
        limit: current.limit,
        totalPages: current.totalPages,
        total: current.total + 1,
      ),
    );

    final sent = await sendMessageUseCase(
      entity: GroupMessageEntity(
        isGroup: event.isGroup,
        groupId: event.groupId,
        content: event.content,
        iv: event.iv,
        encryptedGroupKey: event.encryptedGroupKey,
        version: event.version,
        fileName: event.fileName,
        fileSize: event.fileSize,
        fileType: event.fileType,
        filePages: event.filePages,
        filePath: savedFilePath,
        type: 'FILE',
      ),
    );

    // 5. Replace temp with real (simulate success)
    final latest = state;
    if (latest is! ChatDetailLoaded) return;
    await ChatFileStorage().updateConversationId(tempId, sent.id);
    final updatedMessages = latest.messages.map((m) {
      if (m.id == tempId) {
        return m.copyWith(
          status: 'SENT',
          fileUrl: savedFilePath,
          id: sent.id,
          createdAt: sent.createdAt,
        );
      }
      return m;
    }).toList();
    final updatedList2 = setShowAvatarAndName(updatedMessages);
    emit(
      ChatDetailLoaded(
        messages: updatedList2,
        type: latest.type,
        id: latest.id,
        page: latest.page,
        limit: latest.limit,
        totalPages: latest.totalPages,
        total: latest.total,
      ),
    );
  }

  void _onMessagesStatusUpdated(
    ChatMessagesStatusUpdatedEvent event,
    Emitter<ChatDetailState> emit,
  ) {
    final current = state;
    if (current is! ChatDetailLoaded) return;
    if (current.id != event.update.chatId) return;
    // Update status in flat messages list
    final updatedMessages = current.messages.map((msg) {
      final found = event.update.messages.where((m) => m.id == msg.id);
      if (found.isNotEmpty) {
        return msg.copyWith(status: found.first.status);
      }
      return msg;
    }).toList();
    final updatedList = setShowAvatarAndName(updatedMessages);
    emit(
      ChatDetailLoaded(
        messages: updatedList,
        type: current.type,
        id: current.id,
        page: current.page,
        limit: current.limit,
        totalPages: current.totalPages,
        total: current.total,
      ),
    );
  }

  Key? _cachedGroupKey;

  List<MessageEntity> _attachGroupKeyToMessages(
    List<MessageEntity> messages,
    Key cachedKey,
  ) {
    return messages
        .map((message) => message.copyWith(decryptGroupKey: cachedKey))
        .toList();
  }

  Future<void> _onLoadMessages(
    LoadChatMessagesEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    emit(const ChatDetailLoading());
    _cachedGroupKey = event.decryptGroupKey;

    try {
      final data = await getMessagesUseCase(
        type: event.type,
        id: event.id,
        page: event.page,
        limit: event.limit,
      );

      final processedMessages = _cachedGroupKey != null
          ? _attachGroupKeyToMessages(data.messages, _cachedGroupKey!)
          : data.messages;

      final updatedList = setShowAvatarAndName(processedMessages);
      emit(
        ChatDetailLoaded(
          type: event.type,
          id: event.id,
          page: event.page,
          limit: event.limit,
          total: data.pagination.total,
          totalPages: data.pagination.totalPages,
          messages: updatedList,
        ),
      );
    } catch (e, s) {
      log('Error loading messages $e' , stackTrace: s);
      // Fallback to empty loaded state to avoid error UI when offline
      emit(
        ChatDetailLoaded(
          type: event.type,
          id: event.id,
          page: event.page,
          limit: event.limit,
          total: 0,
          totalPages: 1,
          messages: const [],
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    LoadMoreChatMessagesEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    final current = state;
    if (current is! ChatDetailLoaded) return;

    // Already at last page
    if (current.page >= current.totalPages) return;

    final nextPage = current.page + 1;

    emit(
      ChatDetailLoadingMore(
        messages: current.messages,
        type: current.type,
        id: current.id,
        page: current.page,
        limit: current.limit,
        totalPages: current.totalPages,
        total: current.total,
      ),
    );

    try {
      final data = await getMessagesUseCase(
        type: current.type,
        id: current.id,
        page: nextPage,
        limit: current.limit,
      );

      final newMessages = _cachedGroupKey != null
          ? _attachGroupKeyToMessages(data.messages, _cachedGroupKey!)
          : data.messages;

      // Merge old + new
      final updatedMessages = [...current.messages, ...newMessages];

      final updatedList = setShowAvatarAndName(updatedMessages);
      emit(
        ChatDetailLoaded(
          messages: updatedList,
          type: current.type,
          id: current.id,
          page: nextPage, // incremented
          limit: current.limit,
          totalPages: data.pagination.totalPages,
          total: data.pagination.total,
        ),
      );
    } catch (e) {
      emit(ChatDetailError(e.toString()));
    }
  }

  Future<void> _onPrependMessage(
    PrependNewMessageEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    final current = state;

    final updatedMessage = _cachedGroupKey != null
        ? event.chatMessages.copyWith(decryptGroupKey: _cachedGroupKey)
        : event.chatMessages;

    // now prepend the updatedMessage instead of the old event.chatMessages
    final newMessages = [updatedMessage, ...current.messages];
    log('🔄 Prepending new message: ${event.chatMessages.id}');
    final updatedList = setShowAvatarAndName(newMessages);

    switch (current) {
      case ChatDetailLoaded():
        emit(
          ChatDetailLoaded(
            messages: updatedList,
            type: current.type,
            id: current.id,
            page: current.page,
            limit: current.limit,
            totalPages: current.totalPages,
            total: current.total + 1,
          ),
        );

      case ChatDetailLoadingMore():
        emit(
          ChatDetailLoadingMore(
            messages: updatedList,
            type: current.type,
            id: current.id,
            page: current.page,
            limit: current.limit,
            totalPages: current.totalPages,
            total: current.total + 1,
          ),
        );

      case ChatDetailError():
        // keep error, but still allow messages to update
        emit(ChatDetailError(current.message, messages: updatedList));

      case ChatDetailLoading():
        // still loading, but prepend to messages
        emit(ChatDetailLoading(messages: updatedList));

      case ChatDetailInitial():
        // first time — just build a loaded state with one message
        emit(
          ChatDetailLoaded(
            messages: updatedList,
            type: event.chatMessages.type, // need to pass from event
            id: event.chatMessages.id, // need to pass from event
            page: 1,
            limit: 20,
            totalPages: 1,
            total: 1,
          ),
        );
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    if (state is! ChatDetailLoaded) return;
    final current = state as ChatDetailLoaded;
    final now = DateTime.now();
    final tempId = 'temp-${now.millisecondsSinceEpoch}';

    final tempMessage = MessageEntity(
      id: tempId,
      conversationId: current.id == 'conversation' ? current.id : null,
      groupId: current.type == 'group' ? current.id : null,
      senderId: event.currentUserId,
      encryptedText: event.content,
      type: 'TEXT',
      status: 'SENDING',
      createdAt: now.toUtc().toIso8601String(),
      avatar: '',
      senderName: '',
      isSenderYou: true,
      iv: event.iv,
      encryptedGroupKey: event.encryptedGroupKey,
      decryptGroupKey: _cachedGroupKey,
    );

    // 2. Insert temp at index 0
    final optimisticMessages = [tempMessage, ...current.messages];

    final updatedList = setShowAvatarAndName(optimisticMessages);
    emit(
      ChatDetailLoaded(
        messages: updatedList,
        type: current.type,
        id: current.id,
        page: current.page,
        limit: current.limit,
        totalPages: current.totalPages,
        total: current.total + 1,
      ),
    );

    // 3. Call API
    try {
      final sent = await sendMessageUseCase(
        entity: GroupMessageEntity(
          isGroup: event.isGroup,
          groupId: event.id,
          content: event.content,
          iv: event.iv,
          encryptedGroupKey: event.encryptedGroupKey,
          version: event.version,
        ),
      );

      // 4. Replace temp with real
      final latest = state;
      if (latest is! ChatDetailLoaded) return;

      final updatedMessages = latest.messages.map((m) {
        if (m.id == tempId) {
          return sent.copyWith(decryptGroupKey: _cachedGroupKey);
        }
        return m;
      }).toList();

      final updatedList = setShowAvatarAndName(updatedMessages);
      emit(
        ChatDetailLoaded(
          messages: updatedList,
          type: latest.type,
          id: latest.id,
          page: latest.page,
          limit: latest.limit,
          totalPages: latest.totalPages,
          total: latest.total, // total already increased
        ),
      );
    } catch (e) {
      // 5. Mark temp as FAILED
      final latest = state;
      if (latest is! ChatDetailLoaded) return;

      final updatedMessages = latest.messages.map((m) {
        if (m.id == tempId) {
          return m.copyWith(status: 'FAILED');
        }
        return m;
      }).toList();
      final updatedList = setShowAvatarAndName(updatedMessages);
      emit(
        ChatDetailLoaded(
          messages: updatedList,
          type: latest.type,
          id: latest.id,
          page: latest.page,
          limit: latest.limit,
          totalPages: latest.totalPages,
          total: latest.total,
        ),
      );
    }
  }

  Future<void> _onRetrySendMessage(
    RetrySendMessageEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    if (state is! ChatDetailLoaded) return;
    final current = state as ChatDetailLoaded;

    // 1. Mark the failed message as SENDING
    final retryMessage = event.message.copyWith(status: 'SENDING');

    final optimisticMessages = current.messages.map((m) {
      if (m.id == event.message.id) return retryMessage;
      return m;
    }).toList();
    final updatedList = setShowAvatarAndName(optimisticMessages);
    emit(
      ChatDetailLoaded(
        messages: updatedList,
        type: current.type,
        id: current.id,
        page: current.page,
        limit: current.limit,
        totalPages: current.totalPages,
        total: current.total,
      ),
    );

    try {
      var sent = await sendMessageUseCase(
        entity: GroupMessageEntity(
          isGroup: current.type == 'group',
          groupId: current.id,
          content: retryMessage.encryptedText,
          iv: event.message.iv,
          encryptedGroupKey: event.message.encryptedGroupKey,
          version: event.version,
        ),
      );
      final latest = state;
      if (latest is! ChatDetailLoaded) return;
      final sentWithKey = sent.copyWith(decryptGroupKey: _cachedGroupKey);
      final updatedMessages = latest.messages.map((m) {
        if (m.id == retryMessage.id) return sentWithKey;
        return m;
      }).toList();
      final updatedList = setShowAvatarAndName(updatedMessages);
      emit(
        ChatDetailLoaded(
          messages: updatedList,
          type: latest.type,
          id: latest.id,
          page: latest.page,
          limit: latest.limit,
          totalPages: latest.totalPages,
          total: latest.total,
        ),
      );
    } catch (e) {
      // 4. Mark as FAILED again
      final latest = state;
      if (latest is! ChatDetailLoaded) return;

      final failedMsg = retryMessage.copyWith(status: 'FAILED');
      final failedMessages = latest.messages.map((m) {
        if (m.id == retryMessage.id) return failedMsg;
        return m;
      }).toList();
      final updatedList = setShowAvatarAndName(failedMessages);
      emit(
        ChatDetailLoaded(
          messages: updatedList,
          type: latest.type,
          id: latest.id,
          page: latest.page,
          limit: latest.limit,
          totalPages: latest.totalPages,
          total: latest.total,
        ),
      );
    }
  }

  Future<void> _onRetrySendFileMessage(
    RetrySendFileMessageEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    if (state is! ChatDetailLoaded) return;
    final current = state as ChatDetailLoaded;

    // 1. Mark the failed message as SENDING
    final retryMessage = event.message.copyWith(status: 'SENDING');

    final optimisticMessages = current.messages.map((m) {
      if (m.id == event.message.id) return retryMessage;
      return m;
    }).toList();
    final updatedList = setShowAvatarAndName(optimisticMessages);
    emit(
      ChatDetailLoaded(
        messages: updatedList,
        type: current.type,
        id: current.id,
        page: current.page,
        limit: current.limit,
        totalPages: current.totalPages,
        total: current.total,
      ),
    );

    try {
      var sent = await sendMessageUseCase(
        entity: GroupMessageEntity(
          isGroup: current.type == 'group',
          groupId: current.id,
          content:
              retryMessage.encryptedText, // Or appropriate content for file
          iv: event.message.iv,
          encryptedGroupKey: event.message.encryptedGroupKey,
          version: event.version,
          fileName: event.message.fileName,
          fileSize: event.message.fileSize,
          fileType: event.message.fileType,
          filePages: int.tryParse(event.message.filePages ?? ''),
          filePath: event.message.fileUrl, // Assuming fileUrl is the local path
          type: 'FILE',
        ),
      );

      final latest = state;
      if (latest is! ChatDetailLoaded) return;
      final sentWithKey = sent.copyWith(decryptGroupKey: _cachedGroupKey);
      final updatedMessages = latest.messages.map((m) {
        if (m.id == retryMessage.id) return sentWithKey;
        return m;
      }).toList();
      final updatedListWithSent = setShowAvatarAndName(updatedMessages);
      emit(
        ChatDetailLoaded(
          messages: updatedListWithSent,
          type: latest.type,
          id: latest.id,
          page: latest.page,
          limit: latest.limit,
          totalPages: latest.totalPages,
          total: latest.total,
        ),
      );
    } catch (e) {
      // 4. Mark as FAILED again
      final latest = state;
      if (latest is! ChatDetailLoaded) return;

      final failedMsg = retryMessage.copyWith(status: 'FAILED');
      final failedMessages = latest.messages
          .map((m) => m.id == retryMessage.id ? failedMsg : m)
          .toList();
      final updatedListWithFailed = setShowAvatarAndName(failedMessages);
      emit(
        ChatDetailLoaded(
          messages: updatedListWithFailed,
          type: latest.type,
          id: latest.id,
          page: latest.page,
          limit: latest.limit,
          totalPages: latest.totalPages,
          total: latest.total,
        ),
      );
    }
  }

  Future<void> _onAddReaction(
    AddReactionEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    await _chatListHelper.addReaction(
      messageId: event.messageId,
      emoji: event.emoji,
      chatId: event.chatId,
      isGroup: event.isGroup,
    );
  }

  Future<void> _onRemoveReaction(
    RemoveReactionEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    await _chatListHelper.removeReaction(
      messageId: event.messageId,
      chatId: event.chatId,
      isGroup: event.isGroup,
    );
  }

  void _onReactionAdded(
    ReactionAddedEvent event,
    Emitter<ChatDetailState> emit,
  ) {
    final current = state;
    if (current is! ChatDetailLoaded) return;

    final reactionData = event.reaction['reaction'] as Map<String, dynamic>;
    final reaction = ReactionEntity(
      id: reactionData['id'] as String,
      emoji: reactionData['emoji'] as String,
      userId: reactionData['userId'] as String,
      createdAt: reactionData['createdAt'] as String,
    );

    final updatedMessages = current.messages.map((msg) {
      if (msg.id == event.messageId) {
        final updatedReactions = [...msg.reactions, reaction];
        return msg.copyWith(reactions: updatedReactions);
      }
      return msg;
    }).toList();

    final updatedList = setShowAvatarAndName(updatedMessages);
    emit(
      ChatDetailLoaded(
        messages: updatedList,
        type: current.type,
        id: current.id,
        page: current.page,
        limit: current.limit,
        totalPages: current.totalPages,
        total: current.total,
      ),
    );
  }

  void _onReactionRemoved(
    ReactionRemovedEvent event,
    Emitter<ChatDetailState> emit,
  ) {
    final current = state;
    if (current is! ChatDetailLoaded) return;

    final updatedMessages = current.messages.map((msg) {
      if (msg.id == event.messageId) {
        final updatedReactions = msg.reactions
            .where((r) => r.userId != event.userId)
            .toList();
        return msg.copyWith(reactions: updatedReactions);
      }
      return msg;
    }).toList();

    final updatedList = setShowAvatarAndName(updatedMessages);
    emit(
      ChatDetailLoaded(
        messages: updatedList,
        type: current.type,
        id: current.id,
        page: current.page,
        limit: current.limit,
        totalPages: current.totalPages,
        total: current.total,
      ),
    );
  }

  List<MessageEntity> setShowAvatarAndName(List<MessageEntity> messages) {
    final reversed = messages.toList();
    for (var i = 0; i < reversed.length; i++) {
      final prev = i > 0 ? reversed[i - 1] : null;
      final next = i < reversed.length - 1 ? reversed[i + 1] : null;
      final isFirst = i == 0;
      final isLast = i == reversed.length - 1;

      final current = reversed[i];

      final showAvatar = isFirst || (prev?.senderId != current.senderId);
      final showName = isLast || (next?.senderId != current.senderId);

      reversed[i] = current.copyWith(
        showAvatarImage: showAvatar,
        showSenderName: showName,
      );
    }
    return reversed.toList();
  }
}
