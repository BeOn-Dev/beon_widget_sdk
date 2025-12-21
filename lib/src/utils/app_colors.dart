import 'package:flutter/material.dart';

/// App color constants
abstract class AppColors {
  static const Color mainColor = Color(0xFF017DC0);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color messageBackground = Color(0xFFDBEEF8);
  static const Color greyAccent = Color(0xFF627485);
  static const Color red = Color(0xFFE53935);
  static const Color blue = Color(0xFF2196F3);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
}

/// Cached variables for app state
class CachedVariables {
  static String lang = 'en';
}

/// App text styles
abstract class AppTextStyles {
  static TextStyle w400With14FontSize({
    Color? color,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color ?? Colors.black87,
      decoration: decoration,
    );
  }

  static TextStyle w500With14FontSize({Color? color}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color ?? Colors.black87,
    );
  }

  static TextStyle w600With16FontSize({Color? color}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color ?? Colors.black87,
    );
  }
}

/// App spacing helpers
abstract class AppSpacing {
  static Widget horizontalSpace(double width) => SizedBox(width: width);
  static Widget verticalSpace(double height) => SizedBox(height: height);
}
