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
  String _selectedType = 'web';
  bool _isAutoDetected = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final url = _urlController.text.toLowerCase();
    String? detectedType;

    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      detectedType = 'youtube';
    } else if (url.contains('.rss') ||
        url.contains('.xml') ||
        url.contains('/feed') ||
        url.contains('rss')) {
      detectedType = 'rss';
    } else if (url.isNotEmpty) {
      detectedType = 'web';
    }

    if (detectedType != null && detectedType != _selectedType) {
      setState(() {
        _selectedType = detectedType!;
        _isAutoDetected = true;
      });
    } else if (url.isEmpty) {
      setState(() => _isAutoDetected = false);
    }
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

  void _generateScriptOnly() {
    final source = _createSource();
    if (source == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URL을 입력해주세요.')));
      return;
    }
    context.read<PodcastProvider>().generateScriptOnly([source]);
  }

  void _generatePodcast() {
    final source = _createSource();
    if (source == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URL을 입력해주세요.')));
      return;
    }
    context.read<PodcastProvider>().generatePodcast([source]);
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
                // URL 입력 (먼저)
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.link),
                    suffixIcon: _urlController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _urlController.clear();
                              setState(() => _isAutoDetected = false);
                            },
                          )
                        : null,
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // 소스 타입 (자동 감지 표시)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Source Type',
                          suffixIcon: _isAutoDetected
                              ? Tooltip(
                                  message: 'URL에서 자동 감지됨',
                                  child: Icon(
                                    Icons.auto_awesome,
                                    size: 18,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                )
                              : null,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'web',
                            child: Text('Web Page / Blog'),
                          ),
                          DropdownMenuItem(
                            value: 'rss',
                            child: Text('RSS Feed'),
                          ),
                          DropdownMenuItem(
                            value: 'youtube',
                            child: Text('YouTube Video'),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedType = val!;
                            _isAutoDetected = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 소스 이름 (선택적)
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Source Name (Optional)',
                    hintText: '예: 기술 블로그, 뉴스 피드...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  textInputAction: TextInputAction.done,
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
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("에피소드 삭제"),
                                content: const Text("정말 이 에피소드를 삭제하시겠습니까?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("취소"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      "삭제",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              if (!context.mounted) return;
                              await context
                                  .read<PodcastProvider>()
                                  .deletePodcast(podcast);
                            }
                          },
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
