import 'package:beon_widget_sdk/src/config/beon_config.dart';
import 'package:beon_widget_sdk/src/data/services/chat_service.dart';
import 'package:beon_widget_sdk/src/data/services/ticket_service.dart';
import 'package:beon_widget_sdk/src/models/message.dart';
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final locale in ['en', 'ar']) {
    testWidgets('full mobile chat and tickets in $locale', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final chat = _Chat();
      final tickets = _Tickets();
      when(
        () => chat.fetchHistory(page: 1),
      ).thenAnswer((_) async => (<Message>[], null));
      final config = BeonConfig(
        apiKey: 'test',
        fullScreen: true,
        locale: locale,
        ticketsEnabled: true,
        textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        headerTitle: 'Support',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            configProvider.overrideWithValue(config),
            chatServiceProvider.overrideWithValue(chat),
            effectiveConfigProvider.overrideWith((ref) async => config),
            ticketServiceProvider.overrideWithValue(tickets),
          ],
          child: MaterialApp(
            home: Directionality(
              textDirection: config.textDirection,
              child: Scaffold(
                body: SafeArea(child: SupportChatBody(config: config)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SupportTabs), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
      await tester.tap(find.text(locale == 'ar' ? 'التذاكر' : 'Tickets'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          locale == 'ar' ? 'ابدأ محادثة أولاً' : 'Start a conversation first',
        ),
        findsOneWidget,
      );
      verifyNever(
        () => tickets.fetchTickets(
          page: any(named: 'page'),
          status: any(named: 'status'),
          conversationId: any(named: 'conversationId'),
        ),
      );
      await tester.tap(
        find.text(locale == 'ar' ? 'بدء محادثة الآن' : 'Start Chat Now'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('server can hide tickets', (tester) async {
    final chat = _Chat();
    when(
      () => chat.fetchHistory(page: 1),
    ).thenAnswer((_) async => (<Message>[], null));
    const config = BeonConfig(
      apiKey: 'test',
      fullScreen: true,
      ticketsEnabled: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configProvider.overrideWithValue(config),
          effectiveConfigProvider.overrideWith((ref) async => config),
          chatServiceProvider.overrideWithValue(chat),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SupportChatBody(config: config)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SupportTabs), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
