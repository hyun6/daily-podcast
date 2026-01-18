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
      // 렌더 콜드 스타트 대응: 헬스 체크 확인
      bool isHealthy = await _repository.healthCheck();

      // 최대 3번 재시도 (각 2초 대기)
      if (!isHealthy) {
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(seconds: 2));
          isHealthy = await _repository.healthCheck();
          if (isHealthy) break;
        }
      }

      final podcasts = await _repository.getRecentPodcasts();
      emit(ContentLoaded(podcasts));
    } catch (e) {
      emit(ContentError("서버 연결 실패. 잠시 후 다시 시도해주세요. ($e)"));
    }
  }

  Future<void> deleteContent(Podcast podcast) async {
    if (state is ContentLoaded) {
      final currentList = (state as ContentLoaded).podcasts;
      // Optimistic update
      final optimisticList = List<Podcast>.from(currentList)..remove(podcast);
      emit(ContentLoaded(optimisticList));

      if (podcast.filePath != null) {
        try {
          await _repository.deleteEpisode(podcast.filePath!);
        } catch (e) {
          // Rollback and show error
          emit(
            ContentLoaded(
              currentList,
              errorMessage: "Failed to delete episode: $e",
            ),
          );
          // Allow time for the UI to consume the error before clearing it?
          // Or strictly reliant on the state change.
          // Ideally we might want to clear the error after a bit or on next action,
          // but for now, this ensures the list is restored.
        }
      }
    }
  }
}
