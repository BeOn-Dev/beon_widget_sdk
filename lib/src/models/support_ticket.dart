/// Public visitor-facing ticket data. Internal notes never enter this model.
class SupportTicket {
  final String id;
  final String? uuid;
  final String subject;
  final String description;
  final String status;
  final String? category;
  final String? createdAt;
  const SupportTicket({
    required this.id,
    this.uuid,
    required this.subject,
    this.description = '',
    this.status = 'open',
    this.category,
    this.createdAt,
  });
  bool get isClosed => ['closed', 'resolved'].contains(status.toLowerCase());
  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: (json['id'] ?? json['uuid'] ?? '').toString(),
    uuid: json['uuid']?.toString(),
    subject: (json['subject'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    status: (json['status'] ?? 'open').toString(),
    category: json['category'] is Map
        ? json['category']['name']?.toString()
        : json['category']?.toString(),
    createdAt: json['created_at']?.toString(),
  );
}

class TicketReply {
  final String id;
  final String content;
  final bool fromAgent;
  final String? createdAt;
  const TicketReply({
    required this.id,
    required this.content,
    this.fromAgent = false,
    this.createdAt,
  });
  static bool isVisible(Map<String, dynamic> json) {
    const internal = ['note', 'internal_note', 'info', 'system_info'];
    return !internal.contains(json['type']?.toString().toLowerCase()) &&
        !internal.contains(json['message_type']?.toString().toLowerCase()) &&
        json['is_note'] != true &&
        json['private'] != true;
  }

  factory TicketReply.fromJson(Map<String, dynamic> json) => TicketReply(
    id: (json['id'] ?? json['uuid'] ?? '').toString(),
    content: (json['content'] ?? json['body'] ?? '').toString(),
    fromAgent:
        json['message_type'] == 'outgoing' ||
        json['sender_type'] == 'agent' ||
        json['sender'] == 'agent' ||
        json['agent_name'] != null ||
        json['agent_id'] != null ||
        json['agent'] != null,
    createdAt: json['created_at']?.toString(),
  );
}

class TicketPage {
  final List<SupportTicket> records;
  final Map<String, int> counts;
  final bool hasMore;
  const TicketPage({
    this.records = const [],
    this.counts = const {},
    this.hasMore = false,
  });
}

class TicketDetails {
  final SupportTicket ticket;
  final List<TicketReply> messages;
  final bool hasMore;
  const TicketDetails({
    required this.ticket,
    this.messages = const [],
    this.hasMore = false,
  });
}
