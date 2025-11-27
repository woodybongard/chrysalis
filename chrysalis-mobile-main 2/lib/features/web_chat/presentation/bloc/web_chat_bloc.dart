import 'dart:async';

import 'package:chrysalis_mobile/core/socket/chat_list_helper.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/bloc/chat_detail_bloc.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/bloc/home_bloc.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/bloc/home_event.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/bloc/web_chat_event.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/bloc/web_chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WebChatBloc extends Bloc<WebChatEvent, WebChatState> {
  WebChatBloc({
    required this.chatDetailBloc,
    required this.homeBloc,
  }) : super(const WebChatState()) {
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

      emit(state.copyWith(status: WebChatStatus.loading));

      // Leave previous conversation if any
      if (_currentConversationId != null && _currentIsGroup != null) {
        await _chatListHelper.leaveConversation(
          conversationId: _currentConversationId!,
          isGroup: _currentIsGroup!,
        );
      }

      // Join new conversation
      await _chatListHelper.joinConversation(
        conversationId: event.chatArgs.id,
        isGroup: event.chatArgs.isGroup,
      );

      // Update current conversation tracking
      _currentConversationId = event.chatArgs.id;
      _currentIsGroup = event.chatArgs.isGroup;

      // Mark messages as read if needed
      if (event.chatArgs.unReadMessage != null && 
          event.chatArgs.unReadMessage! > 0) {
        homeBloc.add(
          MarkAllAsReadEvent(
            type: event.chatArgs.type,
            chatId: event.chatArgs.id,
          ),
        );
      }

      // Clear previous chat messages and load new ones
      chatDetailBloc.add(
        LoadChatMessagesEvent(
          type: event.chatArgs.type,
          id: event.chatArgs.id,
        ),
      );

      emit(state.copyWith(
        status: WebChatStatus.selected,
        selectedChat: event.chatArgs,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: WebChatStatus.error,
        errorMessage: 'Failed to load chat: $e',
      ));
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
      emit(state.copyWith(
        selectedChat: event.chatArgs,
      ));
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