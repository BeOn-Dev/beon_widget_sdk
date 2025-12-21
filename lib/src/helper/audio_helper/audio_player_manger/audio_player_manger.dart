import 'package:audioplayers/audioplayers.dart';

class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();

  factory AudioPlayerManager() => _instance;

  AudioPlayerManager._internal();

  final List<AudioPlayer> _players = [];

  void registerNewPlayer(AudioPlayer player) {
    // يوقف الباقيين Pause بدل Stop
    for (final p in _players) {
      if (p != player && p.state == PlayerState.playing) {
        p.pause();
      }
    }

    if (!_players.contains(player)) {
      _players.add(player);
    }
  }

  void unregisterPlayer(AudioPlayer player) {
    _players.remove(player);
  }

  void pauseAll() {
    for (final p in _players) {
      if (p.state == PlayerState.playing) {
        p.pause();
      }
    }
  }

  void stopAll() {
    for (final p in _players) {
      if (p.state == PlayerState.playing) {
        p.stop();
      }
    }
  }
}
