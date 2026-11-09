import 'package:beon_widget_sdk/src/ui/components/beon_emoji_picker.dart';

import 'dart:convert';

import 'package:beon_widget_sdk/src/utils/beon_emoji_policy.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:emoji_picker_flutter/locales/default_emoji_set_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('excludes configured symbols, gestures and couple variants', () {
    for (final emoji in [
      '✝',
      '✝️',
      '☦️',
      '✡️',
      '🕎',
      '🔯',
      '🕉️',
      '☸️',
      '☯️',
      '🪯',
      '⛪',
      '🕍',
      '⛩️',
      '🛕',
      '💒',
      '🎅',
      '🎅🏽',
      '🤶🏻',
      '🎄',
      '🧑🏿‍🎄',
      '🪔',
      '🇻🇦',
      '🧿',
      '🖕',
      '🖕🏿',
      '🍆',
      '🍑',
      '👅',
      '💦',
      '👄',
      '🫦',
      '💋',
      '💏🏽',
      '👩🏽‍❤️‍💋‍👨🏻',
      '💑',
      '👯‍♂️',
      '👯‍♀️',
      '👬',
      '👭🏽',
      '👨🏻‍🤝‍👨🏿',
      '👩🏽‍🤝‍👩🏻',
      '👨‍❤️‍👨',
      '👩🏿‍❤️‍👩🏻',
      '👨‍❤️‍💋‍👨',
      '👩‍❤️‍💋‍👩',
      '👨‍👨‍👦',
      '👩‍👩‍👧‍👦',
    ]) {
      expect(BeonEmojiPolicy.isAllowed(emoji), isFalse, reason: emoji);
    }
    for (final emoji in [
      '🕌',
      '🕋',
      '☪️',
      '🤲',
      '🙏🏽',
      '📿',
      '🧕',
      '🛐',
      '❌',
      '❎',
      '➕',
      '⚛️',
      '🎁',
      '🌲',
      '😇',
      '👨',
      '👩',
      '👨‍👩‍👦',
      '👨‍👩‍👧‍👧',
      '👨‍👦',
      '👩‍👧‍👧',
      '🤼‍♂️',
      '🤼‍♀️',
      '❤️',
    ]) {
      expect(BeonEmojiPolicy.isAllowed(emoji), isTrue, reason: emoji);
    }
  });

  for (final language in [
    'en',
    'ar',
    'de',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'nl',
    'pt',
    'ru',
    'zh',
  ]) {
    test('filters $language without modifying the library catalogue', () {
      final locale = Locale(language);
      final original = getDefaultEmojiLocale(locale);
      final originalCount = original
          .expand((category) => category.emoji)
          .length;
      final filtered = BeonEmojiPolicy.emojiSet(locale);
      expect(
        filtered.map((category) => category.category),
        original.map((category) => category.category),
      );
      final emoji = filtered
          .expand((category) => category.emoji)
          .map((emoji) => emoji.emoji)
          .toSet();
      expect(emoji, containsAll(['🕌', '🕋', '📿', '❌', '😀']));
      expect(emoji, isNot(contains('✝️')));
      expect(emoji, isNot(contains('⛪')));
      expect(emoji, isNot(contains('🧿')));
      expect(emoji, isNot(contains('🖕')));
      expect(emoji, isNot(contains('👭')));
      expect(emoji, isNot(contains('👬')));
      expect(emoji, isNot(contains('🍆')));
      expect(emoji, isNot(contains('🍑')));
      expect(
        getDefaultEmojiLocale(
          locale,
        ).expand((category) => category.emoji).length,
        originalCount,
      );
    });
  }

  for (final size in [const Size(390, 844), const Size(834, 1194)]) {
    testWidgets(
      'filters saved recents and search while retaining selection at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          'recent': jsonEncode([
            RecentEmoji(const Emoji('✝️', 'Christian cross'), 4),
            RecentEmoji(
              const Emoji('🎅🏽', 'Santa Claus', hasSkinTone: true),
              3,
            ),
            RecentEmoji(const Emoji('🧿', 'nazar amulet'), 3),
            RecentEmoji(
              const Emoji('🖕🏿', 'middle finger', hasSkinTone: true),
              3,
            ),
            RecentEmoji(const Emoji('👩🏽‍❤️‍👩🏻', 'couple women'), 3),
            RecentEmoji(const Emoji('🍆', 'eggplant'), 3),
            RecentEmoji(const Emoji('😀', 'grinning face'), 2),
          ]),
        });
        final pickerKey = GlobalKey<EmojiPickerState>();
        final selected = <String>[];
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BeonEmojiPicker(
                key: pickerKey,
                textEditingController: controller,
                config: const Config(
                  emojiSet: BeonEmojiPolicy.emojiSet,
                  checkPlatformCompatibility: false,
                  height: 300,
                ),
                onEmojiSelected: (_, emoji) => selected.add(emoji.emoji),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final state = tester
            .widget<DefaultEmojiPickerView>(find.byType(DefaultEmojiPickerView))
            .state;
        expect(
          state.categoryEmoji
              .firstWhere((category) => category.category == Category.RECENT)
              .emoji
              .map((emoji) => emoji.emoji),
          ['😀'],
        );
        expect(find.text('✝️'), findsNothing);
        expect(find.text('🎅🏽'), findsNothing);
        final searchResults = await EmojiPickerUtils().searchEmoji(
          'cross',
          state.categoryEmoji,
          checkPlatformCompatibility: false,
        );
        expect(
          searchResults.any(
            (emoji) => emoji.emoji == '✝️' || emoji.emoji == '☦️',
          ),
          isFalse,
        );
        final grinning = state.categoryEmoji
            .firstWhere((category) => category.category == Category.RECENT)
            .emoji
            .single;
        state.onEmojiSelected(Category.RECENT, grinning);
        await tester.pumpAndSettle();
        expect(selected, ['😀']);
        expect(controller.text, '😀');
        expect(
          state.categoryEmoji
              .firstWhere((category) => category.category == Category.RECENT)
              .emoji
              .map((emoji) => emoji.emoji),
          ['😀'],
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
