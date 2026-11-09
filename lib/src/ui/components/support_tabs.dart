import 'package:flutter/material.dart';
import 'support_style.dart';

class SupportTabs extends StatelessWidget {
  final bool ticketsSelected;
  final ValueChanged<bool> onChanged;
  final String locale;
  const SupportTabs({
    super.key,
    required this.ticketsSelected,
    required this.onChanged,
    required this.locale,
  });
  @override
  Widget build(BuildContext context) {
    final strings = SupportStrings(locale);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: SupportStyle.input,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            _tab(
              strings.chat,
              Icons.chat_bubble_outline,
              !ticketsSelected,
              false,
            ),
            _tab(
              strings.tickets,
              Icons.confirmation_number_outlined,
              ticketsSelected,
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, IconData icon, bool selected, bool value) =>
      Expanded(
        child: Semantics(
          selected: selected,
          child: Material(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => onChanged(value),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: selected ? SupportStyle.ink : SupportStyle.muted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? SupportStyle.ink : SupportStyle.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
