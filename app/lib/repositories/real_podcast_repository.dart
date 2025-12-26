import 'package:dio/dio.dart';
import '../models/podcast.dart';
import 'podcast_repository.dart';

class RealPodcastRepository implements PodcastRepository {
  final Dio _dio;
  final String baseUrl;

  RealPodcastRepository({required this.baseUrl})
    : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  @override
  Future<Podcast> generatePodcast(
    List<Source> sources, {
    String? ttsEngine,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/generate',
        data: {
          "sources": sources
              .map((s) => {"source_type": s.type, "url": s.url, "name": s.name})
              .toList(),
          "tts_engine": ttsEngine,
        },
      );

      // Map API Response to Podcast Model
      // Expected API Response:
      // {
      //   "file_path": "path/to/file.mp3",
      //   "metadata": {
      //     "title": "Title",
      //     "sources": ["source1"],
      //     "created_at": "timestamp"
      //   }
      // }
      final data = response.data;
      final metadata = PodcastMetadata(
        title: data['metadata']['title'],
        sourceNames: List<String>.from(data['metadata']['sources']),
        createdAt: DateTime.now(), // Or parse from server if available
      );

      return Podcast(
        filePath:
            "${baseUrl.replaceAll("/api/v1", "")}/${data['file_path']}", // Assuming file is served statically or via another endpoint
        metadata: metadata,
        ttsEngineUsed: data['tts_engine_used'],
      );
    } catch (e) {
      throw Exception('Failed to generate podcast: $e');
    }
  }

  @override
  Future<List<Podcast>> getRecentPodcasts() async {
    try {
      final response = await _dio.get('/api/v1/episodes');
      // Response: {"episodes": ["file1.mp3", ...]}
      // We don't have full metadata here yet, so we'll mock it or extract from filename
      final List<dynamic> files = response.data['episodes'];

      return files.map((file) {
        return Podcast(
          filePath: "${baseUrl.replaceAll("/api/v1", "")}/downloads/$file",
          metadata: PodcastMetadata(
            title: file.toString(),
            sourceNames: [],
            createdAt: DateTime.now(),
          ),
        );
      }).toList();
    } catch (e) {
      print("Failed to fetch recent episodes: $e");
      return [];
    }
  }
}
