import 'dart:async';
import 'dart:developer';

import 'package:chrysalis_mobile/core/endpoints/api_endpoints.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  factory SocketService() => _instance;
  SocketService._internal();
  static final SocketService _instance = SocketService._internal();

  io.Socket? _socket;
  final _statusController = StreamController<SocketStatus>.broadcast();

  Stream<SocketStatus> get statusStream => _statusController.stream;
  io.Socket? get socket => _socket;

  void connect() {
    if (_socket != null && _socket!.connected) {
      log('[SocketService] Already connected');
      return;
    }
    log('[SocketService] Connecting to socket...');
    _socket = io.io(
      ApiEndpoints.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket!.on('connect', (_) {
      log('[SocketService] Socket connected');
      _statusController.add(SocketStatus.connected);
    });
    _socket!.on('disconnect', (_) {
      log('[SocketService] Socket disconnected');
      _statusController.add(SocketStatus.disconnected);
    });
    _socket!.on('connect_error', (data) {
      log('[SocketService] Connection error: $data');
      _statusController.add(SocketStatus.error);
    });
    _socket!.on('reconnect', (_) {
      log('[SocketService] Socket reconnected');
      _statusController.add(SocketStatus.reconnected);
    });

    _socket!.connect();
  }

  void disconnect() {
    if (_socket != null) {
      log('[SocketService] Disconnecting socket...');
      _socket!.disconnect();
      _socket!.destroy();
      _socket = null;
      _statusController.add(SocketStatus.disconnected);
    }
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }
}

enum SocketStatus { connected, disconnected, error, reconnected }
