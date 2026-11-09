import 'package:flutter/material.dart';
import 'support_style.dart';

class ChatHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color primaryColor;
  final VoidCallback onClose;
  final bool showWave;
  final String? avatarUrl;
  final String locale;
  final bool showClose;
  final EdgeInsetsGeometry padding;

  const ChatHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.primaryColor,
    required this.onClose,
    this.showWave = false,
    this.avatarUrl,
    this.locale = 'en',
    this.showClose = true,
    this.padding = const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 10),
  });

  @override
  Widget build(BuildContext context) {
    final strings = SupportStrings(locale);
    return Container(
      color: Colors.white,
      padding: padding,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: SupportStyle.ink,
                backgroundImage: avatarUrl == null || avatarUrl!.isEmpty
                    ? null
                    : NetworkImage(avatarUrl!),
                onBackgroundImageError: avatarUrl == null || avatarUrl!.isEmpty
                    ? null
                    : (_, _) {},
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? const Icon(
                        Icons.account_circle,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: SupportStyle.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle ?? strings.online,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: SupportStyle.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showClose)
            IconButton(
              onPressed: onClose,
              tooltip: strings.close,
              icon: const Icon(
                Icons.close,
                size: 16,
                color: SupportStyle.muted,
              ),
            ),
        ],
      ),
    );
  }
}
