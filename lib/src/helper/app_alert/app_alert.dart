import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:toastification/toastification.dart';

import '../../../../main.dart';
import '../../utils/app_functions/app_functions.dart';

class AppAlert {
  /// Get safe context for toasts - uses navigatorKey.currentContext if available
  /// Falls back to provided context if navigatorKey context is null


  static success(
      {required String message,
      required context,
      bool isTranslated = false}) {
    try {


      return toastification.show(
        context: context,
        style: ToastificationStyle.minimal,
        type: ToastificationType.success,
        alignment: Alignment.topCenter,
        title: Text(
          message,
          maxLines: 4,
        ),
        autoCloseDuration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppFunctions.logPrint(
          message: "❌ Error showing success toast: $e - Message: $message");
    }
  }

  static error(
      {required String message,
      Toast? toastLength,
      required context,
      bool isTranslated = false}) {
    try {


      return toastification.show(
        context: context,
        style: ToastificationStyle.minimal,
        type: ToastificationType.error,
        alignment: Alignment.topCenter,
        title: Text(
       message,
          maxLines: 4,
        ),
        autoCloseDuration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppFunctions.logPrint(
          message: "❌ Error showing error toast: $e - Message: $message");
    }
  }

  static warning(
      {required String message,
      Toast? toastLength,
      required context,
      bool isTranslated = false}) {
    try {


      return toastification.show(
        context: context,
        style: ToastificationStyle.minimal,
        type: ToastificationType.warning,
        alignment: Alignment.topCenter,
        title: Text(message),
        autoCloseDuration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppFunctions.logPrint(
          message: "❌ Error showing warning toast: $e - Message: $message");
    }
  }
}
