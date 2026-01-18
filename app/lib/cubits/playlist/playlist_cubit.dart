import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../models/podcast.dart';
import 'playlist_state.dart';

class PlaylistCubit extends HydratedCubit<PlaylistState> {
  PlaylistCubit() : super(const PlaylistState());

  void addToPlaylist(Podcast podcast) {
    if (!state.playlist.contains(podcast)) {
      final updatedList = List<Podcast>.from(state.playlist)..add(podcast);
      emit(state.copyWith(playlist: updatedList));
    }
  }

  void removeFromPlaylist(Podcast podcast) {
    final updatedList = List<Podcast>.from(state.playlist)..remove(podcast);
    emit(state.copyWith(playlist: updatedList));
  }

  void reorderPlaylist(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final updatedList = List<Podcast>.from(state.playlist);
    final item = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, item);
    emit(state.copyWith(playlist: updatedList));
  }

  @override
  PlaylistState? fromJson(Map<String, dynamic> json) {
    try {
      final playlist = (json['playlist'] as List)
          .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
          .toList();
      return PlaylistState(playlist: playlist);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(PlaylistState state) {
    return {'playlist': state.playlist.map((p) => p.toJson()).toList()};
  }
}
