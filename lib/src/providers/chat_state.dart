import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../data/services/reverb_service.dart';
import '../data/services/polling_service.dart';
import '../utils/app_functions/app_functions.dart';
import 'providers.dart';
import 'widget_state.dart';

/// State of the chat
@immutable
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final bool isSending;
  final int currentPage;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.isSending = false,
    this.currentPage = 1,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool? isSending,
    int? currentPage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      isSending: isSending ?? this.isSending,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatState &&
        listEquals(other.messages, messages) &&
        other.isLoading == isLoading &&
        other.isLoadingMore == isLoadingMore &&
        other.hasMore == hasMore &&
        other.error == error &&
        other.isSending == isSending ;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(messages),
      isLoading,
      isLoadingMore,
      hasMore,
      error,
      isSending,
    );
  }
}

/// Notifier for managing chat state
class ChatStateNotifier extends StateNotifier<ChatState> {
  final Ref _ref;

  SimpleFlutterReverb? _reverbService;
  PollingService? _pollingService;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _pollingSubscription;
  bool _initialized = false;
  bool _initialLoadComplete = false;
  int? _currentConversationId;

  /// Deduplicate messages by checking multiple criteria
  List<Message> _deduplicateMessages(List<Message> messages) {
    final List<Message> result = [];
    final Set<String> seenUids = {};
    final Set<int> seenIds = {};
    final Map<String, int> seenContent = {}; // content -> index in result

    for (final message in messages) {
      bool isDuplicate = false;
      int? duplicateIndex;

      // Check by uId first (most reliable)
      if (message.uId != null && message.uId!.isNotEmpty) {
        if (seenUids.contains(message.uId)) {
          isDuplicate = true;
          duplicateIndex = result.indexWhere((m) => m.uId == message.uId);
        }
      }

      // Check by id (only for real server IDs, not temp IDs)
      if (!isDuplicate && message.id != null && message.id! > 0 && message.id! < 1000000000) {
        if (seenIds.contains(message.id)) {
          isDuplicate = true;
          duplicateIndex = result.indexWhere((m) => m.id == message.id);
        }
      }

      // ALWAYS check by body content to catch optimistic vs API messages
      // Don't include messageType as it might differ between cached and API messages
      final contentKey = message.body ?? '';
      if (!isDuplicate && contentKey.isNotEmpty && seenContent.containsKey(contentKey)) {
        isDuplicate = true;
        duplicateIndex = seenContent[contentKey];
      }

      if (!isDuplicate) {
        final index = result.length;
        result.add(message);

        // Track all identifiers for this message
        if (message.uId != null && message.uId!.isNotEmpty) {
          seenUids.add(message.uId!);
        }
        if (message.id != null && message.id! > 0 && message.id! < 1000000000) {
          seenIds.add(message.id!);
        }
        seenContent[contentKey] = index;
      } else if (duplicateIndex != null && duplicateIndex >= 0 && duplicateIndex < result.length) {
        // Replace existing with better data
        final existing = result[duplicateIndex];
        bool shouldReplace = false;

        // Prefer message with real server ID over temp ID
        if ((existing.id == null || existing.id! >= 1000000000) &&
            message.id != null && message.id! < 1000000000) {
          shouldReplace = true;
        }
        // Prefer message with uId
        else if (existing.uId == null && message.uId != null) {
          shouldReplace = true;
        }
        // Prefer message with non-sending status
        else if (existing.messageStatus == MessageStatus.sending &&
                 message.messageStatus != MessageStatus.sending) {
          shouldReplace = true;
        }

        if (shouldReplace) {
          result[duplicateIndex] = message;
          if (message.uId != null && message.uId!.isNotEmpty) {
            seenUids.add(message.uId!);
          }
          if (message.id != null && message.id! > 0 && message.id! < 1000000000) {
            seenIds.add(message.id!);
          }
        }
      }
    }

    return result;
  }

  ChatStateNotifier(this._ref) : super(const ChatState()) {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    final storage = _ref.read(localStorageProvider);
    await storage.init();
    final cached = storage.getCachedMessages();
    if (cached != null && cached.isNotEmpty) {
      state = state.copyWith(messages: cached);
    }

    // Initialize polling service
    _pollingService = _ref.read(pollingServiceProvider);

    // Subscribe to polling messages (fallback)
    _pollingSubscription =
        _pollingService!.onNewMessages.listen(_onPollingMessages);

    // Fetch initial messages (only once)
    await loadMessages();
  }
  SimpleFlutterReverb? _reverb;

