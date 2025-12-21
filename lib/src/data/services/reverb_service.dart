import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:simple_flutter_reverb/simple_flutter_reverb_options.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../utils/app_functions/app_functions.dart';

abstract class ReverbService {
  Future<String?> _authenticate(String socketId, String channelName);

  void _subscribe(String channelName, String? broadcastAuthToken,
      {bool isPrivate = false});

  void listen(void Function(dynamic) onData, String channelName,
      {bool isPrivate = false});

  void close();
}

class SimpleFlutterReverb implements ReverbService {
  late final WebSocketChannel _channel;
  final SimpleFlutterReverbOptions options = SimpleFlutterReverbOptions(
    scheme: "wss",
    host: "v3.api.beon.chat",
    port: "443",
    appKey: "t2vthpcpevqgpzw70dku",
  );

  bool _isClosed = false;

  // Track stream subscription for proper cleanup
  StreamSubscription? _streamSubscription;

  // Singleton HTTP client to prevent file descriptor leaks
  static http.Client? _httpClient;

  SimpleFlutterReverb() {
    try {
      final wsUrl = _constructWebSocketUrl();
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      AppFunctions.logPrint(message: '✅ WebSocket connecting to: $wsUrl');
    } catch (e) {
      AppFunctions.logPrint(message: '❌ Failed to connect to WebSocket: $e');
      rethrow;
    }
  }

  String _constructWebSocketUrl() {
    return '${options.scheme}://${options.host}:${options.port}/app/${options.appKey}';
  }

  @override
  void _subscribe(String channelName, String? broadcastAuthToken,
      {bool isPrivate = false}) {
    try {
      if (_isClosed) {
        AppFunctions.logPrint(
            message: '⚠️ Cannot subscribe: connection is closed');
        return;
      }

      final subscription = {
        "event": "pusher:subscribe",
        "data": isPrivate
            ? {"channel": channelName, "auth": broadcastAuthToken}
            : {"channel": channelName},
      };
      _channel.sink.add(jsonEncode(subscription));

      AppFunctions.logPrint(
          message:
          '📡 Subscribing to channel: $channelName (private: $isPrivate)');
    } catch (e) {
      AppFunctions.logPrint(message: '❌ Failed to subscribe to channel: $e');
      rethrow;
    }
  }

  @override
  void listen(void Function(dynamic) onData, String channelName,
      {bool isPrivate = false}) {
    try {
      if (_isClosed) {
        AppFunctions.logPrint(
            message: '⚠️ Cannot listen: connection is closed');
        return;
      }

      final channelPrefix = options.usePrefix ? options.privatePrefix : '';
      final fullChannelName =
      isPrivate ? '$channelPrefix$channelName' : channelName;

      _subscribe(channelName, null);

      // Cancel any existing subscription before creating a new one
      _streamSubscription?.cancel();

      _streamSubscription = _channel.stream.listen(
            (message) async {
          try {
            final Map<String, dynamic> jsonMessage = jsonDecode(message);
            final response = WebsocketResponse.fromJson(jsonMessage);

            if (response.event == 'pusher:connection_established') {
              final socketId = response.data?['socket_id'];

              if (socketId == null) {
                throw Exception('Socket ID is missing');
              }

              AppFunctions.logPrint(
                  message:
                  '✅ Connection established with socket_id: $socketId');

              if (isPrivate) {
                final authToken =
                await _authenticate(socketId, fullChannelName);
                if (authToken != null) {
                  _subscribe(fullChannelName, authToken, isPrivate: isPrivate);
                } else {
                  AppFunctions.logPrint(
                      message: '❌ Authentication failed for private channel');
                }
              } else {
                _subscribe(fullChannelName, null, isPrivate: isPrivate);
              }
            } else if (response.event == 'pusher:ping') {
              if (!_isClosed) {
                _channel.sink.add(jsonEncode({'event': 'pusher:pong'}));
                AppFunctions.logPrint(message: '🏓 Pong sent');
              }
            } else if (response.event == 'pusher:subscription_succeeded') {
              AppFunctions.logPrint(
                  message: '✅ Subscription succeeded for: $channelName');
            }

            onData(response);
          } catch (e) {
            AppFunctions.logPrint(
                message: '❌ Error processing message: ${e.toString()}');
          }
        },
        onError: (error) {
          AppFunctions.logPrint(message: "❌ Stream Error: $error");
        },
        onDone: () {
          _isClosed = true;
          AppFunctions.logPrint(
              message: '🔌 Connection closed for channel: $channelName');
        },
      );

      AppFunctions.logPrint(message: '👂 Listening to channel: $channelName');
    } catch (e) {
      AppFunctions.logPrint(message: '❌ Failed to listen to WebSocket: $e');
      rethrow;
    }
  }

  @override
  Future<String?> _authenticate(String socketId, String channelName) async {
    try {
      if (options.authToken == null) {
        throw Exception('Auth Token is missing');
      } else if (options.authUrl == null) {
        throw Exception('Auth URL is missing');
      }

      var token = options.authToken;
      if (options.authToken is Future<String?>) {
        token = await options.authToken;
      } else if (options.authToken is String) {
        token = options.authToken;
      } else {
        throw Exception('Parameter authToken is not a string or a function');
      }

      AppFunctions.logPrint(
          message: '🔐 Authenticating for channel: $channelName');

      // Use singleton HTTP client to prevent file descriptor leaks
      _httpClient ??= http.Client();

      final response = await _httpClient!.post(
        Uri.parse(options.authUrl!),
        headers: {'Authorization': 'Bearer $token'},
        body: {'socket_id': socketId, 'channel_name': channelName},
      );

      if (response.statusCode == 200) {
        AppFunctions.logPrint(message: '✅ Authentication successful');
        return jsonDecode(response.body)['auth'];
      } else {
        throw Exception('Authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      AppFunctions.logPrint(message: '❌ Authentication error: $e');
      return null;
    }
  }

  @override
  void close() {
    try {
      if (_isClosed) {
        AppFunctions.logPrint(message: 'ℹ️ Connection already closed');
        return;
      }

      _isClosed = true;

      // Cancel stream subscription to prevent memory leaks
      _streamSubscription?.cancel();
      _streamSubscription = null;

      // Close WebSocket channel
      _channel.sink.close(status.normalClosure);

      AppFunctions.logPrint(message: '✅ WebSocket closed successfully');
    } catch (e) {
      AppFunctions.logPrint(message: '❌ Failed to close WebSocket: $e');
    }
  }
}

class WebsocketResponse {
  final String event;
  final Map<String, dynamic>? data;

  WebsocketResponse({required this.event, this.data});

  factory WebsocketResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedData;

    if (json['data'] != null) {
      try {
        // Check if data is already a Map (already parsed)
        if (json['data'] is Map) {
          parsedData = Map<String, dynamic>.from(json['data']);
        }
        // If data is a String, decode it as JSON
        else if (json['data'] is String) {
          parsedData = jsonDecode(json['data']) as Map<String, dynamic>;
        }
        // Otherwise, try to convert to string and decode
        else {
          AppFunctions.logPrint(
              message:
              "⚠️ Unexpected data type in WebSocket: ${json['data'].runtimeType}");
          parsedData = null;
        }
      } catch (e) {
        AppFunctions.logPrint(
            message: "❌ Error parsing WebSocket data: $e - Data: ${json['data']}");
        parsedData = null;
      }
    }

    return WebsocketResponse(
      event: json['event'],
      data: parsedData,
    );
  }
}
