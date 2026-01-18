import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/content/content_cubit.dart';
import '../cubits/content/content_state.dart';
import '../cubits/playlist/playlist_cubit.dart';
import '../cubits/player/player_cubit.dart';
import '../models/podcast.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  @override
  void initState() {
    super.initState();
    // Load content if not loaded? The Cubit loads on init, so maybe just refresh if needed.
    // context.read<ContentCubit>().fetchContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('콘텐츠 라이브러리'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ContentCubit>().fetchContent();
            },
          ),
        ],
      ),
      body: BlocBuilder<ContentCubit, ContentState>(
        builder: (context, state) {
          if (state is ContentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ContentError) {
            return Center(child: Text("오류 발생: ${state.message}"));
          }

          if (state is ContentLoaded) {
            if (state.podcasts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.perm_media_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '저장된 팟캐스트가 없습니다.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.podcasts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final podcast = state.podcasts[index];
                return _buildPodcastItem(context, podcast);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPodcastItem(BuildContext context, Podcast podcast) {
    // We need to check if it's in playlist to update UI
    final isInPlaylist = context.select<PlaylistCubit, bool>(
      (cubit) => cubit.state.playlist.contains(podcast),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        podcast.metadata.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '생성일: ${podcast.metadata.createdAt.toString().split(' ')[0]}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    context.read<PlayerCubit>().play(podcast);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${podcast.metadata.title} 재생 시작'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: Icon(
                    isInPlaylist
                        ? Icons.playlist_add_check
                        : Icons.playlist_add,
                  ),
                  label: Text(isInPlaylist ? '추가됨' : '재생목록 추가'),
                  onPressed: isInPlaylist
                      ? null
                      : () {
                          context.read<PlaylistCubit>().addToPlaylist(podcast);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('재생목록에 추가되었습니다.')),
                          );
                        },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('삭제', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    _confirmDelete(context, podcast);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Podcast podcast) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말로 이 에피소드를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // Delete from Content and Playlist
              context.read<ContentCubit>().deleteContent(podcast);
              context.read<PlaylistCubit>().removeFromPlaylist(podcast);
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
