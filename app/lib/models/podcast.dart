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
}

class Podcast {
  final String? filePath; // Local path or URL
  final PodcastMetadata metadata;
  final bool isGenerating;

  Podcast({this.filePath, required this.metadata, this.isGenerating = false});
}
