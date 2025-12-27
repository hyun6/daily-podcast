import '../models/podcast.dart';
import '../models/dialogue_script.dart';

abstract class PodcastRepository {
  Future<Podcast> generatePodcast(List<Source> sources, {String? ttsEngine});
  Future<List<Podcast>> getRecentPodcasts();

  /// Generate script only without audio
  Future<DialogueScript> generateScript(List<Source> sources);

  /// Generate audio from an existing script
  Future<String> generateAudioFromScript(
    DialogueScript script, {
    String? ttsEngine,
  });
}
