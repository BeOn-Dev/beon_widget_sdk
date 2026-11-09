import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:emoji_picker_flutter/locales/default_emoji_set_locale.dart';
import 'package:flutter/widgets.dart';

abstract class BeonEmojiPolicy {
  // Match Unicode sequences rather than translated keywords. Shared symbols
  // (prayer beads, prayer hands) and ordinary cross marks remain available.
  static const _excluded = {
    '✝',
    '☦',
    '✡',
    '🕎',
    '🔯',
    '🕉',
    '☸',
    '☯',
    '🪯',
    '⛪',
    '🕍',
    '⛩',
    '🛕',
    '💒',
    '🎅',
    '🤶',
    '🎄',
    '🪔',
    '🇻🇦',
    // Additional symbols and suggestive emoji excluded from app pickers.
    '🧿',
    '🖕',
    '🍆',
    '🍑',
    '👅',
    '💦',
    '👄',
    '🫦',
    '💋',
    '💏',
    '💑',
    '👯',
    // Include modern ZWJ and legacy couple/family sequences; skin tones and
    // presentation selectors are removed before matching.
    '👬',
    '👭',
    '👨‍🤝‍👨',
    '👩‍🤝‍👩',
    '👨‍❤‍👨',
    '👩‍❤‍👩',
    '👨‍👨',
    '👩‍👩',
  };

  static String _normalize(String value) => String.fromCharCodes(
    value.runes.where(
      (rune) =>
          rune != 0xfe0f &&
          rune != 0xfe0e &&
          (rune < 0x1f3fb || rune > 0x1f3ff),
    ),
  );

  static bool isAllowed(String emoji) {
    final normalized = _normalize(emoji);
    return !_excluded.any(normalized.contains);
  }

  static List<CategoryEmoji> _filter(List<CategoryEmoji> categories) => [
    for (final category in categories)
      category.copyWith(
        emoji: category.emoji.where((emoji) => isAllowed(emoji.emoji)).toList(),
      ),
  ];

  static List<CategoryEmoji> emojiSet(Locale locale) =>
      _filter(getDefaultEmojiLocale(locale));

  static Widget buildView(
    Config config,
    EmojiViewState state,
    VoidCallback showSearchBar,
  ) {
    // Recents are loaded separately from emojiSet. Filter the picker's display
    // list too, retaining its callbacks and navigation notifier for search/tabs.
    for (var index = 0; index < state.categoryEmoji.length; index++) {
      final category = state.categoryEmoji[index];
      state.categoryEmoji[index] = category.copyWith(
        emoji: category.emoji.where((emoji) => isAllowed(emoji.emoji)).toList(),
      );
    }
    return DefaultEmojiPickerView(config, state, showSearchBar);
  }
}
