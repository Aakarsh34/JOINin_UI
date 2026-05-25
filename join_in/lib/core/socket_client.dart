import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/env.dart';
import 'token_storage.dart';

class SocketClient {
  SocketClient._();
  static final SocketClient instance = SocketClient._();

  io.Socket? _socket;
  io.Socket? get socket => _socket;
  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    final token = TokenStorage.instance.accessToken;
    if (token == null) return;
    if (_socket != null && _socket!.connected) return;

    _socket?.dispose();
    _socket = io.io(
      Env.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': 'Bearer $token'})
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!
      ..onConnect((_) {})
      ..onConnectError((err) {})
      ..onError((err) {})
      ..onDisconnect((_) {});

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void emitWithAck(String event, dynamic data, void Function(dynamic) ack) {
    _socket?.emitWithAck(event, data, ack: ack);
  }

  void on(String event, void Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event, [void Function(dynamic)? handler]) {
    if (handler == null) {
      _socket?.off(event);
    } else {
      _socket?.off(event, handler);
    }
  }
}
