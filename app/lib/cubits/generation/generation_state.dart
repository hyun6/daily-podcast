import 'package:equatable/equatable.dart';
import '../../models/podcast.dart';
import '../../models/dialogue_script.dart';

abstract class GenerationState extends Equatable {
  const GenerationState();

  @override
  List<Object?> get props => [];
}

class GenerationInitial extends GenerationState {}

class GenerationLoading extends GenerationState {
  final String? message;
  final double progress;

  const GenerationLoading({this.message, this.progress = 0.0});

  @override
  List<Object?> get props => [message, progress];
}

class GenerationScriptSuccess extends GenerationState {
  final DialogueScript script;

  const GenerationScriptSuccess(this.script);

  @override
  List<Object?> get props => [script];
}

class GenerationPodcastSuccess extends GenerationState {
  final Podcast podcast;

  const GenerationPodcastSuccess(this.podcast);

  @override
  List<Object?> get props => [podcast];
}

class GenerationError extends GenerationState {
  final String message;

  const GenerationError(this.message);

  @override
  List<Object?> get props => [message];
}
