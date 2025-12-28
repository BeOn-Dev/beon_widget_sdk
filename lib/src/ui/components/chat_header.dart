import 'package:flutter/material.dart';

/// Header component for chat window and pre-chat form
class ChatHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color primaryColor;
  final VoidCallback onClose;
  final bool showWave;

  const ChatHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.primaryColor,
    required this.onClose,
    this.showWave = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Wave emoji for welcome
              if (showWave)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text(
                    '\u{1F44B}', // Wave emoji
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Close button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
