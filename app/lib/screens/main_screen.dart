import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/generation/generation_cubit.dart';
import '../cubits/generation/generation_state.dart';
import '../cubits/content/content_cubit.dart';
import '../cubits/player/player_cubit.dart';
import '../cubits/player/player_state.dart';
import '../cubits/playlist/playlist_cubit.dart';
import 'home_screen.dart';
import 'content_screen.dart';
import 'player_screen.dart';
import 'settings_screen.dart';

/// MainScreen acts as a coordinator for Cubit interactions.
/// It listens to GenerationCubit and triggers ContentCubit refresh on success.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _switchToTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onSwitchToScriptTab: () => _switchToTab(1)),
      const ContentScreen(),
      const PlayerScreen(),
      const SettingsScreen(),
    ];

    // Coordinator: Listen for GenerationCubit success and refresh ContentCubit
    // Coordinator: Listen for PlayerCubit completion and play next track
    return MultiBlocListener(
      listeners: [
        BlocListener<GenerationCubit, GenerationState>(
          listenWhen: (prev, curr) => curr is GenerationPodcastSuccess,
          listener: (context, state) {
            context.read<ContentCubit>().fetchContent();
          },
        ),
        BlocListener<PlayerCubit, PlayerState>(
          listenWhen: (prev, curr) =>
              prev.status != PlayerStatus.completed &&
              curr.status == PlayerStatus.completed,
          listener: (context, state) {
            final playlistCubit = context.read<PlaylistCubit>();
            final playlist = playlistCubit.state.playlist;
            final current = state.currentPodcast;

            if (current != null && playlist.isNotEmpty) {
              final currentIndex = playlist.indexOf(current);
              if (currentIndex != -1 && currentIndex < playlist.length - 1) {
                final nextPodcast = playlist[currentIndex + 1];
                context.read<PlayerCubit>().play(nextPodcast);
              }
            }
          },
        ),
      ],
      child: Scaffold(
        body: screens[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.library_music_outlined),
              selectedIcon: Icon(Icons.library_music),
              label: 'Content',
            ),
            NavigationDestination(
              icon: Icon(Icons.play_circle_outline),
              selectedIcon: Icon(Icons.play_circle),
              label: 'Player',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
