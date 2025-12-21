import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'chat_state.dart';

/// Current view of the widget
enum WidgetView {
  launcher, // Just showing the launcher button
  preChat, // Showing pre-chat form
  chat, // Showing chat window
}

/// State of the widget UI
@immutable
class WidgetState {
  final bool isOpen;
  final WidgetView currentView;
  final bool isAnimating;
  final int unreadCount;

  const WidgetState({
    this.isOpen = false,
    this.currentView = WidgetView.launcher,
    this.isAnimating = false,
    this.unreadCount = 0,
  });

  WidgetState copyWith({
    bool? isOpen,
    WidgetView? currentView,
    bool? isAnimating,
    int? unreadCount,
  }) {
    return WidgetState(
      isOpen: isOpen ?? this.isOpen,
      currentView: currentView ?? this.currentView,
      isAnimating: isAnimating ?? this.isAnimating,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WidgetState &&
        other.isOpen == isOpen &&
        other.currentView == currentView &&
        other.isAnimating == isAnimating &&
        other.unreadCount == unreadCount;
  }

  @override
  int get hashCode {
    return Object.hash(isOpen, currentView, isAnimating, unreadCount);
  }
}

/// Notifier for managing widget state
class WidgetStateNotifier extends StateNotifier<WidgetState> {
  final Ref _ref;

  WidgetStateNotifier(this._ref) : super(const WidgetState());

  /// Initialize for fullscreen mode - sets correct initial view
  void initFullScreen() {
    final config = _ref.read(configProvider);
    final authService = _ref.read(authServiceProvider);

    // Determine which view to show
    WidgetView view;
    if (config.preChatFormEnabled && !authService.isPreChatCompleted) {
      view = WidgetView.preChat;
    } else {
      view = WidgetView.chat;
    }

    state = state.copyWith(
      isOpen: true,
      currentView: view,
    );
  }

  /// Toggle widget open/closed
  void toggle() {
    if (state.isOpen) {
      close();
    } else {
      open();
    }
  }

  /// Open the widget
  void open() {
    final config = _ref.read(configProvider);
    final authService = _ref.read(authServiceProvider);

    // Determine which view to show
    WidgetView view;
    if (config.preChatFormEnabled && !authService.isPreChatCompleted) {
      view = WidgetView.preChat;
    } else {
      view = WidgetView.chat;
      // Refresh messages when opening chat view
      _ref.read(chatStateProvider.notifier).refresh();
    }

    state = state.copyWith(
      isOpen: true,
      currentView: view,
      isAnimating: true,
      unreadCount: 0, // Clear unread when opening
    );
  }

  /// Close the widget
  void close() {
    state = state.copyWith(
      isOpen: false,
      isAnimating: true,
    );
  }

  /// Navigate to chat view
  void goToChat() {
    state = state.copyWith(currentView: WidgetView.chat);
  }

  /// Navigate to pre-chat form
  void goToPreChat() {
    state = state.copyWith(currentView: WidgetView.preChat);
  }

  /// Mark animation as complete
  void animationComplete() {
    state = state.copyWith(isAnimating: false);
  }

  /// Increment unread count
  void incrementUnread() {
    if (!state.isOpen) {
      state = state.copyWith(unreadCount: state.unreadCount + 1);
    }
  }

  /// Clear unread count
  void clearUnread() {
    state = state.copyWith(unreadCount: 0);
  }

  /// Set unread count directly
  void setUnreadCount(int count) {
    state = state.copyWith(unreadCount: count);
  }
}

/// Provider for widget state
final widgetStateProvider =
    StateNotifierProvider<WidgetStateNotifier, WidgetState>((ref) {
  return WidgetStateNotifier(ref);
});
