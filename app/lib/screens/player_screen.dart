import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class PlayerScreen extends StatefulWidget {
  final String? audioPath;
  final String? title;

  const PlayerScreen({super.key, this.audioPath, this.title});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    if (widget.audioPath != null) {
      _loadAudio(widget.audioPath!);
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        _duration = newDuration;
      });
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        _position = newPosition;
      });
    });
  }

  Future<void> _loadAudio(String path) async {
    // For local files or URLs. Handled by Source
    // If it's a local file path, Source.deviceFile
    // If URL, Source.url
    // Assuming URL or asset for now.
    // For this mock, we might struggle with "mock_path.mp3" unless we put it in assets.
    // Let's assume URL for real implementation.
    // For mock, we can ignore or try to load a dummy.
    try {
      // Example: await _audioPlayer.setSourceUrl(path);
    } catch (e) {
      print("Error loading audio: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Podcast Player')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 120, color: Colors.deepPurple),
            const SizedBox(height: 32),
            Text(
              widget.title ?? "No Episode Selected",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Slider(
              min: 0,
              max: _duration.inSeconds.toDouble(),
              value: _position.inSeconds.toDouble(),
              onChanged: (value) async {
                final position = Duration(seconds: value.toInt());
                await _audioPlayer.seek(position);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position)),
                  Text(_formatDuration(_duration)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 35,
              child: IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                iconSize: 40,
                onPressed: () async {
                  if (_isPlaying) {
                    await _audioPlayer.pause();
                  } else {
                    // Resume or Play
                    // For Mock, this won't work without a real file.
                    // In real integration, we will path the URL.
                    await _audioPlayer.resume();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
