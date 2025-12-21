import 'package:beon_widget_sdk/src/utils/app_colors.dart';
import 'package:beon_widget_sdk/src/utils/app_functions/app_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/beon_config.dart';
import '../config/beon_theme.dart';
import '../config/script_loader.dart';
import '../models/message.dart';
import '../providers/providers.dart';
import '../providers/chat_state.dart';
import '../providers/widget_state.dart';
import 'launcher_button.dart';
import 'chat_window.dart';
import 'pre_chat_form.dart';
import 'components/message_widget/message_widget.dart';
import 'components/message_input.dart';
import 'components/powered_by_footer.dart';

/// The main Beon Chat Widget that can be embedded in any Flutter app.
///
/// Usage with configuration:
/// ```dart
/// BeonChatWidget(
///   config: BeonConfig(
///     apiKey: 'your-api-key',
///     widgetId: 'your-widget-id',
///   ),
/// )
/// ```
///
/// Usage for web embedding (reads config from script tag):
/// ```dart
/// BeonChatWidget.fromScriptTag()
/// ```
class BeonChatWidget extends StatelessWidget {
  final BeonConfig? config;


  const BeonChatWidget({
    super.key,
    this.config,
  });

  /// Create widget that reads configuration from HTML script tag
  factory BeonChatWidget.fromScriptTag() {
    return const BeonChatWidget();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = config ?? ScriptLoader.loadFromDOM();

    if (effectiveConfig == null) {
      // No configuration found, render nothing
      return const SizedBox.shrink();
    }

    if (effectiveConfig.apiKey.isEmpty) {
      // Invalid configuration
      return const SizedBox.shrink();
    }

    return ProviderScope(
      overrides: [
        configProvider.overrideWithValue(effectiveConfig),
      ],
      child: Directionality(
        textDirection: effectiveConfig.textDirection,
        child: _BeonChatWidgetContent(config: effectiveConfig),
      ),
    );
  }
}

class _BeonChatWidgetContent extends ConsumerStatefulWidget {
  final BeonConfig config;

  const _BeonChatWidgetContent({required this.config});

  @override
  ConsumerState<_BeonChatWidgetContent> createState() =>
      _BeonChatWidgetContentState();
}

class _BeonChatWidgetContentState
    extends ConsumerState<_BeonChatWidgetContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widgetState = ref.watch(widgetStateProvider);
    final visitorAsync = ref.watch(visitorProvider);
    final effectiveConfigAsync = ref.watch(effectiveConfigProvider);

    // Handle animation state
    if (widgetState.isOpen && !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!widgetState.isOpen && !_animationController.isDismissed) {
      _animationController.reverse();
    }

    // Get effective config (with API settings merged)
    final effectiveConfig = effectiveConfigAsync.valueOrNull ?? widget.config;

    // Fullscreen mode - show chat in Scaffold with AppBar
    if (effectiveConfig.fullScreen) {
      final authService = ref.watch(authServiceProvider);

      // Check if pre-chat form should be shown
      // Use authService directly instead of widgetState to avoid timing issues
      final shouldShowPreChat = effectiveConfig.preChatFormEnabled &&
                                !authService.isPreChatCompleted;

      return Scaffold(
        appBar: AppBar(
          title: Text(
            effectiveConfig.headerTitle ?? 'Chat',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: effectiveConfig.primaryColor,
          elevation: 0,
          centerTitle: true,
        ),
        body: visitorAsync.when(
          data: (visitor) {
            if (shouldShowPreChat) {
              return const PreChatForm();
            }
            return _FullScreenChatBody(visitorId: visitor.id);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _ErrorWidget(),
        ),
      );
    }

    // Normal mode with launcher button
    return SizedBox.expand(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              if (_animationController.value == 0) {
                return const SizedBox.shrink();
              }

              return Positioned(
                right: _isRightPositioned(effectiveConfig) ? 16.0 : null,
                left: _isRightPositioned(effectiveConfig) ? null : 16.0,
                bottom: 80.0,
                child: FadeTransition(
                  opacity: _scaleAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      alignment: _isRightPositioned(effectiveConfig)
                          ? Alignment.bottomRight
                          : Alignment.bottomLeft,
                      child: visitorAsync.when(
                        data: (visitor) {
                          if (widgetState.currentView == WidgetView.preChat &&
                              effectiveConfig.preChatFormEnabled) {
                            return const PreChatForm();
                          }
                          return ChatWindow(visitorId: visitor.id);
                        },
                        loading: () => const _LoadingWidget(),
                        error: (_, __) => const _ErrorWidget(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Launcher button
          Positioned(
            right: _isRightPositioned(effectiveConfig) ? 16.0 : null,
            left: _isRightPositioned(effectiveConfig) ? null : 16.0,
            bottom: 16.0,
            child: LauncherButton(
              isOpen: widgetState.isOpen,
              onPressed: () => ref.read(widgetStateProvider.notifier).toggle(),
              primaryColor: effectiveConfig.primaryColor,
              unreadCount: widgetState.unreadCount,
            ),
          ),
        ],
      ),
    );
  }

  bool _isRightPositioned(BeonConfig config) {
    return config.position == BeonPosition.bottomRight ||
        config.position == BeonPosition.topRight;
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Unable to load chat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Fullscreen chat body without header (header is in AppBar)
class _FullScreenChatBody extends ConsumerWidget {
  final String visitorId;

  const _FullScreenChatBody({required this.visitorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatStateProvider);
    final theme = ref.watch(themeProvider);

    return Column(
      children: [
        // Messages area
        Expanded(
          child: _buildMessageArea(context, ref, chatState, theme),
        ),

        // Input area
        MessageInput(
          onSend: (content) {
            ref.read(chatStateProvider.notifier).sendMessage(content);
          },
          isSending: chatState.isSending,
          primaryColor: theme.primaryColor,
        ),

        const PoweredByFooter(),
      ],
    );
  }

  Widget _buildMessageArea(
    BuildContext context,
    WidgetRef ref,
    ChatState chatState,
    BeonTheme theme,
  ) {
    if (chatState.isLoading && chatState.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
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
                'Start a conversation',
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

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chatState.messages.length + (chatState.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
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
        final isMyMessage = message.messageType == MessageType.myMessage;

        return Padding(
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
        );
      },
    );
  }
}
