import 'dart:async';
import '../../models/message.dart';
import 'chat_service.dart';

/// Fallback polling service when WebSocket is unavailable
class PollingService {
  final ChatService _chatService;
  final Duration interval;

  Timer? _timer;
  String? _lastMessageTimeStr;
  bool _isPolling = false;

  final _messageController = StreamController<List<Message>>.broadcast();

  /// Stream of new messages from polling
  Stream<List<Message>> get onNewMessages => _messageController.stream;

  /// Check if polling is active
  bool get isActive => _isPolling;

  PollingService(
    this._chatService, {
    this.interval = const Duration(seconds: 5),
  });

  /// Start polling for new messages
  void start() {
    if (_isPolling) return;

    _isPolling = true;
    _poll(); // Initial poll
    _timer = Timer.periodic(interval, (_) => _poll());
  }

  /// Stop polling
  void stop() {
    _isPolling = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Perform a single poll
  Future<void> _poll() async {
    if (!_isPolling) return;

    try {
      final lastTime = _lastMessageTimeStr != null
          ? DateTime.tryParse(_lastMessageTimeStr!)
          : null;

      final (messages, _) = await _chatService.fetchHistory(
        limit: 10,
        before: lastTime,
      );

      if (messages.isNotEmpty) {
        // Filter out messages we've already seen
        final newMessages = _lastMessageTimeStr == null
            ? messages
            : messages.where((m) {
                final msgTime = m.createdAt != null ? DateTime.tryParse(m.createdAt!) : null;
                final lastParsed = DateTime.tryParse(_lastMessageTimeStr!);
                if (msgTime == null || lastParsed == null) return true;
                return msgTime.isAfter(lastParsed);
              }).toList();



        if (newMessages.isNotEmpty) {
          _lastMessageTimeStr = newMessages.first.createdAt;
          _messageController.add(newMessages);
        }
      }
    } catch (e) {
      // Silent fail, retry on next interval
    }
  }

  /// Force an immediate poll
  Future<void> pollNow() async {
    await _poll();
  }

  /// Reset last message time
  void reset() {
    _lastMessageTimeStr = null;
  }

  /// Dispose resources
  void dispose() {
    stop();
    _messageController.close();
  }
}
