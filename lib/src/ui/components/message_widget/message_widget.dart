import 'package:beon_widget_sdk/src/ui/components/message_widget/widget/date_time_message_widget/date_time_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/message.dart';
import '../../../utils/app_functions/app_functions.dart';
import '../../../utils/app_padding/app_padding.dart';
import '../../../utils/app_colors.dart';
import 'widget/reply_message_widget/reply_message_widget.dart';
import 'widget/media_widgets.dart';




class MessageBubble extends StatelessWidget {
  final bool isMyMessage;
  final Message message;

  const MessageBubble({
    super.key,
    required this.isMyMessage,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(

      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: AppPadding.padding8(),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isMyMessage
                        ? AppColors.messageBackground : Colors.grey.shade100,
                border: isMyMessage ? null : Border.all(color: Colors.grey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.replay != null)
                    ReplyMessageWidget(replyMessage: message.replay),
                  MessageContent(message: message),
                  AppSpacing.verticalSpace(8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // DateTimeMessageWidget(dateTime: message.createdAt ?? ''),
AppSpacing.verticalSpace(2),
                      Row(
                        children: [
                          DateTimeMessageWidget(dateTime: message.createdAt??''),
                          MessageStatusIcon(
                            status: message.messageStatus,
                            messageId: message.id,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// Reaction Emoji floating 👇
            if (message.react != null &&
                (message.react?.emoji ?? "").isNotEmpty)
              Positioned(
                bottom: -14,
                right: isMyMessage ? 4 : null,
                left: !isMyMessage ? 4 : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (context) {
                      try {
                        // Safely render emoji with additional sanitization
                        final safeEmoji = AppFunctions.sanitizeString(
                          message.react?.emoji ?? "",
                        );
                        return Text(
                          safeEmoji,
                          style: const TextStyle(fontSize: 16),
                        );
                      } catch (e) {
                        // If emoji rendering fails, show a fallback
                        AppFunctions.logPrint(
                          message:
                              "Error rendering emoji reaction: ${e.toString()}",
                        );
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// --------------------
/// 🔥 CONTENT WIDGET - هنا المهم الـ Audio Player
/// --------------------
class MessageContent extends StatelessWidget {
  final Message message;

  const MessageContent({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    bool isLocal = (message.id ?? 0) < 0;
    switch (message.type) {
      case SendMessageType.text:
      case SendMessageType.note:
        // Extra sanitization for message body (already sanitized in fromJson, but double-check)
        final safeBody = AppFunctions.sanitizeString(message.body ?? '');
        return Linkify(
          onOpen: (link) => AppFunctions.launchMyUrl(url: link.url),
          linkStyle:TextStyle(
            color: Colors.blue,
            fontSize: 14,
            height: 1.4,
          ),
          text: safeBody,
          style: TextStyle(
            color:  AppColors.greyAccent ,
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
        return ChatVideoWidget(
          data: VideoModel(url: message.body ?? '', isLocal: isLocal),
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
          linkStyle:TextStyle(
            color: Colors.blue,
            fontSize: 14,
            height: 1.4,
          ),
          text: safeBody,
          style: TextStyle(
            color:  AppColors.greyAccent ,
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
    if (messageId == -1) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.grey),
        ),
      );
    }

    return Icon(
      (status == MessageStatus.read || status == MessageStatus.delivered)
          ? Icons.done_all
          : Icons.done,
      color:
          status == MessageStatus.read ? AppColors.mainColor : AppColors.grey,
      size: 16,
    );
  }
}
