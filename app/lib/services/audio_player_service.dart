import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Singleton service to manage audio playback.
class AudioPlayerService {
  // Singleton instance
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  Stream<PlayerState> get onPlayerStateChanged =>
      _audioPlayer.onPlayerStateChanged;
  Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;
  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;
  Stream<void> get onPlayerComplete => _audioPlayer.onPlayerComplete;

  Future<void> play(String path) async {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      await _audioPlayer.play(UrlSource(path));
    } else {
      await _audioPlayer.play(DeviceFileSource(path));
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setPlaybackRate(speed);
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  /// Note: Disposing a singleton is unusual. Call this only on app shutdown if needed.
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
