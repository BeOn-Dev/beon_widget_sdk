import 'package:flutter/material.dart';

/// Widget position on the screen
enum BeonPosition {
  bottomRight,
  bottomLeft,
  topRight,
  topLeft,
}

/// Configuration for the Beon Chat Widget
///
/// Required fields:
/// - [apiKey]: Your Beon API key (used to fetch widget configuration from API)
///
/// Optional customization (can be overridden by API response):
/// - [primaryColor]: Primary theme color (default: from API or cyan)
/// - [position]: Widget position on screen (default: from API or bottomRight)
/// - [welcomeMessage]: Initial welcome message to display (default: from API)
/// - [enableSounds]: Enable notification sounds (default: true)
/// - [enablePollingFallback]: Fall back to polling if WebSocket fails (default: false)
/// - [preChatFormEnabled]: Show pre-chat form (default: from API)
class BeonConfig {
  final String apiKey;
  final int? channelId;
  final Color primaryColor;
  final BeonPosition position;
  final String? externalUserId;
  final String? welcomeMessage;
  final bool enableSounds;
  final bool enablePollingFallback;
  final Duration pollingInterval;
  final String locale;
  final TextDirection textDirection;
  final String baseUrl;
  final String wsUrl;
  final String widgetVersion;
  final bool preChatFormEnabled;
  final String? headerTitle;
  final String? headerSubtitle;
  final bool preChatNameEnabled;
  final bool preChatEmailEnabled;
  final bool preChatPhoneEnabled;
  final bool preChatMessageEnabled;
  final bool fullScreen;

  const BeonConfig({
    required this.apiKey,
    this.channelId,
    this.primaryColor = const Color(0xFF00BCD4),
    this.position = BeonPosition.bottomRight,
    this.externalUserId,
    this.welcomeMessage,
    this.enableSounds = true,
    this.enablePollingFallback = false,
    this.pollingInterval = const Duration(seconds: 5),
    this.locale = 'en',
    this.textDirection = TextDirection.ltr,
    this.baseUrl = 'https://v3.api.beon.chat/api/widget/v5',
    this.wsUrl = 'wss://v3.api.beon.chat',
    this.widgetVersion = '1.0.0',
    this.preChatFormEnabled = true,
    this.headerTitle,
    this.headerSubtitle,
    this.preChatNameEnabled = true,
    this.preChatEmailEnabled = false,
    this.preChatPhoneEnabled = true,
    this.preChatMessageEnabled = true,
    this.fullScreen = false,
  });

  /// Create config from a map (useful for parsing script tag attributes)
  factory BeonConfig.fromMap(Map<String, String?> map) {
    return BeonConfig(
      apiKey: map['apiKey'] ?? '',
      primaryColor: _parseColor(map['primaryColor']),
      position: _parsePosition(map['position']),
      externalUserId: map['externalUserId'],
      welcomeMessage: map['welcomeMessage'],
      enableSounds: map['enableSounds'] != 'false',
      textDirection: _parseDirection(map['direction']),
      locale: map['locale'] ?? 'en',
      headerTitle: map['headerTitle'],
      headerSubtitle: map['headerSubtitle'],
    );
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return const Color(0xFF00BCD4);
    }
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  static BeonPosition _parsePosition(String? pos) {
    switch (pos?.toLowerCase()) {
      case 'bottom-left':
      case 'bottomleft':
        return BeonPosition.bottomLeft;
      case 'top-right':
      case 'topright':
        return BeonPosition.topRight;
      case 'top-left':
      case 'topleft':
        return BeonPosition.topLeft;
      default:
        return BeonPosition.bottomRight;
    }
  }

  static TextDirection _parseDirection(String? dir) {
    if (dir?.toLowerCase() == 'rtl') {
      return TextDirection.rtl;
    }
    return TextDirection.ltr;
  }

  /// Copy with modified values
  BeonConfig copyWith({
    String? apiKey,
    int? channelId,
    Color? primaryColor,
    BeonPosition? position,
    String? externalUserId,
    String? welcomeMessage,
    bool? enableSounds,
    bool? enablePollingFallback,
    Duration? pollingInterval,
    String? locale,
    TextDirection? textDirection,
    String? baseUrl,
    String? wsUrl,
    bool? preChatFormEnabled,
    String? headerTitle,
    String? headerSubtitle,
    bool? preChatNameEnabled,
    bool? preChatEmailEnabled,
    bool? preChatPhoneEnabled,
    bool? preChatMessageEnabled,
    bool? fullScreen,
  }) {
    return BeonConfig(
      apiKey: apiKey ?? this.apiKey,
      channelId: channelId ?? this.channelId,
      primaryColor: primaryColor ?? this.primaryColor,
      position: position ?? this.position,
      externalUserId: externalUserId ?? this.externalUserId,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      enableSounds: enableSounds ?? this.enableSounds,
      enablePollingFallback: enablePollingFallback ?? this.enablePollingFallback,
      pollingInterval: pollingInterval ?? this.pollingInterval,
      locale: locale ?? this.locale,
      textDirection: textDirection ?? this.textDirection,
      baseUrl: baseUrl ?? this.baseUrl,
      wsUrl: wsUrl ?? this.wsUrl,
      preChatFormEnabled: preChatFormEnabled ?? this.preChatFormEnabled,
      headerTitle: headerTitle ?? this.headerTitle,
      headerSubtitle: headerSubtitle ?? this.headerSubtitle,
      preChatNameEnabled: preChatNameEnabled ?? this.preChatNameEnabled,
      preChatEmailEnabled: preChatEmailEnabled ?? this.preChatEmailEnabled,
      preChatPhoneEnabled: preChatPhoneEnabled ?? this.preChatPhoneEnabled,
      preChatMessageEnabled: preChatMessageEnabled ?? this.preChatMessageEnabled,
      fullScreen: fullScreen ?? this.fullScreen,
    );
  }
}
