import 'package:flutter/material.dart';
import 'support_style.dart';

/// "Powered by Beon" footer component
class PoweredByFooter extends StatelessWidget {
  final String locale;
  final Color? textColor;
  final Color? brandColor;

  const PoweredByFooter({
    super.key,
    this.locale = 'en',
    this.textColor,
    this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            SupportStrings(locale).text('Powered by ', 'مشغل بواسطة '),
            style: TextStyle(
              fontSize: 10,
              color: textColor ?? SupportStyle.muted,
            ),
          ),
          Text(
            'Beon',
            style: TextStyle(
              fontSize: 10,
              color: brandColor ?? Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
