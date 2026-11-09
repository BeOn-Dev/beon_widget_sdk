import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../providers/widget_state.dart';
import 'components/chat_header.dart';
import 'components/support_chat_body.dart';

class ChatWindow extends ConsumerWidget {
  final String visitorId;
  const ChatWindow({super.key, required this.visitorId});
  void _close(WidgetRef ref) => ref.read(widgetStateProvider.notifier).close();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseConfig = ref.watch(configProvider);
    final config = ref.watch(effectiveConfigProvider).valueOrNull ?? baseConfig;
    final theme = ref.watch(themeProvider);
    final size = MediaQuery.sizeOf(context);
    return Container(
      width: config.fullScreen
          ? size.width
          : theme.windowWidth.clamp(0, size.width - 32),
      height: config.fullScreen
          ? size.height
          : theme.windowHeight.clamp(0, size.height - 112),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: config.fullScreen
            ? BorderRadius.zero
            : theme.windowBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          ChatHeader(
            title: config.headerTitle ?? 'Support',
            subtitle: config.headerSubtitle,
            primaryColor: config.primaryColor,
            avatarUrl: config.avatarUrl,
            locale: config.locale,
            onClose: () => _close(ref),
          ),
          Expanded(child: SupportChatBody(config: config)),
        ],
      ),
    );
  }
}
