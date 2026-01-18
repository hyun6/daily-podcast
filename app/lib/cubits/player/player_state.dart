import 'package:equatable/equatable.dart';
import '../../models/podcast.dart';

enum PlayerStatus { initial, playing, paused, stopped, completed }

class PlayerState extends Equatable {
  final PlayerStatus status;
  final Podcast? currentPodcast;
  final bool isPlaying; // Keep for convenience, but status is primary
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final double volume;

  const PlayerState({
    this.status = PlayerStatus.initial,
    this.currentPodcast,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.volume = 1.0,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    Podcast? currentPodcast,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
    double? volume,
  }) {
    return PlayerState(
      status: status ?? this.status,
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
    status,
    currentPodcast,
    isPlaying,
    position,
    duration,
    playbackSpeed,
    volume,
  ];
}
