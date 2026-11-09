import 'package:flutter/material.dart';
import '../../models/support_ticket.dart';
import 'support_style.dart';

class SupportTicketListItem extends StatelessWidget {
  final SupportTicket ticket;
  final SupportStrings strings;
  final VoidCallback onTap;
  const SupportTicketListItem({
    super.key,
    required this.ticket,
    required this.strings,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SupportStyle.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${ticket.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: SupportStyle.muted,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: ticket.isClosed
                          ? SupportStyle.input
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.isClosed
                          ? strings.text('Closed', 'مغلقة')
                          : strings.text('Open', 'مفتوحة'),
                      style: TextStyle(
                        fontSize: 10,
                        color: ticket.isClosed
                            ? SupportStyle.muted
                            : const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SupportStyle.ink,
                ),
              ),
              if (ticket.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  ticket.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: SupportStyle.muted,
                  ),
                ),
              ],
              if (ticket.category != null) ...[
                const SizedBox(height: 8),
                Text(
                  ticket.category!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: SupportStyle.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
