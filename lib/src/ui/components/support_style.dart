import 'package:flutter/material.dart';

/// Shared dashboard widget tokens, independent of the embedding application.
abstract final class SupportStyle {
  static const background = Color(0xFFF8FAFC);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF94A3B8);
  static const border = Color(0xFFF1F5F9);
  static const input = Color(0xFFEEF2F6);
  static const shadow = BoxShadow(
    color: Color(0x080F172A),
    blurRadius: 16,
    offset: Offset(0, 4),
  );
}

/// Uses the same Arabic/English locale selection as the SDK's pre-chat UI.
class SupportStrings {
  final String locale;
  const SupportStrings(this.locale);
  bool get arabic => locale.toLowerCase().startsWith('ar');
  String text(String en, String ar) => arabic ? ar : en;
  String get chat => text('Chat', 'المحادثة');
  String get tickets => text('Tickets', 'التذاكر');
  String get online => text('Online', 'نشط الآن');
  String get close => text('Close', 'إغلاق');
  String get retry => text('Retry', 'إعادة المحاولة');
  String get messageHint => text('Type a message...', 'اكتب رسالتك...');
  String get send => text('Send', 'إرسال');
  String get attach => text('Attach file', 'إرفاق ملف');
  String get firstChat => text('Start a Chat First', 'بدء محادثة أولاً');
  String get startChat => text('Start Chat Now', 'بدء محادثة الآن');
  String get newTicket => text('Create New Ticket', 'إنشاء تذكرة جديدة');
  String get noConversation =>
      text('Start a conversation first', 'ابدأ محادثة أولاً');
  String get conversationRequired => text(
    'To create a support ticket, please start a conversation and send a message to our support team.',
    'لإنشاء تذكرة دعم فني، يرجى بدء محادثة أولاً وإرسال رسالتك للتواصل مع فريق الدعم.',
  );
  String get welcome => text(
    'Hello, how can we help you today?',
    'اهلا بك، كيف يمكنني مساعدتك اليوم؟',
  );
}
