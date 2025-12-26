import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/podcast_provider.dart';
import 'repositories/mock_podcast_repository.dart';
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
          create: (_) => PodcastProvider(MockPodcastRepository()),
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
