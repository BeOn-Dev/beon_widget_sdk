import 'package:flutter/material.dart';
import 'support_style.dart';

class SupportWelcomeCard extends StatelessWidget {
  final String title;
  final String message;
  const SupportWelcomeCard({
    super.key,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(16, 24, 16, 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: SupportStyle.border),
      boxShadow: const [SupportStyle.shadow],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: SupportStyle.background,
          child: Text('👋', style: TextStyle(fontSize: 22)),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: SupportStyle.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: SupportStyle.muted,
          ),
        ),
      ],
    ),
  );
}
