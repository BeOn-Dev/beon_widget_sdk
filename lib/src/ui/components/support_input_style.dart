import 'package:flutter/material.dart';

/// Mirrors Beon's standard form fields without importing the host application.
abstract final class SupportInputStyle {
  static const text = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xFF888888),
  );
  static const hint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF888888),
  );
  static const _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(color: Color(0xFFCCCCCC)),
  );
  static const _errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(color: Color(0xFFE41517)),
  );

  static InputDecoration decoration({
    required Color primaryColor,
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
  }) => InputDecoration(
    hintText: hintText,
    labelText: labelText,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    hintStyle: hint,
    labelStyle: text.copyWith(color: const Color(0xFF333333)),
    isDense: true,
    filled: false,
    constraints: const BoxConstraints(minHeight: 44),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    prefixIcon: prefixIcon ?? const SizedBox.shrink(),
    prefixIconConstraints: prefixIcon == null
        ? const BoxConstraints.tightFor(width: 16, height: 44)
        : const BoxConstraints(minWidth: 44, minHeight: 44),
    border: _border,
    enabledBorder: _border,
    disabledBorder: _border,
    focusedBorder: _border.copyWith(
      borderSide: BorderSide(color: primaryColor),
    ),
    errorBorder: _errorBorder,
    focusedErrorBorder: _errorBorder,
  );
}
