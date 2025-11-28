import 'package:chrysalis_mobile/features/chat_detail/domain/entity/chat_detail_args.dart';
import 'package:equatable/equatable.dart';

abstract class WebChatEvent extends Equatable {
  const WebChatEvent();

  @override
  List<Object?> get props => [];
}

class SelectChatEvent extends WebChatEvent {
  const SelectChatEvent(this.chatArgs);

  final ChatDetailArgs chatArgs;

  @override
  List<Object?> get props => [chatArgs];
}

class ClearChatSelectionEvent extends WebChatEvent {
  const ClearChatSelectionEvent();
}

class UpdateChatEvent extends WebChatEvent {
  const UpdateChatEvent(this.chatArgs);

  final ChatDetailArgs chatArgs;

  @override
  List<Object?> get props => [chatArgs];
}