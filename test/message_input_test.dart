import 'package:beon_widget_sdk/src/ui/components/message_input.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'standard field keeps filtered emoji selection and sends it once',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final sent = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MessageInput(
                onSend: sent.add,
                primaryColor: const Color(0xFF017DC0),
              ),
            ),
          ),
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      final border = field.decoration!.enabledBorder! as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(8));
      expect(border.borderSide.color, const Color(0xFFCCCCCC));
      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.byTooltip('Emoji'));
      await tester.pumpAndSettle();
      final state = tester
          .widget<DefaultEmojiPickerView>(find.byType(DefaultEmojiPickerView))
          .state;
      final catalogue = state.categoryEmoji
          .expand((category) => category.emoji)
          .toList();
      expect(catalogue.any((emoji) => emoji.emoji == '🖕'), isFalse);
      final selected = catalogue.firstWhere((emoji) => emoji.emoji == '😀');
      state.onEmojiSelected(Category.SMILEYS, selected);
      await tester.pumpAndSettle();
      expect(field.controller!.text, '😀');
    state.onEmojiSelected(Category.SMILEYS, selected);
    state.onBackspacePressed!();
    await tester.pumpAndSettle();
    expect(field.controller!.text, '😀');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(sent, ['😀']);
      expect(field.controller!.text, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
