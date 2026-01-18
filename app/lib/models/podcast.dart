class Source {
  final String id;
  final String url;
  final String type; // 'rss', 'web', 'youtube'
  final String? name;

  Source({required this.id, required this.url, required this.type, this.name});
}

class PodcastMetadata {
  final String title;
  final List<String> sourceNames;
  final DateTime createdAt;

  PodcastMetadata({
    required this.title,
    required this.sourceNames,
    required this.createdAt,
  });

  factory PodcastMetadata.fromJson(Map<String, dynamic> json) {
    return PodcastMetadata(
      title: json['title'] ?? 'Untitled',
      sourceNames: List<String>.from(json['sources'] ?? []),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'sources': sourceNames,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Podcast {
  final String? filePath; // Local path or URL
  final PodcastMetadata metadata;
  final bool isGenerating;
  final String? ttsEngineUsed; // Actual TTS engine used (may indicate fallback)

  Podcast({
    this.filePath,
    required this.metadata,
    this.isGenerating = false,
    this.ttsEngineUsed,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      filePath: json['filePath'],
      metadata: PodcastMetadata.fromJson(json['metadata'] ?? {}),
      isGenerating: false, // Don't persist generating state
      ttsEngineUsed: json['ttsEngineUsed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'metadata': metadata.toJson(),
      'ttsEngineUsed': ttsEngineUsed,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Podcast &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          metadata.title == other.metadata.title;

  @override
  int get hashCode => filePath.hashCode ^ metadata.title.hashCode;
}
