/// Represents a single line of dialogue in a podcast script.
class DialogueLine {
  final String speaker;
  final String text;
  final String? emotion;

  DialogueLine({required this.speaker, required this.text, this.emotion});

  factory DialogueLine.fromJson(Map<String, dynamic> json) {
    return DialogueLine(
      speaker: json['speaker'] ?? '',
      text: json['text'] ?? '',
      emotion: json['emotion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'speaker': speaker, 'text': text, 'emotion': emotion};
  }
}

/// Represents a complete podcast script with dialogue lines.
class DialogueScript {
  final String title;
  final List<DialogueLine> lines;
  final DateTime createdAt;

  DialogueScript({
    required this.title,
    required this.lines,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DialogueScript.fromJson(Map<String, dynamic> json) {
    final linesList =
        (json['lines'] as List<dynamic>?)
            ?.map((line) => DialogueLine.fromJson(line as Map<String, dynamic>))
            .toList() ??
        [];

    return DialogueScript(
      title: json['title'] ?? 'Untitled',
      lines: linesList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'lines': lines.map((line) => line.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
