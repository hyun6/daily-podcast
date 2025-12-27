import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dialogue_script.dart';
import '../providers/podcast_provider.dart';
import 'player_screen.dart';

/// Screen to view and generate audio from the podcast script.
class ScriptScreen extends StatelessWidget {
  const ScriptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PodcastProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('스크립트'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (provider.currentScript != null)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: '스크립트 저장',
              onPressed: () async {
                await provider.saveCurrentScript();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('스크립트가 저장되었습니다.')),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showSavedScripts(context),
          ),
        ],
      ),
      body: Consumer<PodcastProvider>(
        builder: (context, provider, child) {
          // Loading state for script generation
          if (provider.isGeneratingScript) {
            return const _LoadingState(
              message: '스크립트 생성 중...',
              subMessage: 'AI가 대본을 작성하고 있습니다',
            );
          }

          // Loading state for audio generation
          if (provider.isGeneratingAudio) {
            return const _LoadingState(
              message: '오디오 생성 중...',
              subMessage: 'TTS로 팟캐스트를 만들고 있습니다',
            );
          }

          // Empty state
          if (provider.currentScript == null) {
            return _EmptyState(onViewHistory: () => _showSavedScripts(context));
          }

          // Script display
          return _ScriptContent(
            script: provider.currentScript!,
            error: provider.error,
            onGenerateAudio: () {
              provider.generateAudioFromCurrentScript().then((_) {
                if (provider.currentPodcast != null && provider.error == null) {
                  // Navigate to player screen on success
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(
                        audioPath: provider.currentPodcast!.filePath,
                        title: provider.currentPodcast!.metadata.title,
                      ),
                    ),
                  );
                }
              });
            },
            ttsEngine: provider.ttsEngine,
            onTtsEngineChanged: (engine) => provider.setTtsEngine(engine),
          );
        },
      ),
    );
  }

  void _showSavedScripts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<PodcastProvider>(
              builder: (context, provider, child) {
                if (provider.savedScripts.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 60,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '저장된 스크립트가 없습니다.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '저장된 스크립트',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: provider.savedScripts.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final script = provider.savedScripts[index];
                          final date = script.createdAt;
                          final dateStr =
                              '${date.year}.${date.month}.${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                          return ListTile(
                            title: Text(
                              script.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              dateStr,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              child: Icon(
                                Icons.article,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            onTap: () {
                              provider.loadScriptFromHistory(script);
                              Navigator.pop(context);
                            },
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('스크립트 삭제'),
                                    content: const Text('이 스크립트를 삭제하시겠습니까?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('취소'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          provider.deleteSavedScript(script);
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                          '삭제',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  final String message;
  final String subMessage;

  const _LoadingState({required this.message, required this.subMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(message, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onViewHistory;

  const _EmptyState({this.onViewHistory});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              '스크립트가 없습니다',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              'Home 탭에서 "스크립트 생성" 버튼을 눌러\n스크립트를 먼저 생성해주세요.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
            if (onViewHistory != null) ...[
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: onViewHistory,
                icon: const Icon(Icons.history),
                label: const Text('저장된 스크립트 불러오기'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScriptContent extends StatelessWidget {
  final DialogueScript script;
  final String? error;
  final VoidCallback onGenerateAudio;
  final String ttsEngine;
  final ValueChanged<String> onTtsEngineChanged;

  const _ScriptContent({
    required this.script,
    required this.error,
    required this.onGenerateAudio,
    required this.ttsEngine,
    required this.onTtsEngineChanged,
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
                      ).withOpacity(0.2),
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
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getSpeakerColor(
                              line.speaker,
                            ).withOpacity(0.2),
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

        // Bottom action bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // TTS Engine selector
                Row(
                  children: [
                    const Text('TTS 엔진: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Chatterbox'),
                      selected: ttsEngine == 'chatterbox',
                      onSelected: (_) => onTtsEngineChanged('chatterbox'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Edge TTS'),
                      selected: ttsEngine == 'edge-tts',
                      onSelected: (_) => onTtsEngineChanged('edge-tts'),
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
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
