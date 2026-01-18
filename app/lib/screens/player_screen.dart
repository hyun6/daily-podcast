import 'dart:async';
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
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    if (widget.audioPath != null) {
      _loadAudio(widget.audioPath!);
    }
  }

  void _setupAudioPlayer() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((
      newDuration,
    ) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((
      newPosition,
    ) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  Future<void> _loadAudio(String path) async {
    try {
      debugPrint("[PlayerScreen] Loading audio from: $path");
      // Check if it's a URL or local file
      if (path.startsWith('http://') || path.startsWith('https://')) {
        await _audioPlayer.setSourceUrl(path);
      } else {
        await _audioPlayer.setSourceDeviceFile(path);
      }
      debugPrint("[PlayerScreen] Audio loaded successfully");
    } catch (e) {
      debugPrint("[PlayerScreen] Error loading audio: $e");
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
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
            const SizedBox(height: 24),
            // Volume Control
            Row(
              children: [
                const Icon(Icons.volume_down, color: Colors.deepPurple),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: 1,
                    value: _volume,
                    activeColor: Colors.deepPurple,
                    onChanged: (value) async {
                      setState(() {
                        _volume = value;
                      });
                      await _audioPlayer.setVolume(value);
                    },
                  ),
                ),
                const Icon(Icons.volume_up, color: Colors.deepPurple),
              ],
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            // Playback Speed Control
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.speed, color: Colors.deepPurple),
                const SizedBox(width: 8),
                DropdownButton<double>(
                  value: _playbackSpeed,
                  underline: Container(),
                  items: _speedOptions.map((speed) {
                    return DropdownMenuItem(
                      value: speed,
                      child: Text(
                        '${speed}x',
                        style: TextStyle(
                          fontWeight: speed == _playbackSpeed
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Colors.deepPurple,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _playbackSpeed = value;
                      });
                      await _audioPlayer.setPlaybackRate(value);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
