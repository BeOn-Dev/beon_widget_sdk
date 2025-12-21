import 'package:flutter/material.dart';

/// "Powered by Beon" footer component
class PoweredByFooter extends StatelessWidget {
  final Color? textColor;
  final Color? brandColor;

  const PoweredByFooter({
    super.key,
    this.textColor,
    this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Powered by ',
            style: TextStyle(
              fontSize: 11,
              color: textColor ?? Colors.grey.shade500,
            ),
          ),
          Text(
            'Beon',
            style: TextStyle(
              fontSize: 11,
              color: brandColor ?? Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
