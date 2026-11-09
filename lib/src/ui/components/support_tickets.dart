import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/beon_config.dart';
import '../../providers/ticket_state.dart';
import 'support_style.dart';
import 'support_ticket_form.dart';
import 'support_ticket_detail.dart';
import 'support_ticket_list_item.dart';

class SupportTickets extends ConsumerStatefulWidget {
  final BeonConfig config;
  final bool hasConversation;
  final int? conversationId;
  final VoidCallback onStartChat;
  const SupportTickets({
    super.key,
    required this.config,
    required this.hasConversation,
    this.conversationId,
    required this.onStartChat,
  });
  @override
  ConsumerState<SupportTickets> createState() => _SupportTicketsState();
}

class _SupportTicketsState extends ConsumerState<SupportTickets> {
  bool _creating = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void didUpdateWidget(covariant SupportTickets oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasConversation != widget.hasConversation ||
        oldWidget.conversationId != widget.conversationId) {
      Future.microtask(_load);
    }
  }

  TicketStateNotifier get _notifier =>
      ref.read(ticketStateProvider(widget.conversationId).notifier);
  void _load() {
    if (mounted && widget.hasConversation) _notifier.load();
  }

  void _filter(String filter) {
    if (widget.hasConversation) {
      _notifier.load(filter: filter);
    } else {
      _notifier.selectFilter(filter);
    }
  }

  void _create() {
    if (!widget.hasConversation) {
      widget.onStartChat();
      return;
    }
    setState(() => _creating = true);
  }

  void _back() {
    setState(() => _creating = false);
    _notifier.back();
  }

  Future<bool> _submit(
    String category,
    String subject,
    String description,
  ) async {
    final success = await _notifier.create(
      categoryId: category,
      subject: subject,
      description: description,
    );
    if (success && mounted) setState(() => _creating = false);
    return success;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ticketStateProvider(widget.conversationId));
    final s = SupportStrings(widget.config.locale);
    final color = widget.config.primaryColor;
    if (_creating) {
      return Column(
        children: [
          Expanded(
            child: SupportTicketForm(
              categories: widget.config.ticketCategories,
              strings: s,
              primaryColor: color,
              submitting: state.submitting,
              onBack: _back,
              onSubmit: _submit,
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                s.text(
                  'Unable to create ticket. Please try again.',
                  'تعذر إنشاء التذكرة. يرجى المحاولة مرة أخرى.',
                ),
              ),
            ),
        ],
      );
    }
    if (state.selected != null) {
      return SupportTicketDetail(
        state: state,
        strings: s,
        primaryColor: color,
        onBack: _back,
        onLoadMore: _notifier.loadMoreReplies,
        onRetry: () => _notifier.open(state.selected!),
        onSend: _notifier.send,
      );
    }
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: SupportStyle.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    children: [
                      for (final filter in ['all', 'open', 'closed'])
                        TextButton(
                          onPressed: () => _filter(filter),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            backgroundColor: state.filter == filter
                                ? Colors.white
                                : Colors.transparent,
                            foregroundColor: state.filter == filter
                                ? SupportStyle.ink
                                : SupportStyle.muted,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            '${filter == 'all'
                                ? s.text('All', 'الكل')
                                : filter == 'open'
                                ? s.text('Open', 'المفتوحة')
                                : s.text('Closed', 'المغلقة')}${state.page.counts.containsKey(filter)
                                ? ' (${state.page.counts[filter]})'
                                : filter == state.filter
                                ? ' (${state.page.records.length})'
                                : ''}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    widget.hasConversation
                        ? Icons.add
                        : Icons.chat_bubble_outline,
                    size: 14,
                  ),
                  label: Text(
                    widget.hasConversation ? s.newTicket : s.firstChat,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.loading
              ? Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                )
              : state.error != null
              ? Center(
                  child: TextButton(
                    onPressed: _load,
                    child: Text(
                      s.text(
                        'Unable to load tickets. Retry',
                        'تعذر تحميل التذاكر. إعادة المحاولة',
                      ),
                    ),
                  ),
                )
              : state.page.records.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.hasConversation
                              ? s.text('No tickets yet', 'لا توجد تذاكر بعد')
                              : s.noConversation,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: SupportStyle.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.hasConversation
                              ? s.text(
                                  'Create a support ticket and our team will help you.',
                                  'أنشئ تذكرة دعم فني وسيساعدك فريقنا.',
                                )
                              : s.conversationRequired,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.7,
                            color: SupportStyle.muted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _create,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.hasConversation ? s.newTicket : s.startChat,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    for (final ticket in state.page.records)
                      SupportTicketListItem(
                        ticket: ticket,
                        strings: s,
                        onTap: () => _notifier.open(ticket),
                      ),
                    if (state.page.hasMore)
                      TextButton(
                        onPressed: state.loadingMore
                            ? null
                            : () => _notifier.load(more: true),
                        child: Text(s.text('Load more', 'تحميل المزيد')),
                      ),
                    if (state.loadingMore)
                      const Center(child: CircularProgressIndicator.adaptive()),
                  ],
                ),
        ),
      ],
    );
  }
}
