import 'package:audioplayers/audioplayers.dart';

/// Service for playing notification sounds
class SoundService {
  static SoundService? _instance;
  static SoundService get instance => _instance ??= SoundService._();

  SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isEnabled = true;

  /// Enable or disable sounds
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if sounds are enabled
  bool get isEnabled => _isEnabled;

  /// Play notification sound for new message
  Future<void> playNotification() async {
    if (!_isEnabled) return;

    try {
      // Use a simple system sound or bundled asset
      await _player.play(
        AssetSource('sounds/notification.mp3'),
        volume: 0.5,
      );
    } catch (e) {
      // Silent fail - sound is not critical
    }
  }

  /// Play send sound
  Future<void> playSend() async {
    if (!_isEnabled) return;

    try {
      await _player.play(
        AssetSource('sounds/send.mp3'),
        volume: 0.3,
      );
    } catch (e) {
      // Silent fail
    }
  }

  /// Stop any playing sounds
  Future<void> stop() async {
    await _player.stop();
  }

  /// Dispose resources
  void dispose() {
    _player.dispose();
  }
}
