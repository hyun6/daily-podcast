import 'package:flutter/foundation.dart';
import '../models/podcast.dart';
import '../repositories/podcast_repository.dart';

class PodcastProvider extends ChangeNotifier {
  final PodcastRepository _repository;

  List<Podcast> _recentPodcasts = [];
  bool _isLoading = false;
  Podcast? _currentPodcast;
  String? _error;

  String _ttsEngine = 'chatterbox';

  PodcastProvider(this._repository) {
    _loadRecents();
  }

  List<Podcast> get recentPodcasts => _recentPodcasts;
  bool get isLoading => _isLoading;
  Podcast? get currentPodcast => _currentPodcast;
  String? get error => _error;
  String get ttsEngine => _ttsEngine;

  void setTtsEngine(String engine) {
    _ttsEngine = engine;
    notifyListeners();
  }

  Future<void> _loadRecents() async {
    try {
      _recentPodcasts = await _repository.getRecentPodcasts();
      notifyListeners();
    } catch (e) {
      print("Failed to load recents: $e");
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
          _error = '⚠️ Chatterbox 초기화 실패로 Edge TTS가 대신 사용되었습니다.';
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
}
