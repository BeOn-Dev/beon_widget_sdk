import 'dart:convert';
import 'package:dio/dio.dart';
import '../api_client.dart';
import '../../models/message.dart';
import '../../models/metadata.dart';
import '../../models/channel_config.dart';
import '../../config/beon_config.dart';

class ChatService {
  final BeonApiClient _apiClient;
  final BeonConfig _config;
  final String Function() _getVisitorId;
  final MessageMetadata Function({
    String? messageContent,
    String? conversationUId,
  })
  _getMetadata;
  final String? Function() _getConversationUid;
  final void Function(String) _setConversationUid;
  final void Function()? _clearInitialMessage;
  Future<ChannelConfig?>? _channelRequest;
  bool? historyHasMore;

  ChatService(
    this._apiClient,
    this._config,
    this._getVisitorId,
    this._getMetadata,
    this._getConversationUid,
    this._setConversationUid, [
    this._clearInitialMessage,
  ]);

  String get _uid {
    final visitor = _getVisitorId().trim();
    final value = visitor.isNotEmpty ? visitor : _getConversationUid();
    if (value == null || value.isEmpty) {
      throw StateError('Visitor is not initialized');
    }
    return value;
  }

  Future<(List<Message>, int?)> fetchHistory({
    int page = 1,
    int limit = 10,
    DateTime? before,
  }) async {
    try {
      final response = await _apiClient.get(
        '/messages',
        queryParameters: {
          'uid': _uid,
          'token': _config.apiKey,
          'page': page,
          'limit': limit,
          if (before != null) 'before': before.toIso8601String(),
        },
      );
      final parsed = MessagesResponse.fromJson(
        response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : {'data': response.data},
      );
      historyHasMore = parsed.meta.currentPage < parsed.meta.lastPage;
      return (parsed.messages, parsed.conversationId);
    } on DioException catch (error) {
      // The widget API returns 404 for a visitor who has not started a chat.
      if (error.response?.statusCode == 404) {
        historyHasMore = false;
        return (<Message>[], null);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _messageData(dynamic value) {
    if (value is! Map) return {};
    final root = Map<String, dynamic>.from(value);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'])
        : root;
    final nested = data['message'] is Map
        ? Map<String, dynamic>.from(data['message'])
        : data['data'] is Map
        ? _messageData(data['data'])
        : data;
    return {...data, ...nested};
  }

  Message _sent(
    dynamic response, {
    required String body,
    required SendMessageType type,
    String? localPath,
  }) {
    final data = _messageData(response);
    final conversation = data['conversation'];
    return Message.fromJson({
      ...data,
      'id': data['id'] ?? data['message_id'],
      'body':
          data['body'] ??
          data['url'] ??
          data['path'] ??
          data['file_url'] ??
          body,
      'type': type.name,
      'message_type': 'incoming',
      'status': data['status'] ?? 'sent',
      'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
      'conversation_id':
          data['conversation_id'] ??
          data['conversationId'] ??
          (conversation is Map ? conversation['id'] : null),
      if (localPath != null) 'local_path': localPath,
    });
  }

  Future<Message> sendMessage(String content) async {
    final uid = _uid;
    final metadata = _getMetadata(
      messageContent: content,
      conversationUId: uid,
    );
    final response = await _apiClient.post(
      '/message/send',
      data: {
        'content': content,
        'type': 'text',
        'id': uid,
        'token': _config.apiKey,
        'meta_data': metadata.toJson(),
      },
    );
    _setConversationUid(uid);
    _clearInitialMessage?.call();
    return _sent(response.data, body: content, type: SendMessageType.text);
  }

  Future<Message> sendMessageWithAttachment({
    required String filePath,
    required String fileName,
    required SendMessageType type,
    String? content,
  }) async {
    final uid = _uid;
    final metadata = _getMetadata(conversationUId: uid);
    final response = await _apiClient.uploadFile(
      '/message/send',
      filePath: filePath,
      fileName: fileName,
      extraData: {
        'type': type.name,
        'id': uid,
        'token': _config.apiKey,
        'metadata': jsonEncode(metadata.toJson()),
      },
    );
    _setConversationUid(uid);
    _clearInitialMessage?.call();
    return _sent(
      response.data,
      body: content ?? fileName,
      type: type,
      localPath: filePath,
    );
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await _apiClient.post(
        '/messages/$messageId/read',
        data: {'uid': _uid, 'token': _config.apiKey},
      );
    } catch (_) {
      /* Read receipt failures must not interrupt chat. */
    }
  }

  Future<ChannelConfig?> fetchChannelConfig() {
    // Cache only within this client, so concurrent widgets cannot exchange channels.
    return _channelRequest ??= _fetchChannelConfig();
  }

  Future<ChannelConfig?> _fetchChannelConfig() async {
    try {
      final response = await _apiClient.get(
        '/channels/validate/${_config.apiKey}',
      );
      final channel = ChannelConfig.fromApiResponse(
        Map<String, dynamic>.from(response.data),
      );
      if (channel == null) throw StateError('Invalid support channel');
      if (_config.channelId != null && _config.channelId != channel.id) {
        throw StateError('Support channel does not match configuration');
      }
      return channel;
    } catch (_) {
      _channelRequest = null;
      rethrow;
    }
  }

  Future<bool> validateWidget() async => await fetchChannelConfig() != null;
}
