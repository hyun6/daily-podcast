import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/player/player_cubit.dart';
import '../cubits/player/player_state.dart';
import '../cubits/playlist/playlist_cubit.dart';
import '../cubits/playlist/playlist_state.dart';
import '../cubits/script/script_cubit.dart';
import '../models/podcast.dart';
import '../widgets/script_view.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // Local state for UI toggles
  bool _showScript = false;
  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context) {
    // We listen to player state to update UI
    return BlocConsumer<PlayerCubit, PlayerState>(
      listenWhen: (previous, current) =>
          previous.currentPodcast != current.currentPodcast,
      listener: (context, state) {
        // If podcast changed, maybe try to load its script?
        // But ScriptCubit already loads everything. We just need to find it.
      },
      builder: (context, playerState) {
        final currentPodcast = playerState.currentPodcast;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Now Playing'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(_showScript ? Icons.music_note : Icons.description),
                onPressed: () {
                  setState(() {
                    _showScript = !_showScript;
                  });
                },
                tooltip: _showScript ? 'Show Cover' : 'Show Script',
              ),
            ],
          ),
          body: Column(
            children: [
              // Upper Area: Script or Cover
              Expanded(
                flex: 3,
                child: _showScript && currentPodcast != null
                    ? _buildScriptView(context, currentPodcast)
                    : _buildCoverView(currentPodcast),
              ),

              // Player Controls
              _buildPlayerControls(context, playerState),

              // Playlist Area
              const Divider(),
              Expanded(flex: 2, child: _buildPlaylist(context, currentPodcast)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScriptView(BuildContext context, Podcast podcast) {
    final scriptCubit = context.read<ScriptCubit>();
    final script = scriptCubit.findScriptForPodcast(podcast.metadata.title);

    if (script == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speaker_notes_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text("스크립트를 찾을 수 없습니다.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ScriptView(script: script, showControls: false),
    );
  }

  Widget _buildCoverView(Podcast? podcast) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade100,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.podcasts,
            size: 100,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            podcast?.metadata.title ?? "No Episode Selected",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerControls(BuildContext context, PlayerState state) {
    final cubit = context.read<PlayerCubit>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scrub Bar
          Slider(
            min: 0,
            max: state.duration.inSeconds.toDouble(),
            value: state.position.inSeconds
                .clamp(0, state.duration.inSeconds)
                .toDouble(),
            onChanged: (value) {
              final position = Duration(seconds: value.toInt());
              cubit.seek(position);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(state.position)),
                Text(_formatDuration(state.duration)),
              ],
            ),
          ),

          // Controls Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () {
                  final newPos = state.position - const Duration(seconds: 10);
                  cubit.seek(newPos < Duration.zero ? Duration.zero : newPos);
                },
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                  iconSize: 32,
                  onPressed: () {
                    if (state.isPlaying) {
                      cubit.pause();
                    } else if (state.currentPodcast != null) {
                      cubit.resume();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_30),
                onPressed: () {
                  final newPos = state.position + const Duration(seconds: 30);
                  final max = state.duration;
                  cubit.seek(newPos > max ? max : newPos);
                },
              ),
            ],
          ),

          // Speed & Volume Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.speed),
                onPressed: () => _showSpeedDialog(context, state.playbackSpeed),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () => _showVolumeDialog(context, state.volume),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSpeedDialog(BuildContext context, double currentSpeed) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        // Use new context if needed, but safe to use parent context for logic
        return SizedBox(
          height: 200,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "재생 속도",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _speedOptions.map((speed) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ChoiceChip(
                        label: Text('${speed}x'),
                        selected: currentSpeed == speed,
                        onSelected: (selected) {
                          if (selected) {
                            context.read<PlayerCubit>().setSpeed(speed);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVolumeDialog(BuildContext context, double currentVolume) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("볼륨 조절"),
          content: SizedBox(
            height: 50,
            child: StatefulBuilder(
              builder: (context, setStateLocal) {
                return Slider(
                  value: currentVolume,
                  min: 0,
                  max: 1,
                  onChanged: (val) {
                    // Optimistic update local
                    setStateLocal(() => currentVolume = val);
                    // Actual update
                    context.read<PlayerCubit>().setVolume(val);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("닫기"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaylist(BuildContext context, Podcast? currentPodcast) {
    return BlocBuilder<PlaylistCubit, PlaylistState>(
      builder: (context, state) {
        if (state.playlist.isEmpty) {
          return const Center(child: Text("재생목록이 비어있습니다."));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "재생목록 (${state.playlist.length})",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: state.playlist.length,
                onReorder: (oldIndex, newIndex) {
                  context.read<PlaylistCubit>().reorderPlaylist(
                    oldIndex,
                    newIndex,
                  );
                },
                itemBuilder: (context, index) {
                  final podcast = state.playlist[index];
                  final isCurrent = podcast == currentPodcast;

                  return ListTile(
                    key: ValueKey("${podcast.metadata.title}_$index"),
                    dense: true,
                    selected: isCurrent,
                    selectedTileColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    leading: Icon(
                      isCurrent ? Icons.graphic_eq : Icons.music_note,
                      color: isCurrent
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    title: Text(
                      podcast.metadata.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrent
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => context
                              .read<PlaylistCubit>()
                              .removeFromPlaylist(podcast),
                        ),
                        const Icon(Icons.drag_handle, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      context.read<PlayerCubit>().play(podcast);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$minutes:$seconds";
  }
}
