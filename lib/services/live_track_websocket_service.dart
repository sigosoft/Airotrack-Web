import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/live_track_model.dart';
import 'websocket/websocket_client.dart';
import 'websocket/websocket_client_stub.dart'
    if (dart.library.html) 'websocket/websocket_client_web.dart'
    if (dart.library.io) 'websocket/websocket_client_io.dart';

typedef DeviceUpdateCallback = void Function(Map<String, dynamic> data);
typedef ReconnectCallback = void Function();

class LiveTrackWebSocketService {
  UniversalWebSocketClient? _client;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isManuallyClosed = false;

  String? _activeImei;
  LiveWebsocketConfig? _config;
  LiveWebsocketInfo? _info;
  DeviceUpdateCallback? _onDeviceUpdate;
  ReconnectCallback? _onReconnected;

  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;

  bool get isConnected => _isConnected;

  Future<bool> connect({
    required String imei,
    required LiveWebsocketConfig? websocketConfig,
    required LiveWebsocketInfo? websocket,
    required DeviceUpdateCallback onDeviceUpdate,
    ReconnectCallback? onReconnected,
  }) async {
    _activeImei = imei;
    _config = websocketConfig;
    _info = websocket;
    _onDeviceUpdate = onDeviceUpdate;
    _onReconnected = onReconnected;
    _isManuallyClosed = false;

    if (websocketConfig == null) {
      debugPrint('[LiveTrackWS] websocketConfig is null, cannot connect');
      return false;
    }

    return _initiateConnection();
  }

  Future<bool> _initiateConnection() async {
    if (_isConnecting) return false;
    _isConnecting = true;

    _cleanupSocket();

    final wsUrl = _buildWebSocketUrl(_config!);
    if (wsUrl == null) {
      _isConnecting = false;
      debugPrint('[LiveTrackWS] Invalid WebSocket URL from config');
      return false;
    }

    debugPrint('[LiveTrackWS] Connecting to: $wsUrl');

    final completer = Completer<bool>();
    try {
      _client = createWebSocketClient();
      _client!.connect(
        url: wsUrl,
        onOpen: () {
          debugPrint('[LiveTrackWS] WebSocket socket opened');
          _isConnected = true;
          _isConnecting = false;
          _reconnectAttempts = 0;
          _startPingTimer();

          // If channel format is known, subscribe immediately or wait for handshake
          _subscribeToChannel();

          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        onMessage: (message) {
          _handleIncomingMessage(message);
        },
        onClose: () {
          debugPrint('[LiveTrackWS] WebSocket connection closed');
          _isConnected = false;
          _isConnecting = false;
          _stopPingTimer();

          if (!completer.isCompleted) {
            completer.complete(false);
          }

          if (!_isManuallyClosed) {
            _scheduleReconnect();
          }
        },
        onError: (error) {
          debugPrint('[LiveTrackWS] WebSocket error: $error');
          _isConnected = false;
          _isConnecting = false;
          _stopPingTimer();

          if (!completer.isCompleted) {
            completer.complete(false);
          }

          if (!_isManuallyClosed) {
            _scheduleReconnect();
          }
        },
      );

      // Timeout connection attempt after 8 seconds
      Future.delayed(const Duration(seconds: 8), () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
    } catch (e) {
      debugPrint('[LiveTrackWS] Failed to connect: $e');
      _isConnecting = false;
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      if (!_isManuallyClosed) {
        _scheduleReconnect();
      }
    }

    return completer.future;
  }

  String? _buildWebSocketUrl(LiveWebsocketConfig config) {
    var rawUrl = config.websocketUrl?.trim() ?? '';
    final appKey = config.appKey?.trim() ?? '';

    if (rawUrl.isEmpty) {
      final host = config.host?.trim();
      final port = config.port;
      final scheme = config.scheme?.trim() ?? 'wss';
      if (host != null && host.isNotEmpty) {
        rawUrl = '$scheme://$host${port != null ? ':$port' : ''}';
      }
    }

    if (rawUrl.isEmpty) return null;

    // Convert http/https to ws/wss if needed
    if (rawUrl.startsWith('http://')) {
      rawUrl = 'ws://${rawUrl.substring(7)}';
    } else if (rawUrl.startsWith('https://')) {
      rawUrl = 'wss://${rawUrl.substring(8)}';
    } else if (!rawUrl.startsWith('ws://') && !rawUrl.startsWith('wss://')) {
      rawUrl = 'wss://$rawUrl';
    }

    // Append Pusher path if not already present
    if (!rawUrl.contains('/app/')) {
      if (!rawUrl.endsWith('/')) rawUrl += '/';
      rawUrl +=
          'app/$appKey?protocol=7&client=js&version=8.4.0-rc2&flash=false';
    }

    return rawUrl;
  }

  void _subscribeToChannel() {
    final imei = _activeImei;
    if (imei == null || imei.isEmpty) return;

    final channelName =
        _info?.channel?.replaceAll('{imei}', imei) ?? 'device.$imei';
    debugPrint('[LiveTrackWS] Subscribing to channel: $channelName');

    final subscribePayload = jsonEncode({
      'event': 'pusher:subscribe',
      'data': {'channel': channelName},
    });

    _client?.send(subscribePayload);
  }

  void _handleIncomingMessage(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final event = decoded['event']?.toString() ?? '';

      // Pusher Handshake
      if (event == 'pusher:connection_established') {
        debugPrint('[LiveTrackWS] Pusher connection established');
        _subscribeToChannel();
        return;
      }

      // Heartbeat ping
      if (event == 'pusher:ping') {
        _client?.send(jsonEncode({'event': 'pusher:pong', 'data': {}}));
        return;
      }

      if (event == 'pusher_internal:subscription_succeeded') {
        debugPrint(
          '[LiveTrackWS] Subscription succeeded for ${decoded['channel']}',
        );
        return;
      }

      // Check if event is vehicle device update
      final targetEvent = _info?.eventName ?? 'device.update';
      final isUpdate =
          event == targetEvent ||
          event == 'device.update' ||
          event.contains('DeviceUpdate') ||
          event.contains('device_update');

      if (isUpdate) {
        var payload = decoded['data'];
        if (payload is String) {
          try {
            payload = jsonDecode(payload);
          } catch (_) {}
        }
        if (payload is Map<String, dynamic>) {
          _onDeviceUpdate?.call(payload);
        } else if (payload is Map) {
          _onDeviceUpdate?.call(Map<String, dynamic>.from(payload));
        }
      }
    } catch (e) {
      debugPrint('[LiveTrackWS] Error parsing message: $e');
    }
  }

  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        try {
          _client?.send(jsonEncode({'event': 'pusher:ping', 'data': {}}));
        } catch (_) {}
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _scheduleReconnect() {
    if (_isManuallyClosed) return;
    _reconnectTimer?.cancel();

    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts * 2).clamp(2, 20);
    debugPrint(
      '[LiveTrackWS] Reconnecting in $delaySeconds seconds (attempt $_reconnectAttempts)',
    );

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (_isManuallyClosed) return;
      final ok = await _initiateConnection();
      if (ok) {
        _onReconnected?.call();
      }
    });
  }

  Future<void> disconnect() async {
    _isManuallyClosed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopPingTimer();
    _cleanupSocket();
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
  }

  void _cleanupSocket() {
    _client?.close();
    _client = null;
  }
}
