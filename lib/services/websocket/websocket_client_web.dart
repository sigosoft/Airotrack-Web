// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'websocket_client.dart';

UniversalWebSocketClient createWebSocketClient() => WebUniversalWebSocketClient();

class WebUniversalWebSocketClient implements UniversalWebSocketClient {
  html.WebSocket? _socket;
  StreamSubscription? _onOpenSub;
  StreamSubscription? _onMessageSub;
  StreamSubscription? _onCloseSub;
  StreamSubscription? _onErrorSub;

  @override
  void connect({
    required String url,
    required OnOpenCallback onOpen,
    required OnMessageCallback onMessage,
    required OnCloseCallback onClose,
    required OnErrorCallback onError,
  }) {
    close();
    try {
      _socket = html.WebSocket(url);

      _onOpenSub = _socket?.onOpen.listen((_) {
        onOpen();
      });

      _onMessageSub = _socket?.onMessage.listen((event) {
        final data = event.data;
        if (data is String) {
          onMessage(data);
        }
      });

      _onCloseSub = _socket?.onClose.listen((_) {
        onClose();
      });

      _onErrorSub = _socket?.onError.listen((e) {
        onError(e);
      });
    } catch (e) {
      onError(e);
    }
  }

  @override
  void send(String data) {
    if (_socket != null && _socket!.readyState == html.WebSocket.OPEN) {
      _socket!.send(data);
    }
  }

  @override
  void close() {
    _onOpenSub?.cancel();
    _onOpenSub = null;
    _onMessageSub?.cancel();
    _onMessageSub = null;
    _onCloseSub?.cancel();
    _onCloseSub = null;
    _onErrorSub?.cancel();
    _onErrorSub = null;

    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
  }
}
