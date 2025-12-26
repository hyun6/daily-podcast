import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text("Backend URL"),
            subtitle: Text("http://localhost:8000"),
            trailing: Icon(Icons.edit),
          ),
          ListTile(
            title: const Text("TTS Engine"),
            subtitle: const Text("Edge TTS"),
            trailing: DropdownButton<String>(
              value: 'edge-tts',
              items: const [
                DropdownMenuItem(value: 'edge-tts', child: Text('Edge TTS')),
                DropdownMenuItem(
                  value: 'chatterbox',
                  child: Text('Chatterbox'),
                ),
              ],
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}
