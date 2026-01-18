import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/podcast.dart';
import '../cubits/generation/generation_cubit.dart';
import '../cubits/generation/generation_state.dart';
import '../cubits/content/content_cubit.dart';
import '../cubits/content/content_state.dart';
import '../cubits/player/player_cubit.dart';
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
    context.read<GenerationCubit>().generateScript([source]);
  }

  void _generatePodcast() {
    final source = _createSource();
    if (source == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URL을 입력해주세요.')));
      return;
    }
    context.read<GenerationCubit>().generatePodcast([source]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Podcast')),
      body: BlocConsumer<GenerationCubit, GenerationState>(
        listener: (context, state) {
          if (state is GenerationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is GenerationPodcastSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("팟캐스트 생성 완료! 라이브러리에 추가되었습니다.")),
            );
            // Content refresh is handled by MainScreen coordinator
          }
          if (state is GenerationScriptSuccess) {
            // Maybe switch tab?
          }
        },
        builder: (context, genState) {
          if (genState is GenerationLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(genState.message ?? "처리 중..."),
                  const SizedBox(height: 8),
                  if (genState.progress > 0)
                    Text("진행률: ${(genState.progress * 100).toInt()}%"),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Inputs
                _buildInputSection(),

                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(),

                const SizedBox(height: 32),

                // Recent Episodes (from ContentCubit)
                const Text(
                  "Recent Episodes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(child: _buildRecentEpisodes()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
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
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
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
                  DropdownMenuItem(value: 'rss', child: Text('RSS Feed')),
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
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _generateScriptOnly,
            icon: const Icon(Icons.article),
            label: const Text('스크립트 생성'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _generatePodcast,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('바로 생성'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentEpisodes() {
    return BlocBuilder<ContentCubit, ContentState>(
      builder: (context, state) {
        if (state is ContentLoaded) {
          if (state.podcasts.isEmpty) {
            return const Center(child: Text("최근 에피소드가 없습니다."));
          }
          final recents = state.podcasts.take(5).toList(); // Show top 5
          return ListView.builder(
            itemCount: recents.length,
            itemBuilder: (context, index) {
              final podcast = recents[index];
              return ListTile(
                leading: const Icon(Icons.podcasts),
                title: Text(podcast.metadata.title),
                subtitle: Text(
                  podcast.metadata.createdAt.toString().split(' ')[0],
                  maxLines: 1,
                ),
                onTap: () {
                  context.read<PlayerCubit>().play(podcast);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                  );
                },
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
