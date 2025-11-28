// HomeBloc for homepage feature
// This file will contain the Bloc implementation for the homepage

import 'package:chrysalis_mobile/core/crypto_services/crypto_service.dart';
import 'package:chrysalis_mobile/core/di/service_locator.dart';
import 'package:chrysalis_mobile/features/homepage/domain/entity/home_entity.dart';
import 'package:chrysalis_mobile/features/homepage/domain/usecase/get_home_data_usecase.dart';
import 'package:chrysalis_mobile/features/homepage/domain/usecase/read_all_mark_usecase.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/bloc/home_event.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this.getHomeDataUseCase) : super(HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeDataEvent);
    on<NewMessageReceivedEvent>(_onNewMessageReceivedEvent);
    on<MarkAllAsReadEvent>(_onMarkAllAsReadEvent);
    on<UserTypingListEvent>(_onUserTypingListEvent);
    on<UserStopTypingListEvent>(_onUserStopTypingListEvent);
    on<UpdateChatLastMessageStatusEvent>(_onUpdateChatLastMessageStatusEvent);
  }

  final GetHomeDataUseCase getHomeDataUseCase;

  Future<void> _onUpdateChatLastMessageStatusEvent(
    UpdateChatLastMessageStatusEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final updatedGroups = List<GroupEntity>.from(currentState.data.data);
      final index = updatedGroups.indexWhere((g) => g.groupId == event.chatId);
      if (index != -1) {
        final group = updatedGroups[index];

        final crypto = CryptoService();

        if (group.lastMessage != null &&
            group.lastMessage!.id == event.lastMessageId) {
          final decryptedGroupKey = await crypto.decryptGroupSenderKey(
            group.lastMessage!.encryptedGroupKey,
          );
          final updatedLastMessage = LastMessageEntity(
            id: group.lastMessage!.id,
            type: group.lastMessage!.type,
            content: group.lastMessage!.content,
            createdAt: group.lastMessage!.createdAt,
            isSenderYou: group.lastMessage!.isSenderYou,
            status: event.lastMessageStatus,
            sender: group.lastMessage!.sender,
            iv: group.lastMessage!.iv,
            encryptedGroupKey: group.lastMessage!.encryptedGroupKey,
            decryptedGroupKey: decryptedGroupKey,
          );
          updatedGroups[index] = GroupEntity(
            type: group.type,
            groupId: group.groupId,
            name: group.name,
            avatar: group.avatar,
            isGroup: group.isGroup,
            lastMessage: updatedLastMessage,
            unreadCount: group.unreadCount,
            typingText: group.typingText,
            version: group.version,
            groupKey: group.groupKey,
          );
          emit(
            HomeLoaded(
              HomeEntity(
                data: updatedGroups,
                pagination: currentState.data.pagination,
              ),
            ),
          );
        }
      }
    }
  }

  void _onUserTypingListEvent(
    UserTypingListEvent event,
    Emitter<HomeState> emit,
  ) {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final updatedGroups = List<GroupEntity>.from(currentState.data.data);
      final index = updatedGroups.indexWhere(
        (g) => g.groupId == event.conversationId,
      );
      if (index != -1) {
        final group = updatedGroups[index];
        updatedGroups[index] = GroupEntity(
          type: group.type,
          groupId: group.groupId,
          name: group.name,
          avatar: group.avatar,
          isGroup: group.isGroup,
          lastMessage: group.lastMessage,
          unreadCount: group.unreadCount,
          typingText: '${event.name} is typing...',
          version: group.version,
          groupKey: group.groupKey,
        );
        emit(
          HomeLoaded(
            HomeEntity(
              data: updatedGroups,
              pagination: currentState.data.pagination,
            ),
          ),
        );
      }
    }
  }

  void _onUserStopTypingListEvent(
    UserStopTypingListEvent event,
    Emitter<HomeState> emit,
  ) {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final updatedGroups = List<GroupEntity>.from(currentState.data.data);
      final index = updatedGroups.indexWhere(
        (g) => g.groupId == event.conversationId,
      );
      if (index != -1) {
        final group = updatedGroups[index];
        updatedGroups[index] = GroupEntity(
          type: group.type,
          groupId: group.groupId,
          name: group.name,
          avatar: group.avatar,
          isGroup: group.isGroup,
          lastMessage: group.lastMessage,
          unreadCount: group.unreadCount,
          version: group.version,
          groupKey: group.groupKey,
        );
        emit(
          HomeLoaded(
            HomeEntity(
              data: updatedGroups,
              pagination: currentState.data.pagination,
            ),
          ),
        );
      }
    }
  }

  Future<void> _onLoadHomeDataEvent(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    final nextPage = event.page;
    final limit = event.limit;
    var accumulatedGroups = <GroupEntity>[];
    PaginationEntity? lastPagination;

    final isFirstPage = nextPage == 1;

    if (currentState is HomeLoaded && nextPage > 1) {
      accumulatedGroups = List.from(currentState.data.data);
      lastPagination = currentState.data.pagination;
      // Don't fetch if already at last page
      if (lastPagination.page >= lastPagination.totalPages) return;
    }

    if (isFirstPage) {
      emit(HomeLoading());
    } else {
      emit(
        currentState is HomeLoaded
            ? HomeLoadingMore(currentState.data)
            : HomeLoading(),
      );
    }

    try {
      var data = await getHomeDataUseCase(page: nextPage, limit: limit);

      await _decryptAndUpdateMessages(data).then((decryptedMessages) {
        data = decryptedMessages;
      });

      if (accumulatedGroups.isNotEmpty) {
        accumulatedGroups.addAll(data.data);

        emit(
          HomeLoaded(
            HomeEntity(data: accumulatedGroups, pagination: data.pagination),
          ),
        );
      } else {
        emit(HomeLoaded(data));
      }
    } catch (e) {
      emit(HomeError(e.toString() ?? 'An unknown error occurred'));
    }
  }

  Future<void> _onNewMessageReceivedEvent(
    NewMessageReceivedEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final updatedGroups = List<GroupEntity>.from(currentState.data.data);
      final index = updatedGroups.indexWhere(
        (g) => g.groupId == event.groupEntity.groupId,
      );
      final crypto = CryptoService();
      final decryptedGroupKey = await crypto.decryptGroupSenderKey(
        event.groupEntity.lastMessage!.encryptedGroupKey,
      );

      if (index != -1) {
        // Remove and insert at top
        final updated = event.groupEntity.copyWith(
          decryptGroupKey: decryptedGroupKey,
        );

        updatedGroups
          ..removeAt(index)
          ..insert(0, updated);
      } else {
        final updated = event.groupEntity.copyWith(
          decryptGroupKey: decryptedGroupKey,
        );
        // Add new group at top
        updatedGroups.insert(0, updated);
      }
      emit(
        HomeLoaded(
          HomeEntity(
            data: updatedGroups,
            pagination: currentState.data.pagination,
          ),
        ),
      );
    }
  }

  Future<void> _onMarkAllAsReadEvent(
    MarkAllAsReadEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await sl<MarkAllAsReadUseCase>()(type: event.type, chatId: event.chatId);
      add(const LoadHomeDataEvent());
    } catch (e) {
      // emit(HomeError(e.toString()));
    }
  }

  Future<HomeEntity> _decryptAndUpdateMessages(HomeEntity messages) async {
    final crypto = CryptoService();

    final updatedGroups = <GroupEntity>[];
    for (final group in messages.data) {
      if (group.lastMessage?.encryptedGroupKey != null) {
        final decryptedGroupKey = await crypto.decryptGroupSenderKey(
          group.groupKey ?? group.lastMessage!.encryptedGroupKey,
        );

        updatedGroups.add(group.copyWith(decryptGroupKey: decryptedGroupKey));
      } else {
        updatedGroups.add(group);
      }
    }

    return messages.copyWith(data: updatedGroups);
  }
}
