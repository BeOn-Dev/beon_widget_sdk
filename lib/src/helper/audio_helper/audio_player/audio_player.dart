import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/app_functions/app_functions.dart';
import '../../../utils/app_padding/app_padding.dart';
import '../audio_player_manger/audio_player_manger.dart';

/// 🔥 IMPROVED AUDIO PLAYER
/// يحافظ على الـ state حتى لو حصل rebuild من الـ Cubit
class AudioPlayer extends StatefulWidget {
  final String source;
  final VoidCallback? onDelete;
  final bool isLoading;
  final void Function()? onSendRecord;

  const AudioPlayer({
    super.key,
    required this.source,
    this.onDelete,
    this.onSendRecord,
    this.isLoading = false,
  });

  @override
  AudioPlayerState createState() => AudioPlayerState();
}

class AudioPlayerState extends State<AudioPlayer>
    with AutomaticKeepAliveClientMixin {
  static const double _controlSize = 56;
  static const double _deleteBtnSize = 24;

  final _audioPlayer = ap.AudioPlayer()..setReleaseMode(ap.ReleaseMode.stop);

  StreamSubscription<void>? _playerCompleteSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  Duration? _position;
  Duration? _duration;
  double _playbackSpeed = 1.0;

  /// 🔥 NEW: علشان نمنع إعادة التهيئة
  bool _isInitialized = false;
  String? _currentSource;

  /// 🔥 CRITICAL: بنقول لـ Flutter إن الـ widget دي لازم تفضل محفوظة
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentSource = widget.source;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAudio();
    });
  }

  Future<void> _initAudio() async {
    if (_isInitialized) {
      AppFunctions.logPrint(
          message: "🎵 Audio already initialized, skipping init");
      return;
    }

    AppFunctions.logPrint(
        message: "🎵 Initializing audio player for: ${widget.source}");

    // Register listeners safely
    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) async {
      AppFunctions.logPrint(message: "🎵 Audio playback completed");
      await stop();
    });

    _positionSub = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _durationSub = _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    try {
      // Validate source before attempting to set it
      final source = _source; // This will throw if invalid
      await _audioPlayer.setSource(source);
      _isInitialized = true;
      _currentSource = widget.source;
      AppFunctions.logPrint(message: "✅ Audio initialized successfully: ${widget.source}");
    } catch (e) {
      AppFunctions.logPrint(
        message: "❌ Error loading audio source '${widget.source}': $e"
      );
      // Mark as failed so we don't try to play
      _isInitialized = false;

      // Update state to show error if mounted
      if (mounted) {
        setState(() {
          // Error state - player will show disabled/error UI
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant AudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// 🔥 CRITICAL FIX: بس نعمل reload لو الـ source فعلاً اتغير
    /// مش لو الـ parent widget اتعمل rebuild
    if (oldWidget.source != widget.source && widget.source != _currentSource) {
      AppFunctions.logPrint(
          message:
              "🔄 Audio source changed from ${oldWidget.source} to ${widget.source}");
      _reloadSource();
    } else if (oldWidget.source == widget.source) {
      AppFunctions.logPrint(
          message: "✅ Audio source unchanged, keeping playback state");
    }
  }

  Future<void> _reloadSource() async {
    try {
      final wasPlaying = _audioPlayer.state == ap.PlayerState.playing;
      final currentPosition = _position;

      AppFunctions.logPrint(
          message:
              "🔄 Reloading audio source. Was playing: $wasPlaying at position: $currentPosition");

      await _audioPlayer.stop();
      await _audioPlayer.setSource(_source);
      _currentSource = widget.source;

      /// 🔥 محاولة استرجاع الموضع لو ممكن
      if (wasPlaying && currentPosition != null) {
        await _audioPlayer.seek(currentPosition);
        await _audioPlayer.resume();
        AppFunctions.logPrint(
            message: "✅ Resumed playback at previous position");
      }

      if (mounted) setState(() {});
    } catch (e) {
      AppFunctions.logPrint(message: "⚠️ Error reloading audio source: $e");
    }
  }

  @override
  void dispose() {
    AppFunctions.logPrint(
        message: "🗑️ Disposing audio player for: ${widget.source}");

    AudioPlayerManager().unregisterPlayer(_audioPlayer);
    _playerCompleteSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> play() async {
    AudioPlayerManager().registerNewPlayer(_audioPlayer);
    try {
      await _audioPlayer.resume();
      AppFunctions.logPrint(message: "▶️ Playing audio");
      if (mounted) setState(() {});
    } catch (e) {
      AppFunctions.logPrint(message: "⚠️ Error playing audio: $e");
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      AppFunctions.logPrint(message: "⏸️ Paused audio");
      if (mounted) setState(() {});
    } catch (e) {
      AppFunctions.logPrint(message: "⚠️ Error pausing audio: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      AppFunctions.logPrint(message: "⏹️ Stopped audio");
      if (mounted) setState(() {});
    } catch (e) {
      AppFunctions.logPrint(message: "⚠️ Error stopping audio: $e");
    }
  }

  void _changeSpeed() async {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });
    try {
      await _audioPlayer.setPlaybackRate(_playbackSpeed);
      AppFunctions.logPrint(
          message: "🎚️ Playback speed changed to ${_playbackSpeed}x");
    } catch (e) {
      AppFunctions.logPrint(
          message: "⚠️ Playback speed not supported on this device: $e");
      _playbackSpeed = 1.0;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 🔥 IMPORTANT: لازم نعمل call للـ super علشان الـ mixin يشتغل
    super.build(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            widget.onDelete != null
                ? IconButton(
                    icon: const Icon(Icons.delete,
                        color: AppColors.red, size: _deleteBtnSize),
                    onPressed: () async {
                      if (_audioPlayer.state == ap.PlayerState.playing) {
                        await pause();
                      }
                      widget.onDelete?.call();
                    },
                  )
                : const SizedBox.shrink(),
            Expanded(
              child: Container(
                padding: AppPadding.padding8(),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.grey.withValues(alpha: 0.3),
                ),
                child: Row(
                  children: [
                    _buildControl(),
                    Expanded(child: _buildSlider(constraints.maxWidth)),
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    AppSpacing.horizontalSpace(4),
                    InkWell(
                      onTap: _changeSpeed,
                      child: Text(
                        "${_playbackSpeed}x",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // widget.onSendRecord != null
            //     ? widget.isLoading
            //         ? const CircularProgressIndicator.adaptive()
            //         : IconButton(
            //             onPressed: widget.onSendRecord,
            //             icon: const SVGImageWidget(
            //               image: AppIcons.sendMessage,
            //               color: AppColors.black,
            //             ))
            //     : const ShrinkSizedBoxWidget(),
          ],
        );
      },
    );
  }

  Widget _buildControl() {
    final isPlaying = _audioPlayer.state == ap.PlayerState.playing;
    final icon = Icon(
      isPlaying ? Icons.pause : Icons.play_arrow,
      color: AppColors.mainColor,
      size: 30,
    );

    return InkWell(
      onTap: () => isPlaying ? pause() : play(),
      child: SizedBox(width: _controlSize, height: _controlSize, child: icon),
    );
  }

  Widget _buildSlider(double widgetWidth) {
    bool canSetValue = false;
    final duration = _duration;
    final position = _position;

    if (duration != null && position != null) {
      canSetValue = position.inMilliseconds > 0 &&
          position.inMilliseconds < duration.inMilliseconds;
    }

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
      ),
      child: Slider(
        activeColor: AppColors.mainColor,
        inactiveColor: AppColors.white,
        onChanged: (v) {
          if (duration != null) {
            final newPos = v * duration.inMilliseconds;
            _audioPlayer.seek(Duration(milliseconds: newPos.round()));
          }
        },
        value: canSetValue && duration != null && position != null
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0,
      ),
    );
  }

  ap.Source get _source {
    // Validate source is not empty
    if (widget.source.trim().isEmpty) {
      throw Exception('Audio source cannot be empty');
    }

    final trimmedSource = widget.source.trim();

    // Proper URL validation using startsWith instead of contains
    final isUrl = trimmedSource.startsWith('http://') ||
        trimmedSource.startsWith('https://');

    if (isUrl) {
      // Validate URL can be parsed
      try {
        final uri = Uri.parse(trimmedSource);
        if (!uri.hasScheme || uri.host.isEmpty) {
          throw Exception('Invalid URL format: $trimmedSource');
        }
        AppFunctions.logPrint(message: "🎵 Loading audio from URL: $trimmedSource");
        return ap.UrlSource(trimmedSource);
      } catch (e) {
        AppFunctions.logPrint(message: "❌ Invalid audio URL: $e");
        throw Exception('Failed to parse audio URL: $trimmedSource');
      }
    } else {
      // For file paths, just validate it's not empty
      // File existence check happens during playback
      AppFunctions.logPrint(message: "🎵 Loading audio from file: $trimmedSource");
      return ap.DeviceFileSource(trimmedSource);
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
