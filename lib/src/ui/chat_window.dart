import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../providers/widget_state.dart';
import '../providers/chat_state.dart';
import '../models/message.dart';
import 'components/chat_header.dart';
import 'components/message_widget/message_widget.dart';
import 'components/message_input.dart';
import 'components/powered_by_footer.dart';

/// The main chat window showing messages and input
class ChatWindow extends ConsumerStatefulWidget {
  final String visitorId;

  const ChatWindow({
    super.key,
    required this.visitorId,
  });

  @override
  ConsumerState<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends ConsumerState<ChatWindow> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when scrolled near the top (since list is reversed)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatStateProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider);
    final theme = ref.watch(themeProvider);
    final chatState = ref.watch(chatStateProvider);
    final screenSize = MediaQuery.of(context).size;

    // Use full screen dimensions if fullScreen is enabled
    final windowWidth = config.fullScreen ? screenSize.width : theme.windowWidth;
    final windowHeight = config.fullScreen ? screenSize.height : theme.windowHeight;
    final borderRadius = config.fullScreen
        ? BorderRadius.zero
        : theme.windowBorderRadius;

    return Container(
      width: windowWidth,
      height: windowHeight,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: borderRadius,
        boxShadow: config.fullScreen ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          ChatHeader(
            title: config.headerTitle ?? 'Chat',
            subtitle: config.headerSubtitle ?? 'How can we help you?',
            primaryColor: theme.primaryColor,
            onClose: () => ref.read(widgetStateProvider.notifier).close(),
          ),

          // Messages area
          Expanded(
            child: _buildMessageArea(chatState),
          ),

          // Input area
          MessageInput(
            onSend: (content) {
              ref.read(chatStateProvider.notifier).sendMessage(content);
            },
            // onAttachment: (filePath, fileName) {
            //   ref.read(chatStateProvider.notifier).sendMessageWithAttachment(
            //         filePath: filePath,
            //         fileName: fileName,
            //       );
            // },
            isSending: chatState.isSending,
            primaryColor: theme.primaryColor,
          ),

          const PoweredByFooter(),
        ],
      ),
    );
  }

  Widget _buildMessageArea(ChatState chatState) {
    if (chatState.isLoading && chatState.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (chatState.error != null && chatState.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Unable to load messages',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.read(chatStateProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (chatState.messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chatState.messages.length + (chatState.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the end (top of chat)
        if (chatState.isLoadingMore && index == chatState.messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final message = chatState.messages[index];
        final showDate = _shouldShowDate(chatState.messages, index);
        final isMyMessage = message.messageType == MessageType.myMessage;

        return Column(
          children: [
            if (showDate) _buildDateSeparator(message.createdAt),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: isMyMessage
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: MessageBubble(
                  isMyMessage: isMyMessage,
                  message: message,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final config = ref.watch(configProvider);
    final theme = ref.watch(themeProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 32,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              config.welcomeMessage ?? 'Start a conversation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(String? dateStr) {
    final date = _parseDate(dateStr);
    if (date == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  bool _shouldShowDate(List<Message> messages, int index) {
    if (index == messages.length - 1) return true;

    final current = messages[index];
    final next = messages[index + 1];

    final currentDate = _parseDate(current.createdAt);
    final nextDate = _parseDate(next.createdAt);

    if (currentDate == null || nextDate == null) return false;
    return !_isSameDay(currentDate, nextDate);
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
