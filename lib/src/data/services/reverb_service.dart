import 'dart:async';
import 'dart:convert';
import 'package:simple_flutter_reverb/simple_flutter_reverb_options.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class ReverbService {
  void listen(
    void Function(dynamic) onData,
    String channelName, {
    bool isPrivate = false,
  });
  void close();
}

/// Public widget channels reconnect and resubscribe after network interruptions.
class SimpleFlutterReverb implements ReverbService {
  final SimpleFlutterReverbOptions options;
  final WebSocketChannel Function(Uri) _connector;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeat;
  String? _channelName;
  void Function(dynamic)? _onData;
  bool _closed = false;
  int _attempt = 0;
  SimpleFlutterReverb({
    Uri? endpoint,
    WebSocketChannel Function(Uri)? connector,
  }) : options = SimpleFlutterReverbOptions(
         scheme: endpoint?.scheme ?? 'wss',
         host: endpoint?.host ?? 'ws.beon.chat',
         port: endpoint?.hasPort == true ? endpoint!.port.toString() : '443',
         appKey: 't2vthpcpevqgpzw70dku',
       ),
       _connector = connector ?? WebSocketChannel.connect;

  @override
  void listen(
    void Function(dynamic) onData,
    String channelName, {
    bool isPrivate = false,
  }) {
    if (_closed) return;
    if (isPrivate) {
      throw UnsupportedError('The widget SDK uses public visitor channels.');
    }
    _onData = onData;
    _channelName = channelName;
    _connect();
  }

  Future<void> _connect() async {
    if (_closed || _channelName == null) return;
    _reconnectTimer?.cancel();
    // Detach immediately; socket cleanup may finish after the remote close.
    // Reconnection must not wait for that cleanup future to complete.
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (_closed) return;
    try {
      final uri = Uri.parse(
        '${options.scheme}://${options.host}:${options.port}/app/${options.appKey}',
      );
      final channel = _connector(uri);
      _channel = channel;
      _subscription = channel.stream.listen(
        _receive,
        onError: (_) => _reconnect(),
        onDone: _reconnect,
      );
      await channel.ready;
    } catch (_) {
      _reconnect();
    }
  }

  void _receive(dynamic raw) {
    if (_closed) return;
    try {
      final event = WebsocketResponse.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw)),
      );
      if (event.event == 'pusher:connection_established') {
        _attempt = 0;
        _send({
          'event': 'pusher:subscribe',
          'data': {'channel': _channelName},
        });
        _heartbeat?.cancel();
        _heartbeat = Timer.periodic(
          const Duration(seconds: 25),
          (_) => _send({'event': 'pusher:ping', 'data': {}}),
        );
      } else if (event.event == 'pusher:ping') {
        _send({'event': 'pusher:pong', 'data': {}});
      }
      _onData?.call(event);
    } catch (_) {
      /* Ignore malformed socket frames without dropping the stream. */
    }
  }

  void _send(Map<String, dynamic> payload) {
    if (_closed) return;
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (_) {
      _reconnect();
    }
  }

  void _reconnect() {
    if (_closed || _reconnectTimer?.isActive == true) return;
    _heartbeat?.cancel();
    _onData?.call(WebsocketResponse(event: 'beon:disconnected'));
    final delay = Duration(seconds: (1 << _attempt.clamp(0, 5)).clamp(1, 30));
    _attempt++;
    _reconnectTimer = Timer(delay, () {
      _channel?.sink.close();
      _connect();
    });
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _reconnectTimer?.cancel();
    _heartbeat?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _onData = null;
  }
}

class WebsocketResponse {
  final String event;
  final Map<String, dynamic>? data;
  WebsocketResponse({required this.event, this.data});
  factory WebsocketResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final decoded = raw is String ? jsonDecode(raw) : raw;
    return WebsocketResponse(
      event: '${json['event'] ?? ''}',
      data: decoded is Map ? Map<String, dynamic>.from(decoded) : null,
    );
  }
}
