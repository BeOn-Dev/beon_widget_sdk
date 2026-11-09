import 'dart:async';
import 'package:beon_widget_sdk/src/config/beon_config.dart';
import 'package:beon_widget_sdk/src/data/api_client.dart';
import 'package:beon_widget_sdk/src/data/services/auth_service.dart';
import 'package:beon_widget_sdk/src/data/services/ticket_service.dart';
import 'package:beon_widget_sdk/src/data/services/reverb_service.dart';
import 'package:beon_widget_sdk/src/models/channel_config.dart';
import 'package:beon_widget_sdk/src/models/support_ticket.dart';
import 'package:beon_widget_sdk/src/models/visitor.dart';
import 'package:beon_widget_sdk/src/providers/ticket_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Client extends Mock implements BeonApiClient {}

class _Auth extends Mock implements AuthService {}

class _Tickets extends Mock implements TicketService {}

class _Socket implements ReverbService {
  void Function(dynamic)? onData;
  String? channel;
  bool closed = false;
  @override
  void listen(
    void Function(dynamic) callback,
    String name, {
    bool isPrivate = false,
  }) {
    onData = callback;
    channel = name;
  }

  @override
  void close() {
    closed = true;
  }
}

void main() {
  const ticket = SupportTicket(id: '12', subject: 'Help');
  group('Visitor ticket API contract', () {
    late _Client client;
    late TicketService service;
    setUp(() {
      client = _Client();
      final auth = _Auth();
      when(() => auth.conversationUid).thenReturn('visitor');
      when(() => auth.currentVisitor).thenReturn(
        Visitor(id: 'visitor', name: 'Example', createdAt: DateTime(2026)),
      );
      service = TicketService(
        client,
        const BeonConfig(apiKey: 'test-key'),
        auth,
      );
    });
    test(
      'list uses visitor credentials, status and conversation scope',
      () async {
        when(
          () => client.get(
            '/tickets',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(),
            data: {
              'data': {
                'records': [
                  {'id': 12, 'subject': 'Help'},
                ],
                'counts': {'all': 1, 'open': 1},
                'meta': {'current_page': 1, 'last_page': 2},
              },
            },
          ),
        );
        final result = await service.fetchTickets(
          status: 'open',
          conversationId: 42,
        );
        expect(result.records.single.subject, 'Help');
        expect(result.counts['all'], 1);
        expect(result.hasMore, isTrue);
        verify(
          () => client.get(
            '/tickets',
            queryParameters: {
              'uid': 'visitor',
              'token': 'test-key',
              'page': 1,
              'status': 'open',
              'conversation_id': 42,
            },
          ),
        ).called(1);
      },
    );
    test('details discard private notes and system information', () async {
      when(
        () => client.get(
          '/tickets/12',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: {
            'data': {
              'ticket': {'id': 12, 'subject': 'Help'},
              'messages': [
                {'id': 1, 'body': 'public'},
                {'id': 2, 'body': 'secret', 'private': true},
                {'id': 3, 'body': 'internal', 'type': 'internal_note'},
                {'id': 4, 'body': 'system', 'message_type': 'info'},
              ],
              'meta': {'current_page': 1, 'last_page': 1},
            },
          },
        ),
      );
      final details = await service.fetchTicket('12');
      expect(details.messages.map((e) => e.content), ['public']);
      expect(details.hasMore, isFalse);
    });
    test('create and reply match dashboard payloads', () async {
      when(() => client.post('/tickets', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: {
            'data': {
              'ticket': {'id': 12, 'subject': 'Help'},
            },
          },
        ),
      );
      when(
        () => client.post('/tickets/12/messages', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(), data: {}),
      );
      await service.createTicket(
        categoryId: '3',
        subject: 'Help',
        description: 'Details',
        conversationId: 42,
      );
      final payload =
          verify(
                () => client.post('/tickets', data: captureAny(named: 'data')),
              ).captured.single
              as Map;
      expect(payload['uid'], 'visitor');
      expect(payload['category_id'], '3');
      expect(payload['ticket_category_id'], '3');
      expect(payload['conversation_id'], 42);
      expect(payload['name'], 'Example');
      await service.sendReply('12', 'Reply');
      verify(
        () => client.post(
          '/tickets/12/messages',
          data: {
            'uid': 'visitor',
            'token': 'test-key',
            'id': 'visitor',
            'content': 'Reply',
            'body': 'Reply',
          },
        ),
      ).called(1);
    });
  });
  test('channel settings control ticket visibility, categories and logo', () {
    final channel = ChannelConfig.fromApiResponse({
      'status': true,
      'data': {
        'id': 1,
        'name': 'Support',
        'categories': [
          {'id': 3, 'name': 'Technical'},
        ],
        'settings': {
          'tickets_enabled': 'true',
          'logo': 'https://example.com/logo.png',
        },
      },
    });
    expect(channel!.settings.ticketsEnabled, isTrue);
    expect(channel.settings.ticketCategories.single['id'], 3);
    expect(channel.settings.avatarUrl, 'https://example.com/logo.png');
    const config = BeonConfig(
      apiKey: 'test',
      ticketsEnabled: true,
      widgetVersion: 'custom',
    );
    expect(config.copyWith(locale: 'ar').ticketsEnabled, isTrue);
    expect(config.copyWith(locale: 'ar').widgetVersion, 'custom');
  });
  test(
    'ticket socket uses UUID, ignores notes and closes on disposal',
    () async {
      final service = _Tickets();
      final socket = _Socket();
      const selected = SupportTicket(
        id: '12',
        uuid: 'ticket-uuid',
        subject: 'Help',
      );
      when(
        () => service.fetchTicket('12'),
      ).thenAnswer((_) async => const TicketDetails(ticket: selected));
      final notifier = TicketStateNotifier(
        service,
        42,
        createReverb: () => socket,
      );
      await notifier.open(selected);
      expect(socket.channel, 'tickets_public_ticket-uuid');
      socket.onData!(
        WebsocketResponse(
          event: 'ticket_message',
          data: {
            'message': {'id': 1, 'content': 'Hello', 'sender': 'agent'},
          },
        ),
      );
      socket.onData!(
        WebsocketResponse(
          event: 'ticket_message',
          data: {
            'message': {'id': 2, 'content': 'Private', 'private': true},
          },
        ),
      );
      expect(notifier.state.replies.map((e) => e.content), ['Hello']);
      notifier.dispose();
      expect(socket.closed, isTrue);
    },
  );
  group('Ticket lifecycle', () {
    late _Tickets service;
    late TicketStateNotifier notifier;
    setUp(() {
      service = _Tickets();
      notifier = TicketStateNotifier(service, 42);
    });
    tearDown(() => notifier.dispose());
    test('failed loading completes and allows retry', () async {
      when(
        () => service.fetchTickets(page: 1, status: 'all', conversationId: 42),
      ).thenThrow(Exception('offline'));
      await notifier.load();
      expect(notifier.state.loading, isFalse);
      expect(notifier.state.error, isNotNull);
      when(
        () => service.fetchTickets(page: 1, status: 'all', conversationId: 42),
      ).thenAnswer((_) async => const TicketPage(records: [ticket]));
      await notifier.load();
      expect(notifier.state.error, isNull);
      expect(notifier.state.page.records.single.id, '12');
    });
    test(
      'a stale filter response cannot replace the selected filter',
      () async {
        final first = Completer<TicketPage>();
        when(
          () =>
              service.fetchTickets(page: 1, status: 'open', conversationId: 42),
        ).thenAnswer((_) => first.future);
        when(
          () => service.fetchTickets(
            page: 1,
            status: 'closed',
            conversationId: 42,
          ),
        ).thenAnswer((_) async => const TicketPage());
        final pending = notifier.load(filter: 'open');
        await notifier.load(filter: 'closed');
        first.complete(const TicketPage(records: [ticket]));
        await pending;
        expect(notifier.state.filter, 'closed');
        expect(notifier.state.page.records, isEmpty);
      },
    );
    test('repeat create taps send one request', () async {
      final first = Completer<SupportTicket>();
      when(
        () => service.createTicket(
          categoryId: '3',
          subject: 'Help',
          description: 'Details',
          conversationId: 42,
        ),
      ).thenAnswer((_) => first.future);
      when(
        () => service.fetchTicket('12'),
      ).thenAnswer((_) async => const TicketDetails(ticket: ticket));
      final pending = notifier.create(
        categoryId: '3',
        subject: 'Help',
        description: 'Details',
      );
      expect(
        await notifier.create(
          categoryId: '3',
          subject: 'Help',
          description: 'Details',
        ),
        isFalse,
      );
      first.complete(ticket);
      expect(await pending, isTrue);
      verify(
        () => service.createTicket(
          categoryId: '3',
          subject: 'Help',
          description: 'Details',
          conversationId: 42,
        ),
      ).called(1);
    });
    test(
      'successful reply appears immediately without depending on a history reload',
      () async {
        when(
          () => service.fetchTicket('12'),
        ).thenAnswer((_) async => const TicketDetails(ticket: ticket));
        when(() => service.sendReply('12', 'Reply')).thenAnswer(
          (_) async => const TicketReply(id: 'new', content: 'Reply'),
        );
        await notifier.open(ticket);
        expect(await notifier.send('Reply'), isTrue);
        expect(notifier.state.replies.single.content, 'Reply');
        verify(() => service.fetchTicket('12')).called(1);
      },
    );
    test(
      'failed reply retains a retryable error and completes loading',
      () async {
        when(
          () => service.fetchTicket('12'),
        ).thenAnswer((_) async => const TicketDetails(ticket: ticket));
        when(
          () => service.sendReply('12', 'Reply'),
        ).thenThrow(Exception('offline'));
        await notifier.open(ticket);
        expect(await notifier.send('Reply'), isFalse);
        expect(notifier.state.submitting, isFalse);
        expect(notifier.state.error, 'send');
      },
    );
    test(
      'late reply from an old ticket socket cannot enter a new view',
      () async {
        when(
          () => service.fetchTicket('12'),
        ).thenAnswer((_) async => const TicketDetails(ticket: ticket));
        when(
          () =>
              service.fetchTickets(page: 1, status: 'all', conversationId: 42),
        ).thenAnswer((_) async => const TicketPage());
        final socket = _Socket();
        final active = TicketStateNotifier(
          service,
          42,
          createReverb: () => socket,
        );
        await active.open(ticket);
        final callback = socket.onData!;
        await active.load();
        callback(
          WebsocketResponse(
            event: 'ticket_message',
            data: {
              'message': {'id': 'late', 'content': 'Old reply'},
            },
          ),
        );
        expect(active.state.replies, isEmpty);
        expect(socket.closed, isTrue);
        active.dispose();
      },
    );
    test('closed tickets cannot send replies', () async {
      const closed = SupportTicket(id: '12', subject: 'Help', status: 'closed');
      when(
        () => service.fetchTicket('12'),
      ).thenAnswer((_) async => const TicketDetails(ticket: closed));
      await notifier.open(closed);
      expect(await notifier.send('Reply'), isFalse);
      verifyNever(() => service.sendReply(any(), any()));
    });
  });
}
