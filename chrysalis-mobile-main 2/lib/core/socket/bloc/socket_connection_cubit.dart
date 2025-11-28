import 'dart:async';
import 'dart:developer';

import 'package:chrysalis_mobile/core/network/socket_service.dart';
import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/socket/bloc/socket_connection_state.dart';
import 'package:chrysalis_mobile/core/socket/chat_list_helper.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/bloc/chat_detail_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SocketConnectionCubit extends Cubit<SocketConnectionState> {
  SocketConnectionCubit(this._socketService, {this.onSnackbar})
    : super(SocketConnectionState.disconnected()) {
    _statusSub = _socketService.statusStream.listen((status) {
      switch (status) {
        case SocketStatus.connected:
          emit(SocketConnectionState.connected());
          log('[SocketCubit] Connected');
          _joinRoomHelper.joinUserRoom();
          joinConversation();

        case SocketStatus.disconnected:
          emit(SocketConnectionState.disconnected());
          log('[SocketCubit] Disconnected');
        case SocketStatus.error:
          emit(SocketConnectionState.error());
          log('[SocketCubit] Error');
        case SocketStatus.reconnected:
          emit(SocketConnectionState.reconnected());
          log('[SocketCubit] Reconnected');
      }
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.none)) {
        _socketService.disconnect();
        emit(SocketConnectionState.disconnected());
        onSnackbar?.call('No internet connection. Socket disconnected.');
      } else {
        // Reconnect only if a socket instance already exists and is not connected
        if (_socketService.socket != null &&
            !_socketService.socket!.connected) {
          _socketService.connect();
          emit(SocketConnectionState.reconnected());
          onSnackbar?.call('Internet restored. Reconnecting socket...');
        }
      }
    });
  }
  final SocketService _socketService;
  late final StreamSubscription<SocketStatus> _statusSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final void Function(String message)? onSnackbar;
  final ChatListHelper _joinRoomHelper = ChatListHelper();

  void connect() {
    _socketService.connect();
  }

  void disconnect() {
    _socketService.disconnect();
  }

  @override
  Future<void> close() {
    _statusSub.cancel();
    _connectivitySub?.cancel();
    _socketService.dispose();
    return super.close();
  }

  void joinConversation() {
    try {
      final navContext = navigatorKey.currentContext;

      if (navContext != null) {
        if (navContext.mounted) {
          final chatDetailBloc = navContext.read<ChatDetailBloc>();
          if (GoRouter.of(navContext).routeInformationProvider.value.uri.path ==
              AppRoutes.chatDetail) {
            _joinRoomHelper.joinConversation(
              conversationId: chatDetailBloc.state.messages.first.groupId!,
              isGroup: true,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }
}
