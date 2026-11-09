import 'dart:convert';
import 'package:beon_widget_sdk/beon_widget_sdk.dart';
import 'package:beon_widget_sdk/src/data/services/chat_service.dart';
import 'package:beon_widget_sdk/src/data/services/reverb_service.dart';
import 'package:beon_widget_sdk/src/data/services/ticket_service.dart';
import 'package:beon_widget_sdk/src/models/message.dart';
import 'package:beon_widget_sdk/src/models/support_ticket.dart';
import 'package:beon_widget_sdk/src/providers/providers.dart';
import 'package:beon_widget_sdk/src/ui/components/support_chat_body.dart';
import 'package:beon_widget_sdk/src/ui/components/support_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Chat extends Mock implements ChatService {}

class _Tickets extends Mock implements TicketService {}

class _Socket implements ReverbService {
  @override
  void listen(
    void Function(dynamic) onData,
    String name, {
    bool isPrivate = false,
  }) {}
  @override
  void close() {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'mobile keeps draft across tabs and interactive buttons send titles',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final chat = _Chat();
      final tickets = _Tickets();
      final interactive = Message.fromJson({
        'id': 1,
        'type': 'interactive',
        'message_type': 'outgoing',
        'body': jsonEncode({
          'text': 'Choose an option',
          'buttons': [
            {
              'reply': {'id': 'choice-id', 'title': 'Technical support'},
            },
          ],
        }),
        'created_at': '2026-11-09T10:00:00Z',
      });
      when(
        () => chat.fetchHistory(page: 1),
      ).thenAnswer((_) async => ([interactive], 42));
      when(
        () => tickets.fetchTickets(page: 1, status: 'all', conversationId: 42),
      ).thenAnswer((_) async => const TicketPage());
      when(() => chat.sendMessage('Technical support')).thenAnswer(
        (_) async => const Message(
          id: 2,
          body: 'Technical support',
          type: SendMessageType.text,
          messageType: MessageType.myMessage,
          messageStatus: MessageStatus.sent,
          conversationId: 42,
        ),
      );
      const config = BeonConfig(
        apiKey: 'test',
        fullScreen: true,
        ticketsEnabled: true,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            configProvider.overrideWithValue(config),
            chatServiceProvider.overrideWithValue(chat),
            ticketServiceProvider.overrideWithValue(tickets),
            reverbServiceProvider('42').overrideWithValue(_Socket()),
            effectiveConfigProvider.overrideWith((ref) async => config),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SupportChatBody(config: config)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Unsent draft');
      await tester.tap(find.text('Tickets'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Unsent draft',
      );
      final choice = find.widgetWithText(OutlinedButton, 'Technical support');
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      verify(() => chat.sendMessage('Technical support')).called(1);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Unsent draft',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'authenticated full-screen route uses server channel and retains back navigation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final chat = _Chat();
      when(
        () => chat.fetchHistory(page: 1),
      ).thenAnswer((_) async => (<Message>[], null));
      const config = BeonConfig(
        apiKey: 'test',
        channelId: 1638,
        fullScreen: true,
        user: BeonUser(id: '5049', name: 'Example | acc 237'),
      );
      const channel = ChannelConfig(
        id: 1638,
        name: 'Dashboard support',
        identifier: 'website',
        token: 'test',
        settings: ChannelSettings(
          widgetType: 'users_login',
          primaryColor: Color(0xFF5DB7DE),
          ticketsEnabled: true,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            configProvider.overrideWithValue(config),
            chatServiceProvider.overrideWithValue(chat),
            channelConfigProvider.overrideWith((ref) async => channel),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BeonChatWidget(config: config),
                    ),
                  ),
                  child: const Text('Open support'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open support'));
      await tester.pumpAndSettle();
      expect(find.byType(SupportTabs), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Dashboard support'), findsNWidgets(2));
      await tester.enterText(find.byType(TextField), 'Draft');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Open support'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
