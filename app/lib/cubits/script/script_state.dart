import 'package:equatable/equatable.dart';
import '../../models/dialogue_script.dart';

abstract class ScriptState extends Equatable {
  const ScriptState();

  @override
  List<Object?> get props => [];
}

class ScriptInitial extends ScriptState {}

class ScriptLoading extends ScriptState {}

class ScriptLoaded extends ScriptState {
  final List<DialogueScript> scripts;
  final DialogueScript? currentScript;

  const ScriptLoaded({this.scripts = const [], this.currentScript});

  ScriptLoaded copyWith({
    List<DialogueScript>? scripts,
    DialogueScript? currentScript,
  }) {
    return ScriptLoaded(
      scripts: scripts ?? this.scripts,
      currentScript: currentScript ?? this.currentScript,
    );
  }

  @override
  List<Object?> get props => [scripts, currentScript];
}

class ScriptError extends ScriptState {
  final String message;

  const ScriptError(this.message);

  @override
  List<Object?> get props => [message];
}
