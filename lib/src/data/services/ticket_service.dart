import '../../config/beon_config.dart';
import '../../models/support_ticket.dart';
import '../api_client.dart';
import 'auth_service.dart';

/// Uses the same visitor-scoped endpoints and payloads as the web widget.
class TicketService {
  final BeonApiClient client;
  final BeonConfig config;
  final AuthService auth;
  TicketService(this.client, this.config, this.auth);

  String get _uid => auth.currentVisitor?.id ?? '';
  Map<String, dynamic> get _query => {'uid': _uid, 'token': config.apiKey};
  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
  bool _hasMore(Map<String, dynamic> meta, int count, int page) => meta.isEmpty
      ? count >= 10
      : (int.tryParse('${meta['current_page'] ?? page}') ?? page) <
            (int.tryParse('${meta['last_page'] ?? page}') ?? page);

  Future<TicketPage> fetchTickets({
    int page = 1,
    String status = 'all',
    int? conversationId,
  }) async {
    final response = await client.get(
      '/tickets',
      queryParameters: {
        ..._query,
        'page': page,
        if (status != 'all') 'status': status,
        if (conversationId != null) 'conversation_id': conversationId,
      },
    );
    final root = _map(response.data);
    final data = root['data'] ?? root;
    final body = _map(data);
    final records = data is List
        ? data
        : body['records'] ?? body['tickets'] ?? [];
    final items = (records as List)
        .whereType<Map>()
        .map((e) => SupportTicket.fromJson(_map(e)))
        .toList();
    final counts = _map(body['counts'] ?? root['counts']);
    return TicketPage(
      records: items,
      counts: counts.map(
        (key, value) => MapEntry(key, int.tryParse('$value') ?? 0),
      ),
      hasMore: _hasMore(_map(body['meta'] ?? root['meta']), items.length, page),
    );
  }

  Future<TicketDetails> fetchTicket(String id, {int page = 1}) async {
    final response = await client.get(
      '/tickets/${Uri.encodeComponent(id)}',
      queryParameters: {..._query, 'page': page},
    );
    final root = _map(response.data);
    final outer = _map(root['data'] ?? root);
    final body = _map(outer['data'] ?? outer);
    final rawMessages = (body['messages'] ?? body['records'] ?? []) as List;
    final messages = rawMessages
        .whereType<Map>()
        .map(_map)
        .where(TicketReply.isVisible)
        .map(TicketReply.fromJson)
        .toList();
    return TicketDetails(
      ticket: SupportTicket.fromJson(_map(body['ticket'] ?? body)),
      messages: messages,
      hasMore: _hasMore(
        _map(body['meta'] ?? outer['meta'] ?? root['meta']),
        rawMessages.length,
        page,
      ),
    );
  }

  Future<SupportTicket> createTicket({
    required String categoryId,
    required String subject,
    required String description,
    int? conversationId,
  }) async {
    final visitor = auth.currentVisitor;
    final info = {
      'name': visitor?.name,
      'email': visitor?.email,
      'phone': visitor?.phone,
    };
    final response = await client.post(
      '/tickets',
      data: {
        ..._query,
        'id': _uid,
        'subject': subject,
        'description': description,
        'category_id': categoryId,
        'ticket_category_id': categoryId,
        ...info,
        'visitorInfo': info,
        if (conversationId != null) 'conversation_id': conversationId,
      },
    );
    final root = _map(response.data);
    final body = _map(root['data'] ?? root);
    return SupportTicket.fromJson(_map(body['ticket'] ?? body['data'] ?? body));
  }

  Future<TicketReply?> sendReply(String id, String content) async {
    final response = await client.post(
      '/tickets/${Uri.encodeComponent(id)}/messages',
      data: {..._query, 'id': _uid, 'content': content, 'body': content},
    );
    final root = _map(response.data);
    final data = _map(root['data'] ?? root);
    final body = _map(data['data'] ?? data);
    final message = _map(body['message'] ?? body);
    return message.isEmpty ? null : TicketReply.fromJson(message);
  }
}
