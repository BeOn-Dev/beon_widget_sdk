import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/beon_config.dart';
import '../../models/message.dart';
import '../../providers/chat_state.dart';
import 'message_input.dart';
import 'powered_by_footer.dart';
import 'support_conversation.dart';
import 'support_style.dart';
import 'support_tabs.dart';
import 'support_tickets.dart';

/// Shared chat experience in a host route or an SDK floating window.
class SupportChatBody extends ConsumerStatefulWidget {
  final BeonConfig config;
  const SupportChatBody({super.key, required this.config});
  @override
  ConsumerState<SupportChatBody> createState() => _SupportChatBodyState();
}

class _SupportChatBodyState extends ConsumerState<SupportChatBody> {
  bool _tickets = false;
  bool _ticketsOpened = false;
  void _selectTab(bool tickets) {
    FocusScope.of(context).unfocus();
    setState(() {
      _tickets = tickets;
      _ticketsOpened = _ticketsOpened || tickets;
    });
  }

  void _startChat() => _selectTab(false);
  void _send(String text) =>
      ref.read(chatStateProvider.notifier).sendMessage(text);
  void _attach(String path, String name, SendMessageType type) => ref
      .read(chatStateProvider.notifier)
      .sendMessageWithAttachment(filePath: path, fileName: name, type: type);
  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final state = ref.watch(chatStateProvider);
    final messages = state.messages
        .where(
          (m) =>
              m.type != SendMessageType.note && m.type != SendMessageType.info,
        )
        .toList();
    final hasConversation =
        state.conversationId != null ||
        messages.any(
          (m) =>
              m.messageStatus != MessageStatus.failed &&
              m.messageStatus != MessageStatus.sending,
        );
    final ticketsVisible = config.ticketsEnabled == true;
    return ColoredBox(
      color: SupportStyle.background,
      child: Column(
        children: [
          if (ticketsVisible)
            SupportTabs(
              ticketsSelected: _tickets,
              onChanged: _selectTab,
              locale: config.locale,
            ),
          Expanded(
            child: IndexedStack(
              index: _tickets && ticketsVisible ? 1 : 0,
              children: [
                Column(
                  children: [
                    Expanded(child: SupportConversation(config: config)),
                    MessageInput(
                      onSend: _send,
                      onAttachment: _attach,
                      isSending: state.isSending,
                      primaryColor: config.primaryColor,
                      locale: config.locale,
                    ),
                  ],
                ),
                if (_ticketsOpened && ticketsVisible)
                  SupportTickets(
                    config: config,
                    hasConversation: hasConversation,
                    conversationId: state.conversationId,
                    onStartChat: _startChat,
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
          if (MediaQuery.viewInsetsOf(context).bottom == 0)
            PoweredByFooter(locale: config.locale),
        ],
      ),
    );
  }
}
