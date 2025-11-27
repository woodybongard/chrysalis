import 'package:chrysalis_mobile/features/chat_detail/domain/entity/chat_detail_args.dart';
import 'package:equatable/equatable.dart';

enum WebChatStatus { initial, loading, selected, error }

class WebChatState extends Equatable {
  const WebChatState({
    this.status = WebChatStatus.initial,
    this.selectedChat,
    this.errorMessage,
  });

  final WebChatStatus status;
  final ChatDetailArgs? selectedChat;
  final String? errorMessage;

  WebChatState copyWith({
    WebChatStatus? status,
    ChatDetailArgs? selectedChat,
    String? errorMessage,
  }) {
    return WebChatState(
      status: status ?? this.status,
      selectedChat: selectedChat ?? this.selectedChat,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  WebChatState clearSelection() {
    return const WebChatState();
  }

  @override
  List<Object?> get props => [status, selectedChat, errorMessage];
}