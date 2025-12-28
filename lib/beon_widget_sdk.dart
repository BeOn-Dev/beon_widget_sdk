/// Beon Widget SDK - A fully-featured chat widget for Flutter
///
/// This library provides an embeddable chat widget with real-time messaging,
/// visitor persistence, and customizable theming.
///
/// Basic usage:
/// ```dart
/// import 'package:beon_widget_sdk/beon_widget_sdk.dart';
///
/// BeonChatWidget(
///   config: BeonConfig(
///     apiKey: 'your-api-key',
///   ),
/// )
/// ```
///
/// The widget fetches configuration from the API using your API key,
/// including channel settings, pre-chat form fields, colors, and position.

// Core widget
export 'src/ui/beon_chat_widget.dart' show BeonChatWidget;

// Configuration
export 'src/config/beon_config.dart' show BeonConfig, BeonPosition;

// Models (for advanced users)
export 'src/models/message.dart' show Message, MessageType, MessageStatus;
export 'src/models/visitor.dart' show Visitor;
export 'src/models/channel_config.dart'
    show ChannelConfig, ChannelSettings, PreChatFields;

// Theme customization
export 'src/config/beon_theme.dart' show BeonTheme;
