import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/podcast_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<PodcastProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              const ListTile(
                title: Text("Backend URL"),
                subtitle: Text("http://localhost:8000"),
                trailing: Icon(Icons.edit),
              ),
              ListTile(
                title: const Text("TTS Engine"),
                subtitle: Text(provider.ttsEngine),
                trailing: DropdownButton<String>(
                  value: provider.ttsEngine,
                  items: const [
                    DropdownMenuItem(
                      value: 'edge-tts',
                      child: Text('Edge TTS'),
                    ),
                    DropdownMenuItem(
                      value: 'chatterbox',
                      child: Text('Chatterbox'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      provider.setTtsEngine(val);
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
