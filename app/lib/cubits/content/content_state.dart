import 'package:equatable/equatable.dart';
import '../../models/podcast.dart';

abstract class ContentState extends Equatable {
  const ContentState();

  @override
  List<Object?> get props => [];
}

class ContentLoading extends ContentState {}

class ContentLoaded extends ContentState {
  final List<Podcast> podcasts;

  const ContentLoaded(this.podcasts);

  @override
  List<Object?> get props => [podcasts];
}

class ContentError extends ContentState {
  final String message;

  const ContentError(this.message);

  @override
  List<Object?> get props => [message];
}
