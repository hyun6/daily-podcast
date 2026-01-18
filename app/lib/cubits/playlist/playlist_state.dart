import 'package:equatable/equatable.dart';
import '../../models/podcast.dart';

class PlaylistState extends Equatable {
  final List<Podcast> playlist;

  const PlaylistState({this.playlist = const []});

  PlaylistState copyWith({List<Podcast>? playlist}) {
    return PlaylistState(playlist: playlist ?? this.playlist);
  }

  @override
  List<Object?> get props => [playlist];
}
