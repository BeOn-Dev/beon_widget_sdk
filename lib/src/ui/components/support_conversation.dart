import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/beon_config.dart';
import '../../models/message.dart';
import '../../providers/chat_state.dart';
import 'message_widget/message_widget.dart';
import 'support_style.dart';
import 'support_welcome_card.dart';

class SupportConversation extends ConsumerStatefulWidget {
  final BeonConfig config;
  const SupportConversation({super.key, required this.config});
  @override
  ConsumerState<SupportConversation> createState() =>
      _SupportConversationState();
}

class _SupportConversationState extends ConsumerState<SupportConversation> {
  final _scroll = ScrollController();
  int _messageCount = 0;
  bool _loadingOlder = false;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.hasClients &&
        _scroll.position.pixels < 80 &&
        _scroll.position.maxScrollExtent > 0 &&
        !_loadingOlder) {
      _loadOlder();
    }
  }

  Future<void> _loadOlder() async {
    _loadingOlder = true;
    final pixels = _scroll.position.pixels;
    final extent = _scroll.position.maxScrollExtent;
    await ref.read(chatStateProvider.notifier).loadMore();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        final target = pixels + _scroll.position.maxScrollExtent - extent;
        _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
      }
      _loadingOlder = false;
    });
  }

  void _reply(String text) =>
      ref.read(chatStateProvider.notifier).sendMessage(text);
  void _retryMessage(Message message) {
    if (message.id != null) {
      ref.read(chatStateProvider.notifier).retryMessage(message.id!);
    }
  }

  void _retry() => ref.read(chatStateProvider.notifier).refresh();
  String _date(DateTime date, SupportStrings s) {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    if (day == DateTime(now.year, now.month, now.day)) {
      return s.text('Today', 'اليوم');
    }
    if (day ==
        DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 1))) {
      return s.text('Yesterday', 'أمس');
    }
    return DateFormat.yMMMd(s.arabic ? 'ar' : 'en').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatStateProvider);
    final s = SupportStrings(widget.config.locale);
    final messages = state.messages
        .where(
          (m) =>
              !m.isPrivate &&
              m.type != SendMessageType.note &&
              m.type != SendMessageType.info,
        )
        .toList()
        .reversed
        .toList();
    if (_messageCount != messages.length) {
      final shouldScroll =
          !_loadingOlder &&
          (!_scroll.hasClients || _scroll.position.extentAfter < 100);
      _messageCount = messages.length;
      if (shouldScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });
      }
    }
    if (state.isLoading && messages.isEmpty) {
      return Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation(widget.config.primaryColor),
        ),
      );
    }
    if (state.error != null && messages.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: _retry,
          child: Text(
            s.text(
              'Unable to load messages. Retry',
              'تعذر تحميل الرسائل. إعادة المحاولة',
            ),
          ),
        ),
      );
    }
    return ListView(
      controller: _scroll,
      children: [
        SupportWelcomeCard(
          title: widget.config.headerTitle ?? s.text('Support', 'الدعم الفني'),
          message: widget.config.welcomeMessage ?? s.welcome,
        ),
        if (messages.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: MessageBubble(
                isMyMessage: false,
                primaryColor: widget.config.primaryColor,
                message: Message(
                  body: widget.config.welcomeMessage ?? s.welcome,
                  type: SendMessageType.text,
                  messageType: MessageType.clientMessage,
                ),
              ),
            ),
          ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator.adaptive()),
          ),
        for (var index = 0; index < messages.length; index++) ...[
          if (_showDate(messages, index))
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: SupportStyle.input,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _date(
                    DateTime.parse(messages[index].createdAt!).toLocal(),
                    s,
                  ),
                  style: const TextStyle(
                    fontSize: 10,
                    color: SupportStyle.muted,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: messages[index].messageType == MessageType.myMessage
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: MessageBubble(
                isMyMessage:
                    messages[index].messageType == MessageType.myMessage,
                message: messages[index],
                locale: widget.config.locale,
                onReply: _reply,
                actionsEnabled: !state.isSending,
                primaryColor: widget.config.primaryColor,
              ),
            ),
          ),
          if (messages[index].messageStatus == MessageStatus.failed)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: state.isSending
                    ? null
                    : () => _retryMessage(messages[index]),
                child: Text(s.retry),
              ),
            ),
        ],
        if (state.error != null && state.error != 'send' && messages.isNotEmpty)
          TextButton(
            onPressed: _retry,
            child: Text(
              s.text('Unable to send. Retry', 'تعذر الإرسال. إعادة المحاولة'),
            ),
          ),
      ],
    );
  }

  bool _showDate(List<Message> messages, int index) {
    final current = DateTime.tryParse(
      messages[index].createdAt ?? '',
    )?.toLocal();
    if (current == null) return false;
    if (index == 0) return true;
    final previous = DateTime.tryParse(
      messages[index - 1].createdAt ?? '',
    )?.toLocal();
    return previous == null ||
        current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }
}
