import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/podcast.dart';
import '../models/dialogue_script.dart';
import '../models/task_status.dart';
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
        filePath: _buildAudioUrl(data['file_path']),
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
          filePath: _buildAudioUrl("data/audio/$file"),
          metadata: PodcastMetadata(
            title: file.toString(),
            sourceNames: [],
            createdAt: DateTime.now(),
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint("Failed to fetch recent episodes: $e");
      return [];
    }
  }

  @override
  Future<DialogueScript> generateScript(List<Source> sources) async {
    try {
      final response = await _dio.post(
        '/api/v1/generate-script',
        data: {
          "sources": sources
              .map((s) => {"source_type": s.type, "url": s.url, "name": s.name})
              .toList(),
        },
      );

      final data = response.data;
      return DialogueScript.fromJson(data['script']);
    } catch (e) {
      throw Exception('Failed to generate script: $e');
    }
  }

  @override
  Future<String> generateAudioFromScript(
    DialogueScript script, {
    String? ttsEngine,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/generate-audio',
        data: {"script": script.toJson(), "tts_engine": ttsEngine},
      );

      final data = response.data;
      return _buildAudioUrl(data['file_path']);
    } catch (e) {
      throw Exception('Failed to generate audio: $e');
    }
  }

  @override
  Future<String> startAudioGeneration(
    DialogueScript script, {
    String? ttsEngine,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/generate-audio-async',
        data: {"script": script.toJson(), "tts_engine": ttsEngine},
      );
      return response.data['task_id'];
    } catch (e) {
      throw Exception('Failed to start audio generation: $e');
    }
  }

  @override
  Future<TaskStatus> getTaskStatus(String taskId) async {
    try {
      final response = await _dio.get('/api/v1/tasks/$taskId');
      final taskStatus = TaskStatus.fromJson(response.data);

      // Convert relative path to full URL if result exists
      if (taskStatus.result != null && !taskStatus.result!.startsWith('http')) {
        final fullUrl = _buildAudioUrl(taskStatus.result!);
        return TaskStatus(
          taskId: taskStatus.taskId,
          status: taskStatus.status,
          progress: taskStatus.progress,
          result: fullUrl,
          error: taskStatus.error,
        );
      }
      return taskStatus;
    } catch (e) {
      throw Exception('Failed to get task status: $e');
    }
  }

  @override
  Future<void> cancelTask(String taskId) async {
    try {
      await _dio.post('/api/v1/tasks/$taskId/cancel');
    } catch (e) {
      throw Exception('Failed to cancel task: $e');
    }
  }

  String _buildAudioUrl(String path) {
    // If it's already an absolute URL (e.g. Supabase Storage), return it as is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    // Otherwise, append the base path (for local dev)
    return "${baseUrl.replaceAll("/api/v1", "")}/$path";
  }
}
