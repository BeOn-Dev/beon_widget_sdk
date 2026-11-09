import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'support_style.dart';

/// Inline native playback, matching the web widget's video controls.
class SupportVideoMessage extends StatefulWidget {
  final String source;
  final bool isLocal;
  final String locale;
  final Color primaryColor;
  final VideoPlayerController Function()? createController;
  const SupportVideoMessage({
    super.key,
    required this.source,
    this.isLocal = false,
    this.locale = 'en',
    this.primaryColor = const Color(0xFF017DC0),
    this.createController,
  });
  @override
  State<SupportVideoMessage> createState() => _SupportVideoMessageState();
}

class _SupportVideoMessageState extends State<SupportVideoMessage> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _error = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SupportVideoMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.isLocal != widget.isLocal) {
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final previous = _controller;
    _controller = null;
    await previous?.dispose();
    if (!mounted || generation != _generation) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    VideoPlayerController? controller;
    try {
      controller =
          widget.createController?.call() ??
          (widget.isLocal && !kIsWeb
              ? VideoPlayerController.file(File(widget.source))
              : VideoPlayerController.networkUrl(Uri.parse(widget.source)));
      _controller = controller;
      await controller.initialize().timeout(const Duration(seconds: 20));
      if (mounted && identical(_controller, controller)) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted && identical(_controller, controller)) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _toggle() async {
    final controller = _controller;
    if (controller == null || _loading || _error) return;
    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _generation++;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = SupportStrings(widget.locale);
    final controller = _controller;
    if (_loading) {
      return SizedBox(
        width: 240,
        height: 140,
        child: Center(
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation(widget.primaryColor),
          ),
        ),
      );
    }
    if (_error || controller == null) {
      return SizedBox(
        width: 240,
        height: 100,
        child: Center(
          child: TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: Text(strings.retry),
          ),
        ),
      );
    }
    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _toggle,
                tooltip: controller.value.isPlaying
                    ? strings.text('Pause', 'إيقاف مؤقت')
                    : strings.text('Play', 'تشغيل'),
                icon: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: widget.primaryColor,
                ),
              ),
              Expanded(
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(playedColor: widget.primaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
