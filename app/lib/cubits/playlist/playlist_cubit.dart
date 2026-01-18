import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/podcast.dart';
import 'playlist_state.dart';

class PlaylistCubit extends Cubit<PlaylistState> {
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
}
