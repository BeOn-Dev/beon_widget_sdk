import 'package:flutter/material.dart';

import '../../../../../models/message.dart';
import '../../../../../utils/app_colors.dart';

class ReplyMessageWidget extends StatelessWidget {
  final Message? replyMessage;
  final bool isPreparedToReply;
  final VoidCallback? onCancelReply;

  const ReplyMessageWidget({
    super.key,
    required this.replyMessage,
    this.isPreparedToReply = false,
    this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    if (replyMessage == null) return const SizedBox.shrink();

    final isMyMessage = replyMessage?.messageType == MessageType.myMessage;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: const Border(
          left: BorderSide(color: AppColors.mainColor, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMyMessage
                      ? (replyMessage?.agentName ?? 'You')
                      : (replyMessage?.agentName ?? 'Agent'),
                  style: AppTextStyles.w500With14FontSize(
                    color: AppColors.mainColor,
                  ),
                ),
                const SizedBox(height: 2),
                _buildReplyContent(replyMessage),
              ],
            ),
          ),
          if (isPreparedToReply && onCancelReply != null)
            InkWell(
              onTap: onCancelReply,
              child: const Icon(
                Icons.close,
                color: AppColors.red,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyContent(Message? message) {
    switch (message?.type) {
      case SendMessageType.text:
      case SendMessageType.note:
        return Text(
          message?.body ?? '',
          style: AppTextStyles.w400With14FontSize(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );

      case SendMessageType.image:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image, size: 16, color: AppColors.grey),
            const SizedBox(width: 4),
            Text(
              'Photo',
              style: AppTextStyles.w400With14FontSize(),
            ),
          ],
        );

      case SendMessageType.video:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam, size: 16, color: AppColors.grey),
            const SizedBox(width: 4),
            Text(
              'Video',
              style: AppTextStyles.w400With14FontSize(),
            ),
          ],
        );

      case SendMessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, size: 16, color: AppColors.grey),
            const SizedBox(width: 4),
            Text(
              'Audio',
              style: AppTextStyles.w400With14FontSize(),
            ),
          ],
        );

      case SendMessageType.document:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, size: 16, color: AppColors.grey),
            const SizedBox(width: 4),
            Text(
              'Document',
              style: AppTextStyles.w400With14FontSize(),
            ),
          ],
        );

      case SendMessageType.location:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 16, color: AppColors.grey),
            const SizedBox(width: 4),
            Text(
              'Location',
              style: AppTextStyles.w400With14FontSize(),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
