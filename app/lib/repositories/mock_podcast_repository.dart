import 'dart:async';
import '../models/podcast.dart';
import 'podcast_repository.dart';

class MockPodcastRepository implements PodcastRepository {
  @override
  Future<Podcast> generatePodcast(List<Source> sources) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 3));

    return Podcast(
      filePath: "mock_path.mp3",
      metadata: PodcastMetadata(
        title: "Daily AI Mock Episode",
        sourceNames: sources.map((s) => s.name ?? s.url).toList(),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<Podcast>> getRecentPodcasts() async {
    return [
      Podcast(
        filePath: "mock_old_1.mp3",
        metadata: PodcastMetadata(
          title: "Yesterday's News",
          sourceNames: ["BBC RSS", "TechCrunch"],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ),
      Podcast(
        filePath: "mock_old_2.mp3",
        metadata: PodcastMetadata(
          title: "Early Morning Update",
          sourceNames: ["YouTube: AI Trends"],
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ),
    ];
  }
}
