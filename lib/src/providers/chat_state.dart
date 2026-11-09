import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../data/services/reverb_service.dart';
import '../data/services/polling_service.dart';
import 'providers.dart';
import 'widget_state.dart';

@immutable
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final bool isSending;
  final int currentPage;
  final int? conversationId;
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.isSending = false,
    this.currentPage = 1,
    this.conversationId,
  });
  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool? isSending,
    int? currentPage,
    int? conversationId,
  }) => ChatState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: error,
    isSending: isSending ?? this.isSending,
    currentPage: currentPage ?? this.currentPage,
    conversationId: conversationId ?? this.conversationId,
  );
}

class ChatStateNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  ReverbService? _socket;
  int? _socketConversation;
  PollingService? _polling;
  StreamSubscription<List<Message>>? _pollingSubscription;
  bool _initialLoadComplete = false;
  ChatStateNotifier(this._ref) : super(const ChatState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final storage = _ref.read(localStorageProvider);
      await storage.init();
      if (!mounted) return;
      final cached = (storage.getCachedMessages() ?? [])
          .where(_visible)
          .toList();
      state = state.copyWith(messages: _merge([], cached));
      _polling = _ref.read(pollingServiceProvider);
      _pollingSubscription = _polling!.onNewMessages.listen((messages) {
        if (mounted) {
          state = state.copyWith(messages: _merge(state.messages, messages));
          _cache();
        }
      });
      await loadMessages();
    } catch (_) {
      if (mounted) state = state.copyWith(isLoading: false, error: 'load');
    }
  }

  bool _visible(Message message) =>
      !message.isPrivate &&
      message.type != SendMessageType.note &&
      message.type != SendMessageType.info;
  String? _key(Message message) => message.serverId ?? message.id?.toString();
  List<Message> _merge(List<Message> existing, List<Message> incoming) {
    final result = existing.where(_visible).toList();
    for (final message in incoming.where(_visible)) {
      final key = _key(message);
      var index = result.indexWhere(
        (item) =>
            (key != null && _key(item) == key) ||
            (key == null &&
                _key(item) == null &&
                (message.uId?.isNotEmpty ?? false) &&
                item.uId == message.uId),
      );
      if (index < 0 &&
          message.messageType == MessageType.myMessage &&
          (message.id ?? 0) >= 0) {
        // Reconcile a single optimistic item, never distinct server messages by text.
        index = result.indexWhere(
          (item) =>
              (item.id ?? -1) < 0 &&
              item.messageType == MessageType.myMessage &&
              item.body == message.body &&
              item.type == message.type,
        );
      }
      if (index < 0) {
        result.add(message);
      } else {
        result[index] = message;
      }
    }
    result.sort(
      (a, b) => (DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1970))
          .compareTo(DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1970)),
    );
    return result;
  }

  Future<void> _cache() async {
    if (!mounted) return;
    try {
      await _ref.read(localStorageProvider).cacheMessages(state.messages);
    } catch (_) {
      /* Persistence must not fail a successful send. */
    }
  }

  void _connect(int? conversationId) {
    if (conversationId == null || !mounted) return;
    state = state.copyWith(conversationId: conversationId);
    if (_socketConversation == conversationId) return;
    _socket?.close();
    _socketConversation = conversationId;
    try {
      _socket = _ref.read(reverbServiceProvider(conversationId.toString()));
      _socket!.listen(_onSocket, 'conversation_id_$conversationId');
    } catch (_) {
      _socket = null;
      _socketConversation = null;
      if (_ref.read(configProvider).enablePollingFallback) _polling?.start();
    }
  }

  void _onSocket(dynamic event) {
    if (!mounted || event is! WebsocketResponse) return;
    if (event.event == 'beon:disconnected') {
      if (_ref.read(configProvider).enablePollingFallback) _polling?.start();
      return;
    }
    if (event.event == 'pusher:connection_established') {
      _polling?.stop();
      refresh();
      return;
    }
    if (event.event != 'conversations_message' &&
        event.event != '.conversations_message') {
      return;
    }
    final data = event.data;
    if (data == null) return;
    final conversation = int.tryParse('${data['conversation_id'] ?? ''}');
    if (conversation != null &&
        state.conversationId != null &&
        conversation != state.conversationId) {
      return;
    }
    final raw = data['last_message'] ?? data['message'] ?? data;
    if (raw is! Map) return;
    final message = Message.fromJson(Map<String, dynamic>.from(raw));
    if (!_visible(message)) return;
    final isNew = !state.messages.any(
      (m) => _key(m) != null && _key(m) == _key(message),
    );
    state = state.copyWith(messages: _merge(state.messages, [message]));
    if (isNew && message.messageType != MessageType.myMessage) {
      _ref.read(widgetStateProvider.notifier).incrementUnread();
    }
    _cache();
  }

  Future<void> loadMessages({bool refresh = false}) async {
    if (state.isLoading || (_initialLoadComplete && !refresh)) return;
    state = state.copyWith(isLoading: true);
    try {
      final service = _ref.read(chatServiceProvider);
      final (messages, conversationId) = await service.fetchHistory(page: 1);
      if (!mounted) return;
      state = state.copyWith(
        messages: _merge(state.messages, messages),
        isLoading: false,
        hasMore: service.historyHasMore ?? messages.length >= 10,
        currentPage: refresh ? state.currentPage : 2,
        conversationId: conversationId,
      );
      _initialLoadComplete = true;
      _connect(conversationId);
      await _cache();
    } catch (_) {
      if (mounted) state = state.copyWith(isLoading: false, error: 'load');
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final service = _ref.read(chatServiceProvider);
      final (messages, conversationId) = await service.fetchHistory(
        page: state.currentPage,
      );
      if (!mounted) return;
      state = state.copyWith(
        messages: _merge(state.messages, messages),
        isLoadingMore: false,
        hasMore: service.historyHasMore ?? messages.length >= 10,
        currentPage: state.currentPage + 1,
        conversationId: conversationId,
      );
      await _cache();
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isLoadingMore: false, error: 'loadMore');
      }
    }
  }

  Future<void> refresh() => loadMessages(refresh: true);

  Future<void> sendMessage(String content) => _send(content: content.trim());
  Future<void> sendMessageWithAttachment({
    required String filePath,
    required String fileName,
    required SendMessageType type,
    String? content,
  }) => _send(
    content: content ?? filePath,
    filePath: filePath,
    fileName: fileName,
    type: type,
  );

  Future<void> _send({
    required String content,
    String? filePath,
    String? fileName,
    SendMessageType type = SendMessageType.text,
  }) async {
    if (state.isSending || (filePath == null && content.isEmpty)) return;
    final tempId = -DateTime.now().microsecondsSinceEpoch;
    final temp = Message(
      id: tempId,
      body: content,
      localPath: filePath,
      type: type,
      messageType: MessageType.myMessage,
      messageStatus: MessageStatus.sending,
      createdAt: DateTime.now().toIso8601String(),
    );
    state = state.copyWith(
      messages: [temp, ...state.messages],
      isSending: true,
    );
    try {
      final service = _ref.read(chatServiceProvider);
      final sent = filePath == null
          ? await service.sendMessage(content)
          : await service.sendMessageWithAttachment(
              filePath: filePath,
              fileName: fileName!,
              type: type,
            );
      if (!mounted) return;
      final confirmed = sent.copyWith(
        id: sent.id ?? tempId,
        messageStatus: MessageStatus.sent,
      );
      state = state.copyWith(
        messages: _merge(state.messages.where((m) => m.id != tempId).toList(), [
          confirmed,
        ]),
        isSending: false,
      );
      _connect(sent.conversationId);
      await _cache();
      // The web API often acknowledges a send without its conversation ID.
      // Recover it immediately so history, tickets and realtime share one chat.
      if (state.conversationId == null) await refresh();
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        messages: state.messages
            .map(
              (m) => m.id == tempId
                  ? m.copyWith(
                      messageStatus: MessageStatus.failed,
                      isSendingError: true,
                    )
                  : m,
            )
            .toList(),
        isSending: false,
        error: 'send',
      );
      await _cache();
    }
  }

  Future<void> retryMessage(int messageId) async {
    if (state.isSending) return;
    final failed = state.messages.where(
      (m) => m.id == messageId && m.messageStatus == MessageStatus.failed,
    );
    if (failed.isEmpty) return;
    final message = failed.first;
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != messageId).toList(),
    );
    if (message.localPath != null) {
      await sendMessageWithAttachment(
        filePath: message.localPath!,
        fileName: message.localPath!.split(RegExp(r'[/\\]')).last,
        type: message.type ?? SendMessageType.document,
      );
    } else {
      await sendMessage(message.body ?? '');
    }
  }

  void clearError() {
    state = state.copyWith();
  }

  @override
  void dispose() {
    _pollingSubscription?.cancel();
    _polling?.dispose();
    _socket?.close();
    super.dispose();
  }
}

final chatStateProvider = StateNotifierProvider<ChatStateNotifier, ChatState>(
  (ref) => ChatStateNotifier(ref),
  dependencies: [
    configProvider,
    localStorageProvider,
    pollingServiceProvider,
    chatServiceProvider,
    reverbServiceProvider,
    widgetStateProvider,
  ],
);
