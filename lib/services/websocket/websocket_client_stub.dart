import 'websocket_client.dart';

UniversalWebSocketClient createWebSocketClient() =>
    throw UnsupportedError('Cannot create a WebSocket client without dart:html or dart:io');
