import 'dart:async';

import 'package:chrysalis_mobile/core/socket/chat_list_helper.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/bloc/chat_detail_bloc.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/bloc/home_bloc.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/bloc/home_event.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/bloc/web_chat_event.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/bloc/web_chat_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WebChatBloc extends Bloc<WebChatEvent, WebChatState> {
  WebChatBloc({required this.chatDetailBloc, required this.homeBloc})
    : super(const WebChatState()) {
    on<SelectChatEvent>(_onSelectChat);
    on<ClearChatSelectionEvent>(_onClearChatSelection);
    on<UpdateChatEvent>(_onUpdateChat);
  }

  final ChatDetailBloc chatDetailBloc;
  final HomeBloc homeBloc;
  final ChatListHelper _chatListHelper = ChatListHelper();
  String? _currentConversationId;
  bool? _currentIsGroup;

  Future<void> _onSelectChat(
    SelectChatEvent event,
    Emitter<WebChatState> emit,
  ) async {
    try {
      // If selecting the same chat, do nothing
      if (state.selectedChat?.id == event.chatArgs.id) {
        return;
      }

      // 🚀 INSTANT UI UPDATE: Immediately show selected chat for instant feedback
      emit(
        state.copyWith(
          status: WebChatStatus.selected,
          selectedChat: event.chatArgs,
        ),
      );

      // 🚀 IMMEDIATE MESSAGE LOADING: Start loading messages right away
      chatDetailBloc.add(
        LoadChatMessagesEvent(
          type: event.chatArgs.type,
          id: event.chatArgs.id,
          decryptGroupKey: event.chatArgs.decryptGroupKey,
        ),
      );

      // 🚀 PARALLEL BACKGROUND OPERATIONS: Run socket operations in parallel
      final backgroundTasks = <Future<void>>[];

      // Handle leaving previous conversation (non-blocking)
      if (_currentConversationId != null && _currentIsGroup != null) {
        backgroundTasks.add(
          _chatListHelper
              .leaveConversation(
                conversationId: _currentConversationId!,
                isGroup: _currentIsGroup!,
              )
              .catchError((Object e) {
                // Log but don't block UI for leave failures
                debugPrint(
                  'Warning: Failed to leave previous conversation $_currentConversationId: $e',
                );
                return null;
              }),
        );
      }

      // Join new conversation (non-blocking)
      backgroundTasks.add(
        _chatListHelper
            .joinConversation(
              conversationId: event.chatArgs.id,
              isGroup: event.chatArgs.isGroup,
            )
            .catchError((Object e) {
              // Log but don't block UI for join failures
              debugPrint(
                'Warning: Failed to join conversation ${event.chatArgs.id}: $e',
              );
              return null;
            }),
      );

      // Mark messages as read (non-blocking)
      if (event.chatArgs.unReadMessage != null &&
          event.chatArgs.unReadMessage! > 0) {
        backgroundTasks.add(
          Future.microtask(() {
            homeBloc.add(
              MarkAllAsReadEvent(
                type: event.chatArgs.type,
                chatId: event.chatArgs.id,
              ),
            );
          }).catchError((Object e) {
            debugPrint('Warning: Failed to mark messages as read: $e');
            return null;
          }),
        );
      }

      // 🚀 UPDATE TRACKING IMMEDIATELY (optimistic)
      _currentConversationId = event.chatArgs.id;
      _currentIsGroup = event.chatArgs.isGroup;

      // 🚀 RUN BACKGROUND TASKS: Don't await, let them complete in background
      if (backgroundTasks.isNotEmpty) {
        unawaited(
          Future.wait(backgroundTasks)
              .then((_) {
                // All background operations completed successfully
                debugPrint(
                  '✅ Background operations completed for chat: ${event.chatArgs.id}',
                );
              })
              .catchError((Object e) {
                // Some background operations failed, but UI is already working
                debugPrint(
                  '⚠️ Some background operations failed for chat ${event.chatArgs.id}: $e',
                );
              }),
        );
      }
    } catch (e) {
      // Only emit error for critical failures that prevent chat selection
      debugPrint('❌ Critical error selecting chat: $e');
      emit(
        state.copyWith(
          status: WebChatStatus.error,
          errorMessage: 'Failed to select chat: $e',
        ),
      );
    }
  }

  Future<void> _onClearChatSelection(
    ClearChatSelectionEvent event,
    Emitter<WebChatState> emit,
  ) async {
    // Leave current conversation if any
    if (_currentConversationId != null && _currentIsGroup != null) {
      await _chatListHelper.leaveConversation(
        conversationId: _currentConversationId!,
        isGroup: _currentIsGroup!,
      );
    }

    _currentConversationId = null;
    _currentIsGroup = null;

    emit(state.clearSelection());
  }

  Future<void> _onUpdateChat(
    UpdateChatEvent event,
    Emitter<WebChatState> emit,
  ) async {
    // Update the current chat args without reloading
    if (state.selectedChat?.id == event.chatArgs.id) {
      emit(state.copyWith(selectedChat: event.chatArgs));
    }
  }

  @override
  Future<void> close() {
    // Clean up: leave current conversation if any
    if (_currentConversationId != null && _currentIsGroup != null) {
      _chatListHelper.leaveConversation(
        conversationId: _currentConversationId!,
        isGroup: _currentIsGroup!,
      );
    }
    return super.close();
  }
}
