import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/generation/generation_cubit.dart';
import '../cubits/generation/generation_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                subtitle: Text("Current: ${cubit.ttsEngine}"),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
                onTap: () {
                  // Example to toggle engine
                  // cubit.setTtsEngine('other-engine');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
