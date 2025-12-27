import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/podcast.dart';
import '../providers/podcast_provider.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSwitchToScriptTab;

  const HomeScreen({super.key, this.onSwitchToScriptTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _selectedType = 'rss';

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Source? _createSource() {
    final url = _urlController.text;
    final name = _nameController.text;
    if (url.isEmpty) return null;

    return Source(
      id: DateTime.now().toString(),
      url: url,
      type: _selectedType,
      name: name.isNotEmpty ? name : null,
    );
  }

  void _generatePodcast() {
    final source = _createSource();
    if (source == null) return;
    context.read<PodcastProvider>().generatePodcast([source]);
  }

  void _generateScriptOnly() {
    final source = _createSource();
    if (source == null) return;
    context.read<PodcastProvider>().generateScriptOnly([source]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Podcast')),
      body: Consumer<PodcastProvider>(
        builder: (context, provider, child) {
          // Show loading for direct podcast generation
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("팟캐스트 생성 중..."),
                  SizedBox(height: 8),
                  Text(
                    "스크립트 작성 및 오디오 생성",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Show loading for script-only generation
          if (provider.isGeneratingScript) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("스크립트 생성 중..."),
                  SizedBox(height: 8),
                  Text(
                    "AI가 대본을 작성하고 있습니다",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (provider.error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                            provider.error!,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => provider.clearError(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Source Type'),
                  items: const [
                    DropdownMenuItem(value: 'rss', child: Text('RSS Feed')),
                    DropdownMenuItem(
                      value: 'web',
                      child: Text('Web Page / Blog'),
                    ),
                    DropdownMenuItem(
                      value: 'youtube',
                      child: Text('YouTube Video'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Source Name (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Two buttons: Script only vs Full podcast
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _generateScriptOnly,
                        icon: const Icon(Icons.article),
                        label: const Text('스크립트 생성'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _generatePodcast,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('바로 생성'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),

                // Show script preview hint
                if (provider.currentScript != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '스크립트가 생성되었습니다: "${provider.currentScript!.title}"',
                            style: TextStyle(color: Colors.green.shade800),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onSwitchToScriptTab,
                          child: const Text('보기'),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),
                const Text(
                  "Recent Episodes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.recentPodcasts.length,
                    itemBuilder: (context, index) {
                      final podcast = provider.recentPodcasts[index];
                      return ListTile(
                        leading: const Icon(Icons.podcasts),
                        title: Text(podcast.metadata.title),
                        subtitle: Text(
                          "${podcast.metadata.createdAt.toString().split('.')[0]} • ${podcast.metadata.sourceNames.join(', ')}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Navigate to PlayerScreen
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(
                                audioPath: podcast.filePath,
                                title: podcast.metadata.title,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
