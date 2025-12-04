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
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  DateTime? _lastPongTime;

  /// Heartbeat interval - send ping every 30 seconds
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  /// If no pong received within this duration, consider connection dead
  static const Duration _pongTimeout = Duration(seconds: 45);

  /// Reconnection delay when connection is lost
  static const Duration _reconnectDelay = Duration(seconds: 3);

  Stream<SocketStatus> get statusStream => _statusController.stream;
  io.Socket? get socket => _socket;
  bool get isConnected => _socket != null && _socket!.connected;

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
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(3000)
          .setReconnectionDelayMax(10000)
          .build(),
    );

    _socket!.on('connect', (_) {
      log('[SocketService] Socket connected');
      _lastPongTime = DateTime.now();
      _statusController.add(SocketStatus.connected);
      _startHeartbeat();
      _cancelReconnectTimer();
    });

    _socket!.on('disconnect', (reason) {
      log('[SocketService] Socket disconnected: $reason');
      _stopHeartbeat();
      _statusController.add(SocketStatus.disconnected);
      // Schedule reconnection attempt
      _scheduleReconnect();
    });

    _socket!.on('connect_error', (data) {
      log('[SocketService] Connection error: $data');
      _statusController.add(SocketStatus.error);
      _scheduleReconnect();
    });

    _socket!.on('reconnect', (_) {
      log('[SocketService] Socket reconnected');
      _lastPongTime = DateTime.now();
      _statusController.add(SocketStatus.reconnected);
      _startHeartbeat();
      _cancelReconnectTimer();
    });

    _socket!.on('reconnect_attempt', (attemptNumber) {
      log('[SocketService] Reconnection attempt #$attemptNumber');
    });

    _socket!.on('reconnect_error', (error) {
      log('[SocketService] Reconnection error: $error');
    });

    _socket!.on('reconnect_failed', (_) {
      log('[SocketService] Reconnection failed after all attempts');
      _statusController.add(SocketStatus.error);
    });

    // Listen for pong responses from server (application-level)
    _socket!.on('pong', (_) {
      log('[SocketService] Pong received (app-level)');
      _lastPongTime = DateTime.now();
    });

    // Also listen for any server activity as proof of connection
    // This helps when server doesn't implement custom ping/pong
    _socket!.onAny((event, data) {
      // Update last activity time on any event from server
      _lastPongTime = DateTime.now();
    });

    _socket!.connect();
  }

  /// Start the heartbeat timer to keep connection alive
  void _startHeartbeat() {
    _stopHeartbeat(); // Cancel any existing timer
    log('[SocketService] Starting heartbeat timer');

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_socket == null || !_socket!.connected) {
        log('[SocketService] Socket not connected, stopping heartbeat');
        _stopHeartbeat();
        return;
      }

      // Check if we received a pong recently
      if (_lastPongTime != null) {
        final timeSinceLastPong = DateTime.now().difference(_lastPongTime!);
        if (timeSinceLastPong > _pongTimeout) {
          log('[SocketService] No pong received for ${timeSinceLastPong.inSeconds}s, reconnecting...');
          _forceReconnect();
          return;
        }
      }

      // Send ping to server
      log('[SocketService] Sending ping');
      _socket!.emit('ping');
    });
  }

  /// Stop the heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Schedule a reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectTimer != null) return; // Already scheduled

    log('[SocketService] Scheduling reconnection in ${_reconnectDelay.inSeconds}s');
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectTimer = null;
      if (_socket == null || !_socket!.connected) {
        log('[SocketService] Attempting reconnection...');
        _socket?.connect();
      }
    });
  }

  /// Cancel any pending reconnection timer
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Force reconnection by disconnecting and reconnecting
  void _forceReconnect() {
    log('[SocketService] Force reconnecting...');
    _stopHeartbeat();
    _socket?.disconnect();

    // Small delay before reconnecting
    Future.delayed(const Duration(milliseconds: 500), () {
      _socket?.connect();
    });
  }

  /// Manually trigger a reconnection (can be called from UI)
  void reconnect() {
    log('[SocketService] Manual reconnection requested');
    if (_socket != null && !_socket!.connected) {
      _socket!.connect();
    } else if (_socket == null) {
      connect();
    }
  }

  void disconnect() {
    if (_socket != null) {
      log('[SocketService] Disconnecting socket...');
      _stopHeartbeat();
      _cancelReconnectTimer();
      _socket!.disconnect();
      _socket!.destroy();
      _socket = null;
      _statusController.add(SocketStatus.disconnected);
    }
  }

  void dispose() {
    _stopHeartbeat();
    _cancelReconnectTimer();
    disconnect();
    _statusController.close();
  }
}

enum SocketStatus { connected, disconnected, error, reconnected }
