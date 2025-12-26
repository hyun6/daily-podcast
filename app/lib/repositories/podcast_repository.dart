import '../models/podcast.dart';

abstract class PodcastRepository {
  Future<Podcast> generatePodcast(List<Source> sources);
  Future<List<Podcast>> getRecentPodcasts();
}
