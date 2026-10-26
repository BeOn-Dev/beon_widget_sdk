import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beon_widget_sdk/beon_widget_sdk.dart';
import 'package:beon_widget_sdk/src/models/visitor.dart' show PreChatData;
import 'package:beon_widget_sdk/src/ui/pre_chat_form.dart';
import 'package:beon_widget_sdk/src/ui/pre_chat_tablet_layout.dart';
import 'package:beon_widget_sdk/src/providers/providers.dart';
import 'package:beon_widget_sdk/src/providers/widget_state.dart';
import 'package:beon_widget_sdk/src/data/services/auth_service.dart';
import 'package:beon_widget_sdk/src/data/services/chat_service.dart';

class _Auth extends Mock implements AuthService {}

class _Chat extends Mock implements ChatService {}

void main() {
  const config = BeonConfig(apiKey: 'test-only', fullScreen: true);
  final visitor = Visitor(id: 'test-visitor', createdAt: DateTime(2026));
  late _Auth auth;
  late _Chat chat;
  setUpAll(
    () => registerFallbackValue(
      const PreChatData(name: 'Example', phone: '01234567890'),
    ),
  );
  setUp(() {
    auth = _Auth();
    chat = _Chat();
    when(() => auth.isPreChatCompleted).thenReturn(false);
  });
  List<Override> overrides() => [
    configProvider.overrideWithValue(config),
    themeProvider.overrideWithValue(
      BeonTheme.fromPrimaryColor(config.primaryColor),
    ),
    effectiveConfigProvider.overrideWith((ref) async => config),
    channelConfigProvider.overrideWith((ref) async => null),
    visitorProvider.overrideWith((ref) async => visitor),
    authServiceProvider.overrideWithValue(auth),
    chatServiceProvider.overrideWithValue(chat),
  ];

  Future<void> mount(
    WidgetTester tester, {
    bool mobile = false,
    bool wholeWidget = false,
  }) async {
    tester.view.physicalSize = mobile
        ? const Size(390, 844)
        : const Size(834, 1194);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          home: Scaffold(
            body: wholeWidget
                ? const BeonChatWidget(config: config)
                : const PreChatForm(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void fill(WidgetTester tester) {
    tester
            .widget<TextFormField>(find.byType(TextFormField).at(0))
            .controller!
            .text =
        'Example';
    tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text =
        '01234567890';
  }

  VoidCallback submit(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed!;

  testWidgets('existing API keeps the mobile form unchanged', (tester) async {
    await mount(tester, mobile: true);
    expect(find.byType(PreChatTabletLayout), findsNothing);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Start Chat'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
    expect(find.text('Powered by '), findsOneWidget);
  });

  testWidgets(
    'tablet presentation is automatic through the original constructor',
    (tester) async {
      await mount(tester, wholeWidget: true);
      expect(find.byType(PreChatTabletLayout), findsOneWidget);
      final bar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.backgroundColor, Colors.white);
      expect(bar.centerTitle, false);
      expect(bar.toolbarHeight, 96);
      expect(find.text('Powered by '), findsOneWidget);
    },
  );

  testWidgets(
    'internal tablet form keeps validation, sending and duplicate guard',
    (tester) async {
      await mount(tester);
      submit(tester)();
      await tester.pump();
      verifyNever(() => auth.updateVisitor(any()));
      expect(find.text('Name is required'), findsOneWidget);
      fill(tester);
      tester
              .widget<TextFormField>(find.byType(TextFormField).last)
              .controller!
              .text =
          'Hello';
      final pending = Completer<Visitor>();
      when(() => auth.updateVisitor(any())).thenAnswer((_) => pending.future);
      when(() => chat.sendMessage('Hello')).thenAnswer(
        (_) async => Message(
          id: 1,
          body: 'Hello',
          messageType: MessageType.myMessage,
          createdAt: '2026-01-01',
        ),
      );
      final onSubmit = submit(tester);
      onSubmit();
      onSubmit();
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      verify(() => auth.updateVisitor(any())).called(1);
      pending.complete(visitor);
      await tester.pumpAndSettle();
      verify(() => chat.sendMessage('Hello')).called(1);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(PreChatForm)),
      );
      expect(scope.read(widgetStateProvider).currentView, WidgetView.chat);
    },
  );

  testWidgets('submission failure completes loading and permits retry', (
    tester,
  ) async {
    await mount(tester);
    fill(tester);
    when(() => auth.updateVisitor(any())).thenThrow(StateError('offline'));
    submit(tester)();
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
    when(() => auth.updateVisitor(any())).thenAnswer((_) async => visitor);
    submit(tester)();
    await tester.pumpAndSettle();
    verify(() => auth.updateVisitor(any())).called(2);
  });
}
