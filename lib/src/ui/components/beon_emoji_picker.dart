import '../../utils/beon_emoji_policy.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

/// Applies the app's emoji filter to both initial data and subsequent recents.
class BeonEmojiPicker extends EmojiPicker {
  const BeonEmojiPicker({
    super.key,
    super.textEditingController,
    super.onEmojiSelected,
    super.onBackspacePressed,
    super.config = const Config(emojiSet: BeonEmojiPolicy.emojiSet),
  }) : super(customWidget: BeonEmojiPolicy.buildView);

  @override
  EmojiPickerState createState() => _BeonEmojiPickerState();
}

class _BeonEmojiPickerState extends EmojiPickerState {
  @override
  void updateRecentEmoji(
    List<RecentEmoji> recentEmoji, {
    bool refresh = false,
  }) {
    super.updateRecentEmoji(
      recentEmoji
          .where((recent) => BeonEmojiPolicy.isAllowed(recent.emoji.emoji))
          .toList(),
      refresh: refresh,
    );
  }
}
