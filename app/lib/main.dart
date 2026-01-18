import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'repositories/podcast_repository.dart';
import 'repositories/real_podcast_repository.dart';
import 'repositories/script_repository.dart';
import 'repositories/local_script_repository.dart';
import 'services/audio_player_service.dart';
import 'screens/main_screen.dart';
import 'cubits/content/content_cubit.dart';
import 'cubits/playlist/playlist_cubit.dart';
import 'cubits/player/player_cubit.dart';
import 'cubits/script/script_cubit.dart';
import 'cubits/generation/generation_cubit.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load .env file.
  // Note: For release builds, make sure .env is included in assets or handle errors.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found. Using default values.");
  }
  runApp(const DailyPodcastApp());
}

class DailyPodcastApp extends StatelessWidget {
  const DailyPodcastApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Repositories & Services
    // Load API URL from .env, default to localhost
    final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';

    final podcastRepository = RealPodcastRepository(baseUrl: apiBaseUrl);
    final scriptRepository = LocalScriptRepository();
    final audioPlayerService = AudioPlayerService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PodcastRepository>.value(value: podcastRepository),
        RepositoryProvider<ScriptRepository>.value(value: scriptRepository),
        RepositoryProvider<AudioPlayerService>.value(value: audioPlayerService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ContentCubit>(
            create: (context) => ContentCubit(podcastRepository),
          ),
          BlocProvider<PlaylistCubit>(create: (context) => PlaylistCubit()),
          BlocProvider<PlayerCubit>(
            create: (context) => PlayerCubit(
              AudioPlayerService(), // Singleton
            ),
          ),
          BlocProvider<ScriptCubit>(
            create: (context) => ScriptCubit(scriptRepository),
          ),
          BlocProvider<GenerationCubit>(
            create: (context) => GenerationCubit(
              podcastRepository: podcastRepository,
              scriptRepository: scriptRepository,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Daily Podcast',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const MainScreen(),
        ),
      ),
    );
  }
}
