import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/podcast_repository.dart';
import '../../models/podcast.dart';
import 'content_state.dart';

class ContentCubit extends Cubit<ContentState> {
  final PodcastRepository _repository;

  ContentCubit(this._repository) : super(ContentLoading()) {
    fetchContent();
  }

  Future<void> fetchContent() async {
    emit(ContentLoading());
    try {
      final podcasts = await _repository.getRecentPodcasts();
      emit(ContentLoaded(podcasts));
    } catch (e) {
      emit(ContentError("Failed to fetch content: $e"));
    }
  }

  Future<void> deleteContent(Podcast podcast) async {
    if (state is ContentLoaded) {
      final currentList = (state as ContentLoaded).podcasts;
      final optimisticList = List<Podcast>.from(currentList)..remove(podcast);
      emit(ContentLoaded(optimisticList));

      if (podcast.filePath != null) {
        try {
          await _repository.deleteEpisode(podcast.filePath!);
        } catch (e) {
          emit(ContentError("Failed to delete episode: $e"));
          // Rollback on failure could be implemented here, but typically we just show error
          // and maybe re-fetch.
          fetchContent();
        }
      }
    }
  }
}
