import 'package:beon_widget_sdk/src/ui/components/message_widget/widget/date_time_message_widget/date_time_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

import '../../../models/message.dart';
import '../../../utils/app_functions/app_functions.dart';
import '../../../utils/app_padding/app_padding.dart';
import '../../../utils/app_colors.dart';
import '../support_style.dart';
import '../support_interactive_message.dart';
import '../support_video_message.dart';
import 'widget/reply_message_widget/reply_message_widget.dart';
import 'widget/media_widgets.dart';

class MessageBubble extends StatelessWidget {
  final bool isMyMessage;
  final Message message;
  final Color primaryColor;
  final ValueChanged<String>? onReply;
  final bool actionsEnabled;
  final String locale;
  const MessageBubble({
    super.key,
    required this.isMyMessage,
    required this.message,
    this.primaryColor = const Color(0xFF017DC0),
    this.onReply,
    this.actionsEnabled = true,
    this.locale = 'en',
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final maxWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth * .85
          : 320.0;
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth.clamp(0, 480)),
        child: Column(
          crossAxisAlignment: isMyMessage
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMyMessage ? primaryColor : Colors.white,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(isMyMessage ? 20 : 4),
                  topEnd: Radius.circular(isMyMessage ? 4 : 20),
                  bottomStart: const Radius.circular(20),
                  bottomEnd: const Radius.circular(20),
                ),
                border: Border.all(color: SupportStyle.border),
                boxShadow: const [SupportStyle.shadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.replay != null)
                    ReplyMessageWidget(replyMessage: message.replay),
                  MessageContent(
                    message: message,
                    locale: locale,
                    primaryColor: primaryColor,
                    onReply: onReply,
                    actionsEnabled: actionsEnabled,
                    textColor: isMyMessage ? Colors.white : SupportStyle.ink,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DateTimeMessageWidget(dateTime: message.createdAt ?? ''),
                if (isMyMessage) ...[
                  const SizedBox(width: 4),
                  MessageStatusIcon(
                    status: message.messageStatus,
                    messageId: message.id,
                  ),
                ],
              ],
            ),
            if ((message.react?.emoji ?? '').isNotEmpty)
              Text(AppFunctions.sanitizeString(message.react!.emoji!)),
          ],
        ),
      );
    },
  );
}

/// --------------------
/// 🔥 CONTENT WIDGET - هنا المهم الـ Audio Player
/// --------------------
class MessageContent extends StatelessWidget {
  final Message message;

  final Color? textColor;
  final ValueChanged<String>? onReply;
  final bool actionsEnabled;
  final String locale;
  final Color primaryColor;
  const MessageContent({
    super.key,
    required this.message,
    this.textColor,
    this.onReply,
    this.actionsEnabled = true,
    this.locale = 'en',
    this.primaryColor = const Color(0xFF017DC0),
  });

  @override
  Widget build(BuildContext context) {
    bool isLocal =
        message.localPath != null && !(message.body ?? '').startsWith('http') ||
        (message.id ?? 0) < 0;
    switch (message.type) {
      case SendMessageType.interactive:
        return SupportInteractiveMessage(
          body: message.body ?? '',
          textColor: textColor,
          onReply: message.messageType == MessageType.myMessage
              ? null
              : onReply,
          enabled: actionsEnabled,
        );
      case SendMessageType.text:
      case SendMessageType.note:
        // Extra sanitization for message body (already sanitized in fromJson, but double-check)
        final safeBody = AppFunctions.sanitizeString(message.body ?? '');
        return Linkify(
          onOpen: (link) => AppFunctions.launchMyUrl(url: link.url),
          linkStyle: TextStyle(
            color: textColor ?? Colors.blue,
            fontSize: 14,
            height: 1.4,
          ),
          text: safeBody,
          style: TextStyle(
            color: textColor ?? SupportStyle.ink,
            fontSize: 14,
            height: 1.4,
          ),
          maxLines: 10000000,
        );

      case SendMessageType.image:
      case SendMessageType.sticker:
        return MyChatImageWidget(
          image: message.body ?? '',
          height: 80,
          width: 80,
          isLocal: isLocal,
        );

      case SendMessageType.location:
        return LocationMessageWidget(
          latitude: message.latitude ?? 0,
          longitude: message.longitude ?? 0,
        );

      case SendMessageType.video:
        return SupportVideoMessage(
          source: message.body ?? '',
          isLocal: isLocal,
          locale: locale,
          primaryColor: primaryColor,
        );

      case SendMessageType.audio:
        // Validate audio source before rendering player
        final audioSource = message.body ?? '';

        // If empty, show error widget
        if (audioSource.trim().isEmpty) {
          return Container(
            padding: AppPadding.padding8(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.red.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.red, size: 20),
                AppSpacing.horizontalSpace(8),
                Text(
                  "Audio unavailable",
                  style: AppTextStyles.w400With14FontSize(color: AppColors.red),
                ),
              ],
            ),
          );
        }

        // Audio source is valid, render player
        return AudioPlayer(
          key: ValueKey('audio_${message.id}_${message.uId}_${message.body}'),
          source: audioSource,
        );

      case SendMessageType.document:
        return DocumentMessageWidget(doc: message.body ?? '');

      default:
        final safeBody = AppFunctions.sanitizeString(message.body ?? '');
        return Linkify(
          onOpen: (link) => AppFunctions.launchMyUrl(url: link.url),
          linkStyle: TextStyle(
            color: textColor ?? Colors.blue,
            fontSize: 14,
            height: 1.4,
          ),
          text: safeBody,
          style: TextStyle(
            color: textColor ?? SupportStyle.ink,
            fontSize: 14,
            height: 1.4,
          ),
          maxLines: 10000000,
        );
    }
  }
}

/// --------------------
/// STATUS ICON WIDGET - عادي زي ما هو
/// --------------------
class MessageStatusIcon extends StatelessWidget {
  final MessageStatus? status;
  final int? messageId;

  const MessageStatusIcon({
    super.key,
    required this.status,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context) {
    // لو لسه بيبعت الرسالة (id = -1)
    if (status == MessageStatus.sending) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.grey),
        ),
      );
    }

    if (status == MessageStatus.failed) {
      return const Icon(Icons.error_outline, color: Colors.red, size: 16);
    }
    return Icon(
      (status == MessageStatus.read || status == MessageStatus.delivered)
          ? Icons.done_all
          : Icons.done,
      color: status == MessageStatus.read
          ? AppColors.mainColor
          : AppColors.grey,
      size: 16,
    );
  }
}
