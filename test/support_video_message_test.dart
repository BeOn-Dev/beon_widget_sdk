import 'package:beon_widget_sdk/src/ui/components/support_video_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player/video_player.dart';

class _Video extends Mock implements VideoPlayerController {}

void main() {
  testWidgets('video plays inline and releases the native controller', (
    tester,
  ) async {
    final controller = _Video();
    var value = const VideoPlayerValue(
      duration: Duration(seconds: 10),
      size: Size(320, 180),
      isInitialized: true,
    );
    when(() => controller.value).thenAnswer((_) => value);
    when(
      () => controller.playerId,
    ).thenReturn(VideoPlayerController.kUninitializedPlayerId);
    when(() => controller.initialize()).thenAnswer((_) async {});
    when(() => controller.dispose()).thenAnswer((_) async {});
    when(() => controller.play()).thenAnswer((_) async {
      value = value.copyWith(isPlaying: true);
    });
    when(() => controller.pause()).thenAnswer((_) async {
      value = value.copyWith(isPlaying: false);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SupportVideoMessage(
            source: 'https://example.com/video.mp4',
            createController: () => controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(VideoPlayer), findsOneWidget);
    await tester.tap(find.byTooltip('Play'));
    await tester.pumpAndSettle();
    verify(() => controller.play()).called(1);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    verify(() => controller.pause()).called(1);
    await tester.pumpWidget(const SizedBox.shrink());
    verify(() => controller.dispose()).called(1);
  });
  testWidgets('video initialization failure stops loading and allows retry', (
    tester,
  ) async {
    final controller = _Video();
    when(() => controller.initialize()).thenThrow(Exception('offline'));
    when(() => controller.dispose()).thenAnswer((_) async {});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SupportVideoMessage(
            source: 'https://example.com/video.mp4',
            createController: () => controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    verify(() => controller.initialize()).called(2);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
