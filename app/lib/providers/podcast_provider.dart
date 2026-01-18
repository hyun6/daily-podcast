import 'package:flutter/foundation.dart';
import '../models/podcast.dart';
import '../models/dialogue_script.dart';
import '../repositories/podcast_repository.dart';
import '../repositories/script_repository.dart';

class PodcastProvider extends ChangeNotifier {
  final PodcastRepository _repository;
  final ScriptRepository _scriptRepository;

  List<Podcast> _recentPodcasts = [];
  bool _isLoading = false;
  Podcast? _currentPodcast;
  String? _error;

  String _ttsEngine = 'edge-tts';

  // Script-related state
  DialogueScript? _currentScript;
  List<DialogueScript> _savedScripts = [];
  List<Source>? _currentSources;
  bool _isGeneratingScript = false;
  bool _isGeneratingAudio = false;

  // Task/Progress related state
  String? _currentTaskId;
  double _audioProgress = 0.0;

  PodcastProvider(this._repository, this._scriptRepository) {
    _loadRecents();
    loadSavedScripts();
  }

  List<Podcast> get recentPodcasts => _recentPodcasts;
  List<DialogueScript> get savedScripts => _savedScripts;
  bool get isLoading => _isLoading;
  Podcast? get currentPodcast => _currentPodcast;
  String? get error => _error;
  String get ttsEngine => _ttsEngine;

  // Script getters
  DialogueScript? get currentScript => _currentScript;
  List<Source>? get currentSources => _currentSources;
  bool get isGeneratingScript => _isGeneratingScript;
  bool get isGeneratingAudio => _isGeneratingAudio;
  double get audioProgress => _audioProgress;

  void setTtsEngine(String engine) {
    _ttsEngine = engine;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearScript() {
    _currentScript = null;
    _currentSources = null;
    notifyListeners();
  }

  Future<void> _loadRecents() async {
    try {
      _recentPodcasts = await _repository.getRecentPodcasts();
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load recents: $e");
    }
  }

  Future<void> loadSavedScripts() async {
    try {
      _savedScripts = await _scriptRepository.getSavedScripts();
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load saved scripts: $e");
    }
  }

  Future<void> deleteSavedScript(DialogueScript script) async {
    try {
      await _scriptRepository.deleteScript(script);
      await loadSavedScripts();
    } catch (e) {
      _error = "스크립트 삭제 실패: $e";
      notifyListeners();
    }
  }

  void loadScriptFromHistory(DialogueScript script) {
    _currentScript = script;
    _currentSources =
        null; // We don't have sources for saved scripts yet unless we save them too
    _error = null;
    notifyListeners();
  }

  Future<void> saveCurrentScript() async {
    if (_currentScript == null) return;
    try {
      await _scriptRepository.saveScript(_currentScript!);
      await loadSavedScripts();
    } catch (e) {
      _error = "스크립트 저장 실패: $e";
      notifyListeners();
    }
  }

  Future<void> generatePodcast(List<Source> sources) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentPodcast = await _repository.generatePodcast(
        sources,
        ttsEngine: _ttsEngine,
      );
      // Check for TTS engine fallback and set warning
      if (_currentPodcast != null) {
        final engineUsed = _currentPodcast!.ttsEngineUsed;
        if (engineUsed != null && engineUsed.contains('fallback')) {
          _error = '⚠️ 엔진 초기화 실패로 Edge TTS가 대신 사용되었습니다.';
        }
        _recentPodcasts.insert(0, _currentPodcast!);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate script only without audio
  Future<void> generateScriptOnly(List<Source> sources) async {
    _isGeneratingScript = true;
    _error = null;
    _currentSources = sources;
    notifyListeners();

    try {
      _currentScript = await _repository.generateScript(sources);
      // Auto-save the generated script
      await _scriptRepository.saveScript(_currentScript!);
      await loadSavedScripts();
    } catch (e) {
      _error = e.toString();
      _currentScript = null;
    } finally {
      _isGeneratingScript = false;
      notifyListeners();
    }
  }

  /// Cancel current audio generation
  Future<void> cancelAudioGeneration() async {
    // Stop the generation regardless of whether we have a taskId
    // This handles the case where the user cancels before taskId is assigned
    final taskIdToCancel = _currentTaskId;

    // Always reset the state first to stop polling loop immediately
    _isGeneratingAudio = false;
    _currentTaskId = null;
    _audioProgress = 0.0;
    notifyListeners();

    // Then try to cancel on the server if we have a taskId
    if (taskIdToCancel != null) {
      try {
        await _repository.cancelTask(taskIdToCancel);
      } catch (e) {
        debugPrint("Server cancellation failed: $e");
        // State is already reset, so user can try again
      }
    }
  }

  /// Generate audio from current script using async polling
  Future<void> generateAudioFromCurrentScript() async {
    if (_currentScript == null) {
      _error = '스크립트가 없습니다. 먼저 스크립트를 생성해주세요.';
      notifyListeners();
      return;
    }

    _isGeneratingAudio = true;
    _error = null;
    _audioProgress = 0.0;
    notifyListeners();

    try {
      // 1. Start the task
      _currentTaskId = await _repository.startAudioGeneration(
        _currentScript!,
        ttsEngine: _ttsEngine,
      );

      if (_currentTaskId == null) {
        throw Exception("Task ID was not returned from server.");
      }

      // 2. Poll for status
      bool isDone = false;
      while (!isDone && _isGeneratingAudio) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!_isGeneratingAudio) break; // Check if cancelled during delay

        final status = await _repository.getTaskStatus(_currentTaskId!);
        _audioProgress = status.progress;
        notifyListeners();

        if (status.isCompleted) {
          isDone = true;
          // Create a Podcast from the result
          _currentPodcast = Podcast(
            filePath: status.result!,
            metadata: PodcastMetadata(
              title: _currentScript!.title,
              sourceNames:
                  _currentSources?.map((s) => s.name ?? s.url).toList() ?? [],
              createdAt: DateTime.now(),
            ),
            ttsEngineUsed: _ttsEngine,
          );
          _recentPodcasts.insert(0, _currentPodcast!);
        } else if (status.isFailed) {
          throw Exception(status.error ?? "오디오 생성 실패");
        } else if (status.isCancelled) {
          isDone = true;
          _isGeneratingAudio = false;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isGeneratingAudio = false;
      _currentTaskId = null;
      _audioProgress = 1.0;
      notifyListeners();
    }
  }

  Future<void> deletePodcast(Podcast podcast) async {
    if (podcast.filePath == null) {
      _recentPodcasts.remove(podcast);
      notifyListeners();
      return;
    }

    try {
      await _repository.deleteEpisode(podcast.filePath!);
      _recentPodcasts.remove(podcast);
      notifyListeners();
    } catch (e) {
      _error = "에피소드 삭제 실패: $e";
      notifyListeners();
    }
  }
}
