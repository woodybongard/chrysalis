import 'package:chrysalis_mobile/features/homepage/presentation/bloc/home_event.dart';

abstract class HomeTypingEvent extends HomeEvent {
  const HomeTypingEvent();
}

class UserTypingListEvent extends HomeTypingEvent {
  const UserTypingListEvent({required this.conversationId, required this.name});
  final String conversationId;
  final String name;

  @override
  List<Object?> get props => [conversationId, name];
}

class UserStopTypingListEvent extends HomeTypingEvent {
  const UserStopTypingListEvent({required this.conversationId});
  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}
