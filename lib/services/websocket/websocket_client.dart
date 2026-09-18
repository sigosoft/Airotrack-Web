typedef OnMessageCallback = void Function(String message);
typedef OnOpenCallback = void Function();
typedef OnCloseCallback = void Function();
typedef OnErrorCallback = void Function(dynamic error);

abstract class UniversalWebSocketClient {
  void connect({
    required String url,
    required OnOpenCallback onOpen,
    required OnMessageCallback onMessage,
    required OnCloseCallback onClose,
    required OnErrorCallback onError,
  });

  void send(String data);
  void close();
}
