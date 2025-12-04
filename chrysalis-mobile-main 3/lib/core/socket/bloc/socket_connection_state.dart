import 'package:flutter/foundation.dart';

@immutable
class SocketConnectionState {
  const SocketConnectionState._(this.status);

  factory SocketConnectionState.connected() =>
      const SocketConnectionState._(SocketConnectionStatus.connected);
  factory SocketConnectionState.disconnected() =>
      const SocketConnectionState._(SocketConnectionStatus.disconnected);
  factory SocketConnectionState.error() =>
      const SocketConnectionState._(SocketConnectionStatus.error);
  factory SocketConnectionState.reconnected() =>
      const SocketConnectionState._(SocketConnectionStatus.reconnected);
  final SocketConnectionStatus status;

  @override
  String toString() => 'SocketConnectionState(status: $status)';
}

enum SocketConnectionStatus { connected, disconnected, error, reconnected }
