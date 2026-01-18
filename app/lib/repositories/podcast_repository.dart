import '../models/podcast.dart';
import '../models/dialogue_script.dart';
import '../models/task_status.dart';

abstract class PodcastRepository {
  Future<Podcast> generatePodcast(List<Source> sources, {String? ttsEngine});
  Future<List<Podcast>> getRecentPodcasts();

  /// Generate script only without audio
  Future<DialogueScript> generateScript(List<Source> sources);

  /// Generate audio from an existing script (synchronous)
  Future<String> generateAudioFromScript(
    DialogueScript script, {
    String? ttsEngine,
  });

  /// Start audio generation asynchronously
  Future<String> startAudioGeneration(
    DialogueScript script, {
    String? ttsEngine,
  });

  /// Get status of an async task
  Future<TaskStatus> getTaskStatus(String taskId);

  /// Cancel an async task
  Future<void> cancelTask(String taskId);
}
