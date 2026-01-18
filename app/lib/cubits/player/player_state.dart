import 'package:equatable/equatable.dart';
import '../../models/podcast.dart';

class PlayerState extends Equatable {
  final Podcast? currentPodcast;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final double volume;

  const PlayerState({
    this.currentPodcast,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.volume = 1.0,
  });

  PlayerState copyWith({
    Podcast? currentPodcast,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
    double? volume,
  }) {
    return PlayerState(
      currentPodcast: currentPodcast ?? this.currentPodcast,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      volume: volume ?? this.volume,
    );
  }

  @override
  List<Object?> get props => [
    currentPodcast,
    isPlaying,
    position,
    duration,
    playbackSpeed,
    volume,
  ];
}
