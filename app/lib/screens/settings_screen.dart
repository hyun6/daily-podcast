import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/generation/generation_cubit.dart';
import '../cubits/generation/generation_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<GenerationCubit, GenerationState>(
        builder: (context, state) {
          final cubit = context.read<GenerationCubit>();
          return ListView(
            children: [
              const ListTile(
                title: Text("Backend URL"),
                subtitle: Text("http://localhost:8000"),
                trailing: Icon(Icons.edit),
              ),
              ListTile(
                title: const Text("TTS Engine"),
                subtitle: Text(
                  cubit.ttsEngine == 'qwen'
                      ? 'Qwen TTS (Local, High Quality)'
                      : 'Edge TTS (Fast, Cloud)',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showEngineSelectionDialog(context, cubit),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEngineSelectionDialog(BuildContext context, GenerationCubit cubit) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select TTS Engine'),
          content: RadioGroup<String>(
            groupValue: cubit.ttsEngine,
            onChanged: (value) {
              if (value != null) {
                cubit.setTtsEngine(value);
                setState(() {}); // Rebuild to update subtitle
                Navigator.pop(context);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Edge TTS (Fast, Cloud)'),
                  value: 'edge-tts',
                ),
                RadioListTile<String>(
                  title: const Text('Qwen TTS (Local, High Quality)'),
                  value: 'qwen',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
