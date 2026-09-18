import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'websocket_client.dart';

UniversalWebSocketClient createWebSocketClient() => IoUniversalWebSocketClient();

class IoUniversalWebSocketClient implements UniversalWebSocketClient {
  io.WebSocket? _socket;
  StreamSubscription? _subscription;

  @override
  void connect({
    required String url,
    required OnOpenCallback onOpen,
    required OnMessageCallback onMessage,
    required OnCloseCallback onClose,
    required OnErrorCallback onError,
  }) async {
    close();
    try {
      _socket = await io.WebSocket.connect(url);
      onOpen();

      _subscription = _socket?.listen(
        (data) {
          if (data is String) {
            onMessage(data);
          }
        },
        onDone: () {
          onClose();
        },
        onError: (error) {
          onError(error);
        },
      );
    } catch (e) {
      onError(e);
    }
  }

  @override
  void send(String data) {
    if (_socket != null && _socket!.readyState == io.WebSocket.open) {
      _socket!.add(data);
    }
  }

  @override
  void close() {
    _subscription?.cancel();
    _subscription = null;
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
  }
}
