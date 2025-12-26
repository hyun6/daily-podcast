import 'package:flutter/foundation.dart';
import '../models/podcast.dart';
import '../repositories/podcast_repository.dart';

class PodcastProvider extends ChangeNotifier {
  final PodcastRepository _repository;

  List<Podcast> _recentPodcasts = [];
  bool _isLoading = false;
  Podcast? _currentPodcast;
  String? _error;

  PodcastProvider(this._repository) {
    _loadRecents();
  }

  List<Podcast> get recentPodcasts => _recentPodcasts;
  bool get isLoading => _isLoading;
  Podcast? get currentPodcast => _currentPodcast;
  String? get error => _error;

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
      _currentPodcast = await _repository.generatePodcast(sources);
      // Add to start of list
      if (_currentPodcast != null) {
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
