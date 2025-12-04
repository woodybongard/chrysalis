import 'package:chrysalis_mobile/features/homepage/domain/entity/home_entity.dart';
import 'package:equatable/equatable.dart';

class UpdateChatLastMessageStatusEvent extends HomeEvent {
  const UpdateChatLastMessageStatusEvent({
    required this.chatId,
    required this.lastMessageId,
    required this.lastMessageStatus,
  });
  final String chatId;
  final String lastMessageId;
  final String lastMessageStatus;

  @override
  List<Object?> get props => [chatId, lastMessageId, lastMessageStatus];
}

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeDataEvent extends HomeEvent {
  const LoadHomeDataEvent({this.page = 1, this.limit = 13});
  final int page;
  final int limit;

  @override
  List<Object?> get props => [page, limit];
}

class NewMessageReceivedEvent extends HomeEvent {
  const NewMessageReceivedEvent(this.groupEntity);
  final GroupEntity groupEntity;

  @override
  List<Object?> get props => [groupEntity];
}

class MarkAllAsReadEvent extends HomeEvent {
  const MarkAllAsReadEvent({required this.type, required this.chatId});
  final String type;
  final String chatId;

  @override
  List<Object?> get props => [type, chatId];
}

class UserTypingListEvent extends HomeEvent {
  const UserTypingListEvent({required this.conversationId, required this.name});
  final String conversationId;
  final String name;

  @override
  List<Object?> get props => [conversationId, name];
}

class UserStopTypingListEvent extends HomeEvent {
  const UserStopTypingListEvent({required this.conversationId});
  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}
