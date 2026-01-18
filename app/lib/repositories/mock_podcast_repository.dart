import 'dart:async';
import '../models/podcast.dart';
import '../models/dialogue_script.dart';
import '../models/task_status.dart';
import 'podcast_repository.dart';

class MockPodcastRepository implements PodcastRepository {
  @override
  Future<Podcast> generatePodcast(
    List<Source> sources, {
    String? ttsEngine,
  }) async {
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

  @override
  Future<DialogueScript> generateScript(List<Source> sources) async {
    await Future.delayed(const Duration(seconds: 2));

    return DialogueScript(
      title: "Mock 팟캐스트 스크립트",
      lines: [
        DialogueLine(
          speaker: "Host A",
          text: "안녕하세요, 오늘의 AI 소식을 전해드립니다.",
          emotion: "neutral",
        ),
        DialogueLine(
          speaker: "Host B",
          text: "정말 흥미로운 소식들이 많네요!",
          emotion: "excited",
        ),
        DialogueLine(
          speaker: "Host A",
          text: "네, 오늘은 ${sources.length}개의 소스에서 정보를 가져왔습니다.",
          emotion: "neutral",
        ),
      ],
    );
  }

  @override
  Future<String> generateAudioFromScript(
    DialogueScript script, {
    String? ttsEngine,
  }) async {
    await Future.delayed(const Duration(seconds: 3));
    return "mock_audio_from_script.mp3";
  }

  @override
  Future<String> startAudioGeneration(
    DialogueScript script, {
    String? ttsEngine,
  }) async {
    return "mock_task_id";
  }

  @override
  Future<TaskStatus> getTaskStatus(String taskId) async {
    return TaskStatus(
      taskId: taskId,
      status: "completed",
      progress: 1.0,
      result: "mock_polled_audio.mp3",
    );
  }

  @override
  Future<void> cancelTask(String taskId) async {
    // Mock cancellation
  }

  @override
  Future<void> deleteEpisode(String filePath) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<bool> healthCheck() async {
    return true;
  }
}
