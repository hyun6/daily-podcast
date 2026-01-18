// Force rebuild
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
  final String? errorMessage;

  const ContentLoaded(this.podcasts, {this.errorMessage});

  @override
  List<Object?> get props => [podcasts, errorMessage];
}

class ContentError extends ContentState {
  final String message;

  const ContentError(this.message);

  @override
  List<Object?> get props => [message];
}
