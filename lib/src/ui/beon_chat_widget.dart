import 'package:flutter/material.dart' hide WidgetState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/beon_config.dart';
import '../config/script_loader.dart';
import '../providers/providers.dart';
import '../providers/widget_state.dart';
import '../providers/chat_state.dart';
import 'launcher_button.dart';
import 'chat_window.dart';
import 'pre_chat_form.dart';
import 'components/support_chat_body.dart';
import 'components/support_style.dart';
import 'components/chat_header.dart';

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

  const BeonChatWidget({super.key, this.config});

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
      key: ValueKey(
        '${effectiveConfig.baseUrl}:${effectiveConfig.apiKey}:${effectiveConfig.userId ?? 'visitor'}',
      ),
      overrides: [configProvider.overrideWithValue(effectiveConfig)],
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

class _BeonChatWidgetContentState extends ConsumerState<_BeonChatWidgetContent>
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

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleWindow() {
    ref.read(widgetStateProvider.notifier).toggle();
    if (ref.read(widgetStateProvider).isOpen &&
        ref.read(visitorProvider).hasValue) {
      ref.read(chatStateProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgetState = ref.watch(widgetStateProvider);
    final visitorAsync = ref.watch(visitorProvider);
    final effectiveConfigAsync = ref.watch(effectiveConfigProvider);
    final channelConfigAsync = ref.watch(channelConfigProvider);

    // Handle animation state
    if (widgetState.isOpen && !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!widgetState.isOpen && !_animationController.isDismissed) {
      _animationController.reverse();
    }

    // Check for channel config error (invalid API key, channel not found, etc.)
    if (channelConfigAsync.hasError) {
      return _buildChannelErrorUI(widgetState);
    }

    // Get effective config (with API settings merged)
    final effectiveConfig = effectiveConfigAsync.valueOrNull ?? widget.config;

    // Fullscreen mode - show chat in Scaffold with AppBar
    if (effectiveConfig.fullScreen) {
      final authService = ref.watch(authServiceProvider);

      // Check if pre-chat form should be shown
      // Use authService directly instead of widgetState to avoid timing issues
      final shouldShowPreChat =
          effectiveConfig.preChatFormEnabled && !authService.isPreChatCompleted;

      final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: tablet ? 96 : 64,
          foregroundColor: SupportStyle.ink,
          title: !tablet
              ? ChatHeader(
                  title: effectiveConfig.headerTitle ?? 'Support',
                  subtitle: effectiveConfig.headerSubtitle,
                  primaryColor: effectiveConfig.primaryColor,
                  avatarUrl: effectiveConfig.avatarUrl,
                  locale: effectiveConfig.locale,
                  showClose: false,
                  padding: EdgeInsets.zero,
                  onClose: () {},
                )
              : Text(
                  effectiveConfig.headerTitle ?? 'Chat',
                  style: tablet
                      ? const TextStyle(
                          fontSize: 25,
                          height: 30 / 25,
                          color: Color(0xFF020F15),
                          fontWeight: FontWeight.w500,
                        )
                      : const TextStyle(
                          color: SupportStyle.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        body: effectiveConfigAsync.isLoading
            ? Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(
                    effectiveConfig.primaryColor,
                  ),
                ),
              )
            : visitorAsync.when(
                data: (visitor) {
                  if (shouldShowPreChat) {
                    return const PreChatForm();
                  }
                  return SafeArea(
                    top: false,
                    child: SupportChatBody(config: effectiveConfig),
                  );
                },
                loading: () => Center(
                  child: tablet
                      ? CircularProgressIndicator.adaptive(
                          valueColor: AlwaysStoppedAnimation(
                            effectiveConfig.primaryColor,
                          ),
                        )
                      : const CircularProgressIndicator(),
                ),
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
              onPressed: _toggleWindow,
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

  /// Build error UI when channel config fails to load
  Widget _buildChannelErrorUI(WidgetState widgetState) {
    // For fullscreen mode, show error in Scaffold
    if (widget.config.fullScreen) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Chat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: widget.config.primaryColor,
          elevation: 0,
          centerTitle: true,
        ),
        body: const _ChannelErrorWidget(),
      );
    }

    // For normal mode, show error in positioned container
    return SizedBox.expand(
      child: Stack(
        children: [
          if (widgetState.isOpen)
            Positioned(
              right: _isRightPositioned(widget.config) ? 16.0 : null,
              left: _isRightPositioned(widget.config) ? null : 16.0,
              bottom: 80.0,
              child: const _ChannelErrorWidget(),
            ),
          Positioned(
            right: _isRightPositioned(widget.config) ? 16.0 : null,
            left: _isRightPositioned(widget.config) ? null : 16.0,
            bottom: 16.0,
            child: LauncherButton(
              isOpen: widgetState.isOpen,
              onPressed: _toggleWindow,
              primaryColor: widget.config.primaryColor,
              unreadCount: 0,
            ),
          ),
        ],
      ),
    );
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
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(child: CircularProgressIndicator()),
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
            color: Colors.black.withValues(alpha: 0.15),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text('Please try again later', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ChannelErrorWidget extends StatelessWidget {
  const _ChannelErrorWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
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
              'Configuration Error',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Invalid API key or channel not found.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              'Please contact support.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
