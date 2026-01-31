import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/podcast_repository.dart';
import '../../repositories/script_repository.dart';
import '../../models/podcast.dart';
import '../../models/dialogue_script.dart';
import 'generation_state.dart';

import 'package:shared_preferences/shared_preferences.dart';

class GenerationCubit extends Cubit<GenerationState> {
  final PodcastRepository _podcastRepository;
  final ScriptRepository _scriptRepository;

  String? _currentTaskId;
  bool _isCancelled = false;
  String _ttsEngine = 'edge-tts';

  GenerationCubit({
    required PodcastRepository podcastRepository,
    required ScriptRepository scriptRepository,
  }) : _podcastRepository = podcastRepository,
       _scriptRepository = scriptRepository,
       super(GenerationInitial()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _ttsEngine = prefs.getString('tts_engine') ?? 'edge-tts';
  }

  void setTtsEngine(String engine) async {
    _ttsEngine = engine;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_engine', engine);
  }

  String get ttsEngine => _ttsEngine;

  Future<void> generateScript(List<Source> sources) async {
    emit(const GenerationLoading(message: "Generating Script..."));
    try {
      final script = await _podcastRepository.generateScript(sources);
      // Auto-save
      await _scriptRepository.saveScript(script);
      emit(GenerationScriptSuccess(script));
    } catch (e) {
      emit(GenerationError("Script generation failed: $e"));
    }
  }

  // Legacy synchronous generation (kept for compatibility)
  Future<void> generatePodcast(List<Source> sources) async {
    emit(const GenerationLoading(message: "Generating Podcast..."));
    try {
      final podcast = await _podcastRepository.generatePodcast(
        sources,
        ttsEngine: _ttsEngine,
      );
      // Check for fallback warning
      if (podcast.ttsEngineUsed != null &&
          podcast.ttsEngineUsed!.contains('fallback')) {
        // We can treat this as success but maybe user needs to know.
        // For now just emit success.
      }
      emit(GenerationPodcastSuccess(podcast));
    } catch (e) {
      emit(GenerationError("Podcast generation failed: $e"));
    }
  }

  Future<void> generateAudio(
    DialogueScript script, {
    List<String>? sourceNames,
  }) async {
    _isCancelled = false;
    emit(
      const GenerationLoading(
        message: "Starting Audio Generation...",
        progress: 0.1,
      ),
    );
    _currentTaskId = null;

    try {
      // 1. Start Task
      _currentTaskId = await _podcastRepository.startAudioGeneration(
        script,
        ttsEngine: _ttsEngine,
      );

      if (_currentTaskId == null) {
        throw Exception("Failed to start generation task");
      }

      // 2. Poll
      bool isDone = false;
      while (!isDone && !_isCancelled) {
        await Future.delayed(const Duration(seconds: 1));
        if (_isCancelled) break;

        final status = await _podcastRepository.getTaskStatus(_currentTaskId!);

        if (_isCancelled) break; // Check again after await

        emit(
          GenerationLoading(message: status.status, progress: status.progress),
        );

        if (status.isCompleted) {
          isDone = true;
          final podcast = Podcast(
            filePath: status.result!,
            metadata: PodcastMetadata(
              title: script.title,
              sourceNames: sourceNames ?? [],
              createdAt: DateTime.now(),
            ),
            ttsEngineUsed: _ttsEngine,
          );
          emit(GenerationPodcastSuccess(podcast));
        } else if (status.isFailed) {
          throw Exception(status.error ?? "Unknown error during generation");
        } else if (status.isCancelled) {
          emit(GenerationInitial()); // Reset
          isDone = true;
        }
      }
    } catch (e) {
      if (!_isCancelled) {
        emit(GenerationError(e.toString()));
      }
    }
  }

  Future<void> cancelGeneration() async {
    _isCancelled = true;
    final taskId = _currentTaskId;

    emit(GenerationInitial());

    if (taskId != null) {
      try {
        await _podcastRepository.cancelTask(taskId);
      } catch (e) {
        // Ignore cancellation errors
      }
    }
    _currentTaskId = null;
  }
}
