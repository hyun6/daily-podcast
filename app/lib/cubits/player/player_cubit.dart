import 'dart:async';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/podcast.dart';
import '../../services/audio_player_service.dart';
import 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final AudioPlayerService _audioPlayerService;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _completionSubscription;

  // Optional: Callback to request next track from PlaylistCubit (or handled in UI listener)
  final Function(Podcast)? onPodcastComplete;

  PlayerCubit(this._audioPlayerService, {this.onPodcastComplete})
    : super(const PlayerState()) {
    _initStreams();
  }

  void _initStreams() {
    _playerStateSubscription = _audioPlayerService.onPlayerStateChanged.listen((
      pState,
    ) {
      PlayerStatus status;
      switch (pState) {
        case ap.PlayerState.playing:
          status = PlayerStatus.playing;
          break;
        case ap.PlayerState.paused:
          status = PlayerStatus.paused;
          break;
        case ap.PlayerState.stopped:
          status = PlayerStatus.stopped;
          break;
        case ap.PlayerState.completed:
          status = PlayerStatus.completed;
          break;
        default:
          status = PlayerStatus.initial;
      }
      emit(
        state.copyWith(
          status: status,
          isPlaying: pState == ap.PlayerState.playing,
        ),
      );
    });

    _durationSubscription = _audioPlayerService.onDurationChanged.listen((d) {
      emit(state.copyWith(duration: d));
    });

    _positionSubscription = _audioPlayerService.onPositionChanged.listen((p) {
      emit(state.copyWith(position: p));
    });

    _completionSubscription = _audioPlayerService.onPlayerComplete.listen((_) {
      if (state.currentPodcast != null && onPodcastComplete != null) {
        onPodcastComplete!(state.currentPodcast!);
      }
      emit(
        state.copyWith(
          status: PlayerStatus.completed,
          isPlaying: false,
          position: Duration.zero,
        ),
      );
    });
  }

  Future<void> play(Podcast podcast) async {
    // If same podcast and paused, just resume?
    // But typically 'play(podcast)' means start this specific one.
    if (podcast.filePath != null) {
      await _audioPlayerService.play(podcast.filePath!);
      emit(state.copyWith(currentPodcast: podcast, isPlaying: true));
    }
  }

  Future<void> pause() async {
    await _audioPlayerService.pause();
    // State update handled by stream listener, but optimistic update is fine too
  }

  Future<void> resume() async {
    await _audioPlayerService.resume();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayerService.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    await _audioPlayerService.setSpeed(speed);
    emit(state.copyWith(playbackSpeed: speed));
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayerService.setVolume(volume);
    emit(state.copyWith(volume: volume));
  }

  @override
  Future<void> close() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _completionSubscription?.cancel();
    _audioPlayerService.dispose();
    return super.close();
  }
}