  /// Initialize Reverb WebSocket for real-time messaging
  void _initReverb(int conversationId) {
    AppFunctions.logPrint(
        message: "📡 Initializing Reverb for conversation: $conversationId");

    // Prevent multiple initializations
    if (_reverb != null) {
      AppFunctions.logPrint(message: "⚠️ Reverb already initialized, skipping");
      return;
    }

    try {
      _reverb = SimpleFlutterReverb();

      _reverb!.listen(
            (data) {
          try {
            // ✅ التأكد من نوع البيانات
            if (data is! WebsocketResponse) {
              AppFunctions.logPrint(
                  message: "⚠️ Invalid data type: ${data.runtimeType}");
              return;
            }

            WebsocketResponse response = data;

            AppFunctions.logPrint(
                message: "🔔 Event Received: ${response.event}");

            if (response.event == 'pusher:connection_established') {
              AppFunctions.logPrint(message: "✅ Reverb connected successfully");
              return;
            }

            if (response.event == 'pusher:subscription_succeeded') {
              AppFunctions.logPrint(
                  message: "✅ Subscribed to channel successfully");
              return;
            }

            if (response.event == 'pusher:ping' ||
                response.event == 'pusher:pong') {
              return;
            }

            if (response.event == "conversations_message") {
              if (response.data == null) {
                AppFunctions.logPrint(message: "⚠️ Message event has no data");
                return;
              }

              _handleReverbMessageEvent(response.data!);
            } else {
              AppFunctions.logPrint(
                  message: "ℹ️ Unhandled event: ${response.event}");
            }
          } catch (e, stackTrace) {
            AppFunctions.logPrint(
                message: "❌ Error processing event: $e\nStack: $stackTrace");
          }
        },
        "conversation_id_$conversationId",
      );

      AppFunctions.logPrint(
          message: "✅ Reverb listener initialized successfully");
    } catch (e, stackTrace) {
      AppFunctions.logPrint(
          message: "❌ Error initializing Reverb: $e\nStack: $stackTrace");


    }
  }

  /// Handle message event from Reverb
  void _handleReverbMessageEvent(Map<String, dynamic>? data) {
    AppFunctions.logPrint(message: "Dattttaaaa reverb : ${data.toString()}");
    if (data == null || data.isEmpty) return;

    try {
      // Check for last_message in data
      if (!data.containsKey('last_message') || data['last_message'] == null) {
        debugPrint('⚠️ No last_message in event data');
        return;
      }

      // Parse the message
      final messageData = data['last_message'] as Map<String, dynamic>;
      final message = Message.fromJson(messageData);

      // Verify conversation ID matches
      final eventConversationId = data['conversation_id'];
      if (eventConversationId != null &&
          _currentConversationId != null &&
          eventConversationId != _currentConversationId) {
        debugPrint('⚠️ Event for different conversation');
        return;
      }

      // Check if message is from visitor (update existing) or agent (add new)
      final isFromVisitor = message.messageType == MessageType.myMessage;

      if (isFromVisitor) {
        // Update existing message sent by visitor
        _updateVisitorMessage(message);
      } else {
        // Add incoming message from agent
        _onNewMessage(message);
      }
    } catch (e) {
      debugPrint('❌ Error handling Reverb message event: $e');
    }
  }

  /// Update a message sent by the visitor (confirmation from server)
  void _updateVisitorMessage(Message updatedMessage) {
    final updatedMessages = state.messages.map((m) {
      // Match by uid or temporary id pattern
      if (m.uId == updatedMessage.uId ||
          (m.messageType == MessageType.myMessage && m.body == updatedMessage.body)) {
        return updatedMessage;
      }
      return m;
    }).toList();

    state = state.copyWith(messages: updatedMessages);

    // Cache messages
    final storage = _ref.read(localStorageProvider);
    storage.cacheMessages(updatedMessages);
  }

  /// Disconnect Reverb
  void _disconnectReverb() {
    try {
      _reverbService?.close();
      _reverbService = null;
      debugPrint('✅ Reverb disconnected');
    } catch (e) {
      debugPrint('❌ Error disconnecting Reverb: $e');
    }
  }

