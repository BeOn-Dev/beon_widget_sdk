

import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';
import 'package:intl/src/intl/date_format.dart';
import '../../../beon_widget_sdk.dart';
import '../../models/message.dart';

class AppFunctions {
  /// Translates text using EasyLocalization with fallback safety
  /// Returns untranslated text if context is invalid or translation fails

  // Disabled in production - uncomment for debugging
  // static logPrint({required String message}) => log(message);
  static void logPrint({required String message}) {
    // No-op in production to avoid console logs
  }
  static MessageStatus getMessageStatus({required String status}) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'unread':
        return MessageStatus.unread;
      case 'read':
        return MessageStatus.read;
      case 'delivered':
        return MessageStatus.delivered;
      case 'failed':
      case 'faild': // Handle typo in API
        return MessageStatus.failed;
      default:
        return MessageStatus.unread;
    }
  }

  static MessageType getMessageType({required String messageType}) {
    switch (messageType.toLowerCase()) {
      case 'incoming':
      case 'my_message':
        return MessageType.myMessage;
      case 'outgoing':
      case 'client_message':
        return MessageType.clientMessage;
      default:
        return MessageType.clientMessage;
    }
  }
  static String sanitizeString(String? input) {
    if (input == null || input.isEmpty) return "";

    try {
      // Remove characters that are not valid UTF-16
      final sanitized = StringBuffer();
      final runes = input.runes;

      for (int rune in runes) {
        // Skip unpaired surrogates (0xD800-0xDFFF)
        // and other problematic Unicode ranges
        if (rune >= 0xD800 && rune <= 0xDFFF) {
          continue; // Skip unpaired surrogates
        }

        // Add valid characters
        if (rune <= 0x10FFFF) {
          sanitized.writeCharCode(rune);
        }
      }

      return sanitized.toString();
    } catch (e) {
      AppFunctions.logPrint(
          message: "Error sanitizing string: ${e.toString()}");
      // Return a safe fallback - filter out non-ASCII if all else fails
      return input.replaceAll(RegExp(r'[^\x00-\x7F]+'), '');
    }
  }
  static SendMessageType getSendMessageType({required String type}) {
    switch (type) {
      case "text":
        return SendMessageType.text;
      case "image":
        return SendMessageType.image;
      case "audio":
        return SendMessageType.audio;
      case "document":
        return SendMessageType.document;
      case "video":
        return SendMessageType.video;
      case "note":
        return SendMessageType.note;
      case "location":
        return SendMessageType.location;
      case "info":
        return SendMessageType.info;
      case "sticker":
        return SendMessageType.sticker;
      default:
        return SendMessageType.text;
    }
  }


  /// Sanitizes text by removing unpaired UTF-16 surrogates
  ///
  /// Prevents iOS crash: "Invalid JSON message, encoding failed"
  /// This happens when text contains unpaired UTF-16 surrogate pairs that cannot
  /// be encoded to UTF-8 when sent through Flutter's platform channels.
  ///
  /// Common sources of invalid UTF-16:
  /// - Complex emojis (👨‍👩‍👧‍👦, 👍🏽)
  /// - Backspace on emoji sequences
  /// - Copy-pasted text from other apps
  /// - Malformed API responses
  ///

  /// Safe navigation pop with validation
  /// Checks if a route exists before popping to prevent "Bad state: No element" error
  static popNavigate({required context}) {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      logPrint(
          message:
              "⚠️ Navigation warning: Attempted to pop when no route exists");
    }
  }

  static launchMyUrl({required String url}) async {
    var uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppFunctions.logPrint(message: "Can't Launch ");
    }
  }


  static String convertMessageDateTime({required String date}) {
    try {
      DateTime dateTime = DateTime.parse(date).toLocal();

      String formatted = DateFormat('MM/dd/yyyy, hh:mm a').format(
        dateTime,
      );
      return formatted;
    } catch (e) {
      return date;
    }
  }

}
