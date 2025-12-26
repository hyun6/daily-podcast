import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/podcast_provider.dart';
import 'repositories/real_podcast_repository.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const DailyPodcastApp());
}

class DailyPodcastApp extends StatelessWidget {
  const DailyPodcastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          // Use localhost for macOS/iOS Simulator. Use 10.0.2.2 for Android Emulator.
          create: (_) => PodcastProvider(
            RealPodcastRepository(baseUrl: 'http://127.0.0.1:8000'),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Daily AI Podcast',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}
