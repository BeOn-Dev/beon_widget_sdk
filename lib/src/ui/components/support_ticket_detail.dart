import 'package:flutter/material.dart';
import '../../providers/ticket_state.dart';
import 'support_style.dart';
import 'support_input_style.dart';

class SupportTicketDetail extends StatefulWidget {
  final TicketState state;
  final SupportStrings strings;
  final Color primaryColor;
  final VoidCallback onBack;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;
  final Future<bool> Function(String) onSend;
  const SupportTicketDetail({
    super.key,
    required this.state,
    required this.strings,
    required this.primaryColor,
    required this.onBack,
    required this.onLoadMore,
    required this.onRetry,
    required this.onSend,
  });
  @override
  State<SupportTicketDetail> createState() => _SupportTicketDetailState();
}

class _SupportTicketDetailState extends State<SupportTicketDetail> {
  final _reply = TextEditingController();
  final _scroll = ScrollController();
  double? _olderExtent;
  double? _olderPixels;
  @override
  void didUpdateWidget(covariant SupportTicketDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final loadingFinished =
        oldWidget.state.loadingMore && !widget.state.loadingMore;
    final messagesChanged =
        oldWidget.state.replies.length != widget.state.replies.length;
    if (!loadingFinished && !messagesChanged) return;
    final scrollToBottom =
        !_scroll.hasClients || _scroll.position.extentAfter < 100;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (_olderExtent != null) {
        final offset =
            _olderPixels! + _scroll.position.maxScrollExtent - _olderExtent!;
        _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
        _olderExtent = null;
        _olderPixels = null;
      } else if (scrollToBottom) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _loadMore() {
    if (_scroll.hasClients) {
      _olderExtent = _scroll.position.maxScrollExtent;
      _olderPixels = _scroll.position.pixels;
    }
    widget.onLoadMore();
  }

  @override
  void dispose() {
    _reply.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty || widget.state.submitting) return;
    if (await widget.onSend(text) && mounted) _reply.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final s = widget.strings;
    final ticket = state.selected!;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              BackButton(onPressed: widget.onBack),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '#${ticket.id}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: SupportStyle.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.loading
              ? Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(widget.primaryColor),
                  ),
                )
              : ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (state.hasMoreReplies)
                      TextButton(
                        onPressed: state.loadingMore ? null : _loadMore,
                        child: Text(
                          s.text(
                            'Load older messages',
                            'تحميل الرسائل السابقة',
                          ),
                        ),
                      ),
                    if (state.loadingMore)
                      const Center(child: CircularProgressIndicator.adaptive()),
                    if (ticket.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          ticket.description,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: SupportStyle.muted,
                          ),
                        ),
                      ),
                    for (final reply in state.replies)
                      Align(
                        alignment: reply.fromAgent
                            ? AlignmentDirectional.centerStart
                            : AlignmentDirectional.centerEnd,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: reply.fromAgent
                                ? Colors.white
                                : widget.primaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [SupportStyle.shadow],
                          ),
                          child: Text(
                            reply.content,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: reply.fromAgent
                                  ? SupportStyle.ink
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        if (state.error != null)
          TextButton(
            onPressed: widget.onRetry,
            child: Text(
              s.text('Something went wrong. Retry', 'حدث خطأ. إعادة المحاولة'),
            ),
          ),
        if (ticket.isClosed)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              s.text('This ticket is closed', 'هذه التذكرة مغلقة'),
              style: const TextStyle(color: SupportStyle.muted),
            ),
          )
        else
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _reply,
                    style: SupportInputStyle.text,
                    minLines: 1,
                    maxLines: 4,
                    enabled: !state.submitting,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: SupportInputStyle.decoration(
                      primaryColor: widget.primaryColor,
                      hintText: s.messageHint,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: state.submitting ? null : _send,
                  tooltip: s.send,
                  icon: state.submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.send_outlined,
                          color: widget.primaryColor,
                          textDirection: Directionality.of(context),
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
