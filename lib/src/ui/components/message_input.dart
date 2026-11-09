import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../../models/message.dart';
import 'support_style.dart';
import 'support_input_style.dart';
import 'beon_emoji_picker.dart';
import '../../utils/beon_emoji_policy.dart';

/// Message input component with emoji picker and file attachment
class MessageInput extends StatefulWidget {
  final Function(String content) onSend;
  final Function(String filePath, String fileName, SendMessageType type)?
  onAttachment;
  final bool isSending;
  final Color primaryColor;
  final String locale;

  const MessageInput({
    super.key,
    required this.onSend,
    this.onAttachment,
    this.isSending = false,
    required this.primaryColor,
    this.locale = 'en',
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _showEmojiPicker = false;
  bool _hasText = false;
  bool _attachmentOpen = false;
  PlatformFile? _pendingFile;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onSend() {
    if (widget.isSending) return;
    final pending = _pendingFile;
    if (pending != null) {
      final type =
          [
            'jpg',
            'jpeg',
            'png',
            'gif',
            'webp',
          ].contains(pending.extension?.toLowerCase())
          ? SendMessageType.image
          : ['mp4', 'mov', 'webm'].contains(pending.extension?.toLowerCase())
          ? SendMessageType.video
          : [
              'mp3',
              'm4a',
              'wav',
              'ogg',
            ].contains(pending.extension?.toLowerCase())
          ? SendMessageType.audio
          : SendMessageType.document;
      widget.onAttachment?.call(pending.path!, pending.name, type);
      setState(() => _pendingFile = null);
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  Future<void> _showAttachmentOptions() async {
    if (_attachmentOpen || widget.isSending || widget.onAttachment == null) {
      return;
    }
    _attachmentOpen = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'mp4',
          'mov',
          'webm',
          'mp3',
          'm4a',
          'wav',
          'ogg',
          'pdf',
          'txt',
        ],
      );
      if (!mounted || result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              SupportStrings(widget.locale).text(
                'File is too large. Maximum size is 10 MB.',
                'الملف كبير جداً. الحد الأقصى 10 ميجابايت.',
              ),
            ),
          ),
        );
        return;
      }
      if (file.path != null) setState(() => _pendingFile = file);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              SupportStrings(widget.locale).text(
                'Unable to select file. Please try again.',
                'تعذر اختيار الملف. يرجى المحاولة مرة أخرى.',
              ),
            ),
          ),
        );
      }
    } finally {
      _attachmentOpen = false;
    }
  }

  void _removeFile() => setState(() => _pendingFile = null);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_pendingFile != null)
          ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(
              _pendingFile!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              onPressed: _removeFile,
              tooltip: SupportStrings(widget.locale).close,
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: SupportStyle.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.onAttachment != null)
                  _buildIconButton(
                    icon: Icons.add,
                    onTap: _showAttachmentOptions,
                    tooltip: SupportStrings(widget.locale).attach,
                  ),
                _buildIconButton(
                  icon: _showEmojiPicker
                      ? Icons.keyboard
                      : Icons.emoji_emotions_outlined,
                  onTap: _toggleEmojiPicker,
                  tooltip: SupportStrings(
                    widget.locale,
                  ).text('Emoji', 'إيموجي'),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    style: SupportInputStyle.text,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _onSend(),
                    onTap: _hideEmojiPicker,
                    decoration: SupportInputStyle.decoration(
                      primaryColor: widget.primaryColor,
                      hintText: SupportStrings(widget.locale).messageHint,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildSendButton(),
              ],
            ),
          ),
        ),

        // Emoji picker
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: BeonEmojiPicker(
              textEditingController: _controller,
              config: Config(
                height: 250,
                emojiSet: BeonEmojiPolicy.emojiSet,
                locale: Locale(widget.locale.split(RegExp('[ _-]')).first),
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  columns: 7,
                  emojiSizeMax: 28,
                  verticalSpacing: 0,
                  horizontalSpacing: 0,
                  backgroundColor: Colors.grey.shade50,
                  recentsLimit: 28,
                ),
                categoryViewConfig: CategoryViewConfig(
                  initCategory: Category.RECENT,
                  indicatorColor: widget.primaryColor,
                  iconColor: Colors.grey,
                  iconColorSelected: widget.primaryColor,
                  backspaceColor: widget.primaryColor,
                ),
                bottomActionBarConfig: const BottomActionBarConfig(
                  showBackspaceButton: true,
                  showSearchViewButton: false,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _hideEmojiPicker() {
    if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32,
            height: 36,
            alignment: Alignment.center,
            child: Icon(icon, color: SupportStyle.muted, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = (_hasText || _pendingFile != null) && !widget.isSending;

    return Tooltip(
      message: SupportStrings(widget.locale).send,
      child: Material(
        color: canSend ? widget.primaryColor : Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: canSend ? _onSend : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: widget.isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.send_outlined,
                    color: canSend ? Colors.white : SupportStyle.muted,
                    size: 16,
                    textDirection: Directionality.of(context),
                  ),
          ),
        ),
      ),
    );
  }
}
