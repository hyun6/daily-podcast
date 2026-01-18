import 'package:flutter/material.dart';
import '../models/dialogue_script.dart';

class ScriptView extends StatelessWidget {
  final DialogueScript script;
  final String? error;
  final VoidCallback? onGenerateAudio;
  final String? ttsEngine;
  final ValueChanged<String>? onTtsEngineChanged;
  final bool showControls;

  const ScriptView({
    super.key,
    required this.script,
    this.error,
    this.onGenerateAudio,
    this.ttsEngine,
    this.onTtsEngineChanged,
    this.showControls = true,
  });

  Color _getSpeakerColor(String speaker) {
    if (speaker.contains('A') || speaker.toLowerCase().contains('injoon')) {
      return Colors.blue;
    } else if (speaker.contains('B') ||
        speaker.toLowerCase().contains('sunhi')) {
      return Colors.pink;
    }
    return Colors.grey;
  }

  IconData _getEmotionIcon(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'excited':
        return Icons.celebration;
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_very_dissatisfied;
      case 'neutral':
      default:
        return Icons.sentiment_neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with title
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                script.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.format_list_numbered,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${script.lines.length}개의 대사',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '약 ${(script.lines.length * 3 / 60).ceil()}분',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Error message if any
        if (error != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ],
            ),
          ),

        // Script lines
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: script.lines.length,
            itemBuilder: (context, index) {
              final line = script.lines[index];
              final isHostA =
                  line.speaker.contains('A') ||
                  line.speaker.toLowerCase().contains('injoon');

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Speaker avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getSpeakerColor(
                        line.speaker,
                      ).withValues(alpha: 0.2),
                      child: Text(
                        isHostA ? 'A' : 'B',
                        style: TextStyle(
                          color: _getSpeakerColor(line.speaker),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Dialogue content
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getSpeakerColor(
                            line.speaker,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getSpeakerColor(
                              line.speaker,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  line.speaker,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getSpeakerColor(line.speaker),
                                  ),
                                ),
                                if (line.emotion != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    _getEmotionIcon(line.emotion),
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              line.text,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom action bar (conditionally shown)
        if (showControls && onGenerateAudio != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // TTS Engine selector
                  if (ttsEngine != null)
                    Row(
                      children: [
                        const Text(
                          'TTS 엔진: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'Edge TTS (Fast & Natural)',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Generate Audio button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onGenerateAudio,
                      icon: const Icon(Icons.mic),
                      label: const Text('팟캐스트 생성'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
