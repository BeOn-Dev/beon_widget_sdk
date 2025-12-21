import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visitor.dart';
import '../models/message.dart';

/// Wrapper for SharedPreferences to manage local storage
class LocalStorageService {
  static const _visitorIdKey = 'beon_visitor_id';
  static const _visitorDataKey = 'beon_visitor_data';
  static const _sessionIdKey = 'beon_session_id';
  static const _messagesKey = 'beon_messages_cache';
  static const _preChatCompletedKey = 'beon_prechat_completed';
  static const _conversationUidKey = 'beon_conversation_uid';

  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Initialize the storage service
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Ensure initialized before operations
  void _ensureInitialized() {
    if (!_initialized || _prefs == null) {
      throw StateError('LocalStorageService not initialized. Call init() first.');
    }
  }

  // Visitor ID
  String? getVisitorId() {
    _ensureInitialized();
    return _prefs!.getString(_visitorIdKey);
  }

  Future<bool> saveVisitorId(String id) {
    _ensureInitialized();
    return _prefs!.setString(_visitorIdKey, id);
  }

  // Session ID
  String? getSessionId() {
    _ensureInitialized();
    return _prefs!.getString(_sessionIdKey);
  }

  Future<bool> saveSessionId(String id) {
    _ensureInitialized();
    return _prefs!.setString(_sessionIdKey, id);
  }

  // Visitor data
  Visitor? getVisitor() {
    _ensureInitialized();
    final data = _prefs!.getString(_visitorDataKey);
    if (data == null) return null;
    try {
      return Visitor.fromJson(jsonDecode(data));
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveVisitor(Visitor visitor) {
    _ensureInitialized();
    return _prefs!.setString(_visitorDataKey, jsonEncode(visitor.toJson()));
  }

  // Pre-chat completion status
  // Returns false if not initialized (safe default - will show form)
  bool getPreChatCompleted() {
    if (!_initialized || _prefs == null) {
      return false; // Not initialized, assume not completed
    }
    return _prefs!.getBool(_preChatCompletedKey) ?? false;
  }

  Future<bool> setPreChatCompleted(bool completed) {
    _ensureInitialized();
    return _prefs!.setBool(_preChatCompletedKey, completed);
  }

  // Conversation ID (identifies the chat conversation)
  String? getConversationUid() {
    _ensureInitialized();
    return _prefs!.getString(_conversationUidKey);
  }

  Future<bool> saveConversationUid(String uid) {
    _ensureInitialized();
    return _prefs!.setString(_conversationUidKey, uid);
  }

  // Message cache
  List<Message>? getCachedMessages() {
    _ensureInitialized();
    final data = _prefs!.getString(_messagesKey);
    if (data == null) return null;
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => Message.fromJson(json)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<bool> cacheMessages(List<Message> messages) {
    _ensureInitialized();
    final jsonList = messages.map((m) => _messageToJson(m)).toList();
    return _prefs!.setString(_messagesKey, jsonEncode(jsonList));
  }

  /// Convert Message to JSON for caching
  Map<String, dynamic> _messageToJson(Message m) {
    return {
      if (m.id != null) 'id': m.id,
      if (m.uId != null) 'uid': m.uId,
      if (m.conversationId != null) 'conversation_id': m.conversationId,
      if (m.body != null) 'body': m.body,
      if (m.localPath != null) 'local_path': m.localPath,
      if (m.status != null) 'status': m.status,
      if (m.type != null) 'type': m.type?.name,
      if (m.messageType != null) 'message_type': m.messageType == MessageType.myMessage ? 'my_message' : 'client_message',
      if (m.messageId != null) 'message_id': m.messageId,
      if (m.createdAt != null) 'created_at': m.createdAt,
      if (m.channelId != null) 'channel_id': m.channelId,
      if (m.agentName != null) 'agent_name': m.agentName,
      if (m.messageStatus != null) 'message_status': m.messageStatus?.name,
      if (m.longitude != null) 'long': m.longitude.toString(),
      if (m.latitude != null) 'lat': m.latitude.toString(),
    };
  }

  // Clear all cached messages
  Future<bool> clearMessages() {
    _ensureInitialized();
    return _prefs!.remove(_messagesKey);
  }

  // Clear all data
  Future<void> clear() async {
    _ensureInitialized();
    await _prefs!.remove(_visitorIdKey);
    await _prefs!.remove(_visitorDataKey);
    await _prefs!.remove(_sessionIdKey);
    await _prefs!.remove(_messagesKey);
    await _prefs!.remove(_preChatCompletedKey);
    await _prefs!.remove(_conversationUidKey);
  }

  // Get storage key with prefix (for custom data)
  String? getString(String key) {
    _ensureInitialized();
    return _prefs!.getString('beon_$key');
  }

  Future<bool> setString(String key, String value) {
    _ensureInitialized();
    return _prefs!.setString('beon_$key', value);
  }
}
