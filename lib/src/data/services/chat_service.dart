import 'package:beon_widget_sdk/src/utils/app_functions/app_functions.dart';

import '../api_client.dart';
import '../../models/message.dart';
import '../../models/metadata.dart';
import '../../models/channel_config.dart';
import '../../utils/fingerprint_generator.dart';
import '../../config/beon_config.dart';

/// Service for chat API operations
class ChatService {
  final BeonApiClient _apiClient;
  final BeonConfig _config;
  final String Function() _getVisitorId;
  final MessageMetadata Function({String? messageContent,String? conversationUId}) _getMetadata;
  final void Function()? _clearInitialMessage;
  final String? Function() _getConversationUid;
  final void Function(String) _setConversationUid;
  static ChannelConfig? _cachedChannelConfig;
  static String? _cachedApiKey;
  static Future<ChannelConfig?>? _pendingRequest;

  ChatService(
    this._apiClient,
    this._config,
    this._getVisitorId,
    this._getMetadata,
    this._getConversationUid,
    this._setConversationUid, [
    this._clearInitialMessage,
  ]);

  /// Fetch message history
  /// Returns a tuple of (messages, conversationId)
  Future<(List<Message>, int?)> fetchHistory({
    int page = 1,
    int limit = 20,
    DateTime? before,
  }) async {
    final conversationUid = _getConversationUid();
    if (conversationUid == null) {
      // No conversation started yet
      return (<Message>[], null);
    }

    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'uid': conversationUid,
    };

    if (before != null) {
      params['before'] = before.toIso8601String();
    }

    try {
      final response = await _apiClient.get(
        '/messages',
        queryParameters: params,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Parse using MessagesResponse for proper structure handling
        final messagesResponse = MessagesResponse.fromJson(data);
        AppFunctions.logPrint(message: "Messagaessss s : ${messagesResponse.messages.toString()}");
        return (messagesResponse.messages, messagesResponse.conversationId);
      } else if (data is List) {
        return (data.map((json) => Message.fromJson(json)).toList(), null);
      }

      return (<Message>[], null);
    } catch (e) {
      rethrow;
    }
  }

  /// Send a text message
  Future<Message> sendMessage(String content) async {

    // Get or create conversation UID (same ID for all messages in conversation)
    String conversationUid = _getConversationUid() ?? FingerprintGenerator.generateMessageId();

    final metadata = _getMetadata(messageContent: content,conversationUId:conversationUid );

    // Set conversation UID if this is the first message
    if (_getConversationUid() == null) {
      _setConversationUid(conversationUid);
    }

    final payload = {
      'message': content,
      'id': conversationUid, // Use same ID for all messages in conversation
      'token': _config.apiKey,
      'metadata': metadata.toJson(),
    };

    // Clear initial message after first send
    _clearInitialMessage?.call();

    // Generate a unique local message ID for UI tracking
    final localMessageId = '${conversationUid}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await _apiClient.post(
        '/message/send',
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Parse id as int (API may return int or String)
        try {
          int? messageId;
          if (data['id'] != null) {
            messageId = data['id'] is int
                ? data['id']
                : int.tryParse(data['id'].toString());
          }

          // Use server timestamp if available, otherwise use local time
          final serverTimestamp = data['created_at']?.toString();

          return Message.fromJson({
            ...data,
            'id': messageId,
            'body': content,
            'is_from_visitor': true,
            'message_type': 'my_message', // Visitor's own message
            if (serverTimestamp == null) 'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          AppFunctions.logPrint(message: "Error parsing message: ${e.toString()}");
        }
      }

      // Return optimistic message if response doesn't include full data
      return Message(
        id: int.tryParse(localMessageId.replaceAll(RegExp(r'[^0-9]'), '').substring(0, 9)),
        body: content,
        type: SendMessageType.text,
        messageType: MessageType.myMessage,
        messageStatus: MessageStatus.sent,
        createdAt: DateTime.now().toIso8601String(),
        agentName: metadata.senderName,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Send a message with attachment
  Future<Message> sendMessageWithAttachment({
    required String filePath,
    required String fileName,
    String? content,
  }) async {
    final metadata = _getMetadata();

    // Get or create conversation UID (same ID for all messages in conversation)
    String conversationUid = _getConversationUid() ?? FingerprintGenerator.generateMessageId();

    // Set conversation UID if this is the first message
    if (_getConversationUid() == null) {
      _setConversationUid(conversationUid);
    }

    // Generate a unique local message ID for UI tracking
    final localMessageId = '${conversationUid}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await _apiClient.uploadFile(
        '/message/send',
        filePath: filePath,
        fileName: fileName,
        extraData: {
          'message': content ?? '',
          'id': conversationUid, // Use same ID for all messages in conversation
          'token': _config.apiKey,
          'metadata': metadata.toJson(),
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Parse id as int
        int? messageId;
        if (data['id'] != null) {
          messageId = data['id'] is int
              ? data['id']
              : int.tryParse(data['id'].toString());
        }

        // Use server timestamp if available
        final serverTimestamp = data['created_at']?.toString();

        return Message.fromJson({
          ...data,
          'id': messageId,
          'body': content ?? fileName,
          'is_from_visitor': true,
          'message_type': 'my_message', // Visitor's own message
          if (serverTimestamp == null) 'created_at': DateTime.now().toIso8601String(),
          'type': 'document',
        });
      }

      return Message(
        id: int.tryParse(localMessageId.replaceAll(RegExp(r'[^0-9]'), '').substring(0, 9)),
        body: content ?? fileName,
        type: SendMessageType.document,
        messageType: MessageType.myMessage,
        messageStatus: MessageStatus.sent,
        createdAt: DateTime.now().toIso8601String(),
        agentName: metadata.senderName,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      await _apiClient.post(
        '/messages/$messageId/read',
        data: {
          'uid': _getVisitorId(),
        },
      );
    } catch (_) {
      // Silent fail for read receipts
    }
  }

  /// Validate widget and fetch channel configuration
  ///
  /// Returns [ChannelConfig] with settings from API including:
  /// - Channel ID, name, identifier
  /// - Pre-chat form settings (enabled fields)
  /// - Primary color, position
  /// - Welcome message
  Future<ChannelConfig?> fetchChannelConfig() async {
    // Return cached config if available for the same API key
    if (_cachedChannelConfig != null && _cachedApiKey == _config.apiKey) {
      return _cachedChannelConfig;
    }

    // If there's a pending request for the same API key, wait for it
    if (_pendingRequest != null && _cachedApiKey == _config.apiKey) {
      return _pendingRequest;
    }

    // Start new request
    _cachedApiKey = _config.apiKey;
    _pendingRequest = _fetchChannelConfigFromApi();

    try {
      final result = await _pendingRequest;
      _cachedChannelConfig = result;
      return result;
    } finally {
      _pendingRequest = null;
    }
  }

  /// Internal method to fetch channel config from API
  Future<ChannelConfig?> _fetchChannelConfigFromApi() async {
    try {
      final response =
          await _apiClient.get('/channels/validate/${_config.apiKey}');
      if (response.statusCode == 200 && response.data != null) {
        return ChannelConfig.fromApiResponse(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validate widget configuration (legacy method)
  Future<bool> validateWidget() async {
    final config = await fetchChannelConfig();
    return config != null;
  }
}