  /// Load messages from server
  Future<void> loadMessages({bool refresh = false}) async {
    // Skip if already loading or if initial load is complete (unless refresh requested)
    if (state.isLoading) return;
    if (_initialLoadComplete && !refresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final chatService = _ref.read(chatServiceProvider);
      final (messages, conversationId) = await chatService.fetchHistory(
        page: refresh ? 1 : state.currentPage,
      );

      // Initialize Reverb WebSocket if we got a conversation ID
      if (conversationId != null) {
        _initReverb(conversationId);
      }

      // API messages come first so they take precedence over cached messages
      final combinedMessages = refresh
          ? messages
          : [...messages, ...state.messages];

      // Deduplicate messages properly (first occurrence wins, so API data takes precedence)
      final newMessages = _deduplicateMessages(combinedMessages);

      // Sort by date (newest first) - parse dates properly
      // newMessages.sort((a, b) {
      //   final dateA = DateTime.tryParse(a.createdAt ?? '');
      //   final dateB = DateTime.tryParse(b.createdAt ?? '');
      //   if (dateA == null && dateB == null) return 0;
      //   if (dateA == null) return 1;
      //   if (dateB == null) return -1;
      //   return dateB.compareTo(dateA);
      // });

      state = state.copyWith(
        messages: newMessages,
        hasMore: messages.length >= 20,
        isLoading: false,
        currentPage: refresh ? 2 : state.currentPage + 1,
      );

      // Mark initial load as complete
      _initialLoadComplete = true;

      // Cache messages
      final storage = _ref.read(localStorageProvider);
      await storage.cacheMessages(newMessages);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final chatService = _ref.read(chatServiceProvider);
      final (messages, _) = await chatService.fetchHistory(
        page: state.currentPage,
      );

      if (messages.isEmpty) {
        state = state.copyWith(hasMore: false, isLoadingMore: false);
        return;
      }

      // API messages first so they take precedence over existing messages
      final newMessages = _deduplicateMessages([...messages, ...state.messages]);

      // Sort by date (newest first) - parse dates properly
      // newMessages.sort((a, b) {
      //   final dateA = DateTime.tryParse(a.createdAt ?? '');
      //   final dateB = DateTime.tryParse(b.createdAt ?? '');
      //   if (dateA == null && dateB == null) return 0;
      //   if (dateA == null) return 1;
      //   if (dateB == null) return -1;
      //   return dateB.compareTo(dateA);
      // });

      state = state.copyWith(
        messages: newMessages,
        hasMore: messages.length >= 20,
        isLoadingMore: false,
        currentPage: state.currentPage + 1,
      );

      // Cache messages
      final storage = _ref.read(localStorageProvider);
      await storage.cacheMessages(newMessages);
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Refresh messages
  Future<void> refresh() async {
    state = state.copyWith(currentPage: 1);
    await loadMessages(refresh: true);
  }

  /// Send a text message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.isSending) return;

    // Create optimistic message
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempMessage = Message(
      id: tempId,
      body: content,
      type: SendMessageType.text,
      messageType: MessageType.myMessage,
      messageStatus: MessageStatus.sending,
      createdAt: DateTime.now().toIso8601String(),
    );

    // Add to state optimistically
    state = state.copyWith(
      messages: [tempMessage, ...state.messages],
      isSending: true,
    );

    try {
      final chatService = _ref.read(chatServiceProvider);
      final sentMessage = await chatService.sendMessage(content);

      // Replace temp message with sent message
      final updatedMessages = state.messages.map((m) {
        return m.id == tempId ? sentMessage : m;
      }).toList();

      state = state.copyWith(
        messages: updatedMessages,
        isSending: false,
      );

      // Initialize Reverb if not already initialized and we have a conversation ID
      // This handles the case when pre-chat form is disabled
      if (_reverb == null && sentMessage.conversationId != null) {
        _initReverb(sentMessage.conversationId!);
      }

      // Cache messages
      final storage = _ref.read(localStorageProvider);
      await storage.cacheMessages(updatedMessages);
    } catch (e) {
      // Mark message as failed
      final updatedMessages = state.messages.map((m) {
        if (m.id == tempId) {
          return Message(
            id: m.id,
            body: m.body,
            type: m.type,
            messageType: m.messageType,
            messageStatus: MessageStatus.failed,
            createdAt: m.createdAt,
            isSendingError: true,
          );
        }
        return m;
      }).toList();

      state = state.copyWith(
        messages: updatedMessages,
        isSending: false,
        error: 'Failed to send message',
      );
    }
  }

  /// Send a message with attachment
  Future<void> sendMessageWithAttachment({
    required String filePath,
    required String fileName,
    String? content,
  }) async {
    if (state.isSending) return;

    // Create optimistic message
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempMessage = Message(
      id: tempId,
      body: content ?? fileName,
      type: SendMessageType.document,
      messageType: MessageType.myMessage,
      messageStatus: MessageStatus.sending,
      createdAt: DateTime.now().toIso8601String(),
      localPath: filePath,
    );

    state = state.copyWith(
      messages: [tempMessage, ...state.messages],
      isSending: true,
    );

    try {
      final chatService = _ref.read(chatServiceProvider);
      final sentMessage = await chatService.sendMessageWithAttachment(
        filePath: filePath,
        fileName: fileName,
        content: content,
      );

      final updatedMessages = state.messages.map((m) {
        return m.id == tempId ? sentMessage : m;
      }).toList();

      state = state.copyWith(
        messages: updatedMessages,
        isSending: false,
      );

      // Initialize Reverb if not already initialized and we have a conversation ID
      // This handles the case when pre-chat form is disabled
      if (_reverb == null && sentMessage.conversationId != null) {
        _initReverb(sentMessage.conversationId!);
      }

      // Cache messages
      final storage = _ref.read(localStorageProvider);
      await storage.cacheMessages(updatedMessages);
    } catch (e) {
      final updatedMessages = state.messages.map((m) {
        if (m.id == tempId) {
          return Message(
            id: m.id,
            body: m.body,
            type: m.type,
            messageType: m.messageType,
            messageStatus: MessageStatus.failed,
            createdAt: m.createdAt,
            isSendingError: true,
          );
        }
        return m;
      }).toList();

      state = state.copyWith(
        messages: updatedMessages,
        isSending: false,
        error: 'Failed to send attachment',
      );
    }
  }

  /// Retry sending a failed message
  Future<void> retryMessage(int messageId) async {
    final message = state.messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => throw StateError('Message not found'),
    );

    if (message.messageStatus != MessageStatus.failed) return;

    // Remove failed message and resend
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != messageId).toList(),
    );

    await sendMessage(message.body ?? '');
  }

  /// Handle new message from WebSocket
  void _onNewMessage(Message message) {
    // Check for duplicates by id or uId
    final isDuplicate = state.messages.any((m) {
      if (message.uId != null && m.uId != null && message.uId == m.uId) return true;
      if (message.id != null && m.id != null && message.id == m.id) return true;
      return false;
    });

    if (isDuplicate) return;

    // Deduplicate after adding
    final newMessages = _deduplicateMessages([message, ...state.messages]);

    // Sort by date (newest first)
    // newMessages.sort((a, b) {
    //   final dateA = DateTime.tryParse(a.createdAt ?? '');
    //   final dateB = DateTime.tryParse(b.createdAt ?? '');
    //   if (dateA == null && dateB == null) return 0;
    //   if (dateA == null) return 1;
    //   if (dateB == null) return -1;
    //   return dateB.compareTo(dateA);
    // });

    state = state.copyWith(messages: newMessages);

    // Increment unread if widget is closed
    _ref.read(widgetStateProvider.notifier).incrementUnread();

    // Cache messages
    final storage = _ref.read(localStorageProvider);
    storage.cacheMessages(newMessages);
  }

  /// Handle messages from polling
  void _onPollingMessages(List<Message> messages) {
    for (final message in messages) {
      _onNewMessage(message);
    }
  }



  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _pollingSubscription?.cancel();
    _disconnectReverb();
    _pollingService?.dispose();
    super.dispose();
  }
}

/// Provider for chat state
final chatStateProvider =
    StateNotifierProvider<ChatStateNotifier, ChatState>((ref) {
  // Keep the provider alive to prevent recreation
  ref.keepAlive();
  return ChatStateNotifier(ref);
});
