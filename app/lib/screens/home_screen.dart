import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/podcast.dart';
import '../providers/podcast_provider.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  void _generatePodcast() {
    final url = _urlController.text;
    final name = _nameController.text;
    if (url.isEmpty) return;

    final source = Source(
      id: DateTime.now().toString(),
      url: url,
      type: _selectedType,
      name: name.isNotEmpty ? name : null,
    );

    context.read<PodcastProvider>().generatePodcast([source]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Podcast')),
      body: Consumer<PodcastProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Generating Script & Audio..."),
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
                    child: Text(
                      provider.error!,
                      style: TextStyle(color: Colors.red.shade900),
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
                ElevatedButton.icon(
                  onPressed: _generatePodcast,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate Daily Podcast'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
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
