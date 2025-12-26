import '../models/podcast.dart';

abstract class PodcastRepository {
  Future<Podcast> generatePodcast(List<Source> sources, {String? ttsEngine});
  Future<List<Podcast>> getRecentPodcasts();
}
