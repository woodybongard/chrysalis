part of 'chat_detail_bloc.dart';

abstract class ChatDetailState extends Equatable {
  const ChatDetailState({this.messages = const []});
  final List<MessageEntity> messages;

  @override
  List<Object?> get props => [messages];
}

class ChatDetailInitial extends ChatDetailState {
  const ChatDetailInitial({super.messages = const []});
}

class ChatDetailLoading extends ChatDetailState {
  const ChatDetailLoading({super.messages = const []});
}

class ChatDetailError extends ChatDetailState {
  const ChatDetailError(this.message, {super.messages = const []});
  final String message;

  @override
  List<Object?> get props => [message, messages];
}

class ChatDetailLoaded extends ChatDetailState {
  const ChatDetailLoaded({
    required super.messages,
    required this.type,
    required this.id,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.total,
  });
  final String type;
  final String id;
  final int page;
  final int limit;
  final int totalPages;
  final int total;

  @override
  List<Object?> get props => [
    messages,
    type,
    id,
    page,
    limit,
    totalPages,
    total,
  ];
}

class ChatDetailLoadingMore extends ChatDetailState {
  const ChatDetailLoadingMore({
    required super.messages,
    required this.type,
    required this.id,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.total,
  });
  final String type;
  final String id;
  final int page;
  final int limit;
  final int totalPages;
  final int total;

  @override
  List<Object?> get props => [
    messages,
    type,
    id,
    page,
    limit,
    totalPages,
    total,
  ];
}
