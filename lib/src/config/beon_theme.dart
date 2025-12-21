import 'package:flutter/material.dart';

/// Theme customization for the Beon Chat Widget
class BeonTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color visitorBubbleColor;
  final Color agentBubbleColor;
  final Color visitorTextColor;
  final Color agentTextColor;
  final BorderRadius windowBorderRadius;
  final BorderRadius bubbleBorderRadius;
  final double launcherSize;
  final double windowWidth;
  final double windowHeight;
  final EdgeInsets windowPadding;
  final TextStyle? headerTitleStyle;
  final TextStyle? headerSubtitleStyle;
  final TextStyle? messageTextStyle;
  final TextStyle? timestampTextStyle;

  const BeonTheme({
    this.primaryColor = const Color(0xFF017DC0),
    this.backgroundColor = Colors.white,
    this.surfaceColor = const Color(0xFFF5F5F5),
    this.textColor = const Color(0xFF212121),
    this.secondaryTextColor = const Color(0xFF757575),
    this.visitorBubbleColor = const Color(0xFF00BCD4),
    this.agentBubbleColor = const Color(0xFFF5F5F5),
    this.visitorTextColor = Colors.white,
    this.agentTextColor = const Color(0xFF212121),
    this.windowBorderRadius = const BorderRadius.all(Radius.circular(16)),
    this.bubbleBorderRadius = const BorderRadius.all(Radius.circular(16)),
    this.launcherSize = 56,
    this.windowWidth = 360,
    this.windowHeight = 520,
    this.windowPadding = const EdgeInsets.all(16),
    this.headerTitleStyle,
    this.headerSubtitleStyle,
    this.messageTextStyle,
    this.timestampTextStyle,
  });

  /// Create theme from primary color
  factory BeonTheme.fromPrimaryColor(Color color) {
    return BeonTheme(
      primaryColor: color,
      visitorBubbleColor: color,
    );
  }

  /// Copy with modified values
  BeonTheme copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? visitorBubbleColor,
    Color? agentBubbleColor,
    Color? visitorTextColor,
    Color? agentTextColor,
    BorderRadius? windowBorderRadius,
    BorderRadius? bubbleBorderRadius,
    double? launcherSize,
    double? windowWidth,
    double? windowHeight,
    EdgeInsets? windowPadding,
    TextStyle? headerTitleStyle,
    TextStyle? headerSubtitleStyle,
    TextStyle? messageTextStyle,
    TextStyle? timestampTextStyle,
  }) {
    return BeonTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      visitorBubbleColor: visitorBubbleColor ?? this.visitorBubbleColor,
      agentBubbleColor: agentBubbleColor ?? this.agentBubbleColor,
      visitorTextColor: visitorTextColor ?? this.visitorTextColor,
      agentTextColor: agentTextColor ?? this.agentTextColor,
      windowBorderRadius: windowBorderRadius ?? this.windowBorderRadius,
      bubbleBorderRadius: bubbleBorderRadius ?? this.bubbleBorderRadius,
      launcherSize: launcherSize ?? this.launcherSize,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      windowPadding: windowPadding ?? this.windowPadding,
      headerTitleStyle: headerTitleStyle ?? this.headerTitleStyle,
      headerSubtitleStyle: headerSubtitleStyle ?? this.headerSubtitleStyle,
      messageTextStyle: messageTextStyle ?? this.messageTextStyle,
      timestampTextStyle: timestampTextStyle ?? this.timestampTextStyle,
    );
  }
}
