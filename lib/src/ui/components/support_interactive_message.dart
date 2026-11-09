import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/app_functions/app_functions.dart';
import 'support_style.dart';

/// Web widget interactive buttons send their visible reply title as chat text.
class SupportInteractiveMessage extends StatelessWidget {
  final String body;
  final ValueChanged<String>? onReply;
  final bool enabled;
  final Color? textColor;
  const SupportInteractiveMessage({
    super.key,
    required this.body,
    this.onReply,
    this.enabled = true,
    this.textColor,
  });
  Map<String, dynamic> _content() {
    try {
      final value = jsonDecode(body);
      if (value is Map) return Map<String, dynamic>.from(value);
    } catch (_) {
      /* Plain text is also supported by the web widget. */
    }
    return {'text': body};
  }

  String _title(Map button) =>
      '${button['reply'] is Map ? button['reply']['title'] ?? '' : button['title'] ?? button['text'] ?? ''}';
  List<Map<String, String>> _links(Map<String, dynamic> content) {
    final action = content['action'];
    final raw =
        content['links'] ??
        content['link'] ??
        (action is Map && action['name'] == 'cta_url' ? action : null);
    return [
      for (final value
          in raw is List
              ? raw
              : raw == null
              ? []
              : [raw])
        if (value is String)
          {'text': value, 'url': value}
        else if (value is Map)
          {
            'text':
                '${value['parameters'] is Map ? value['parameters']['display_text'] ?? value['parameters']['title'] ?? '' : value['display_text'] ?? value['title'] ?? value['text'] ?? ''}',
            'url':
                '${value['parameters'] is Map ? value['parameters']['url'] ?? '' : value['url'] ?? value['link'] ?? ''}',
          },
    ];
  }

  void _reply(String title) {
    if (enabled && title.isNotEmpty) onReply?.call(title);
  }

  void _open(String url) => AppFunctions.launchMyUrl(url: url);
  @override
  Widget build(BuildContext context) {
    final content = _content();
    final buttons = content['buttons'] is List
        ? content['buttons'] as List
        : const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (content['text'] != null)
          Text(
            '${content['text']}',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: textColor ?? SupportStyle.ink,
            ),
          ),
        for (final link in _links(
          content,
        ).where((link) => link['url']!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: () => _open(link['url']!),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: Text(
                link['text']!.isEmpty ? link['url']! : link['text']!,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        for (final button in buttons.whereType<Map>())
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton(
              onPressed: enabled && onReply != null
                  ? () => _reply(_title(button))
                  : null,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: SupportStyle.ink,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _title(button),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
