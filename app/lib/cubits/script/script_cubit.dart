import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/script_repository.dart';
import '../../models/dialogue_script.dart';
import 'script_state.dart';

class ScriptCubit extends Cubit<ScriptState> {
  final ScriptRepository _repository;

  ScriptCubit(this._repository) : super(ScriptInitial()) {
    loadScripts();
  }

  Future<void> loadScripts() async {
    emit(ScriptLoading());
    try {
      final scripts = await _repository.getSavedScripts();
      emit(ScriptLoaded(scripts: scripts));
    } catch (e) {
      emit(ScriptError("Failed to load scripts: $e"));
    }
  }

  Future<void> saveScript(DialogueScript script) async {
    try {
      await _repository.saveScript(script);
      // Reload to ensure consistency
      loadScripts();
    } catch (e) {
      emit(ScriptError("Failed to save script: $e"));
      // Or retain previous loaded state with error
    }
  }

  Future<void> deleteScript(DialogueScript script) async {
    try {
      await _repository.deleteScript(script);
      loadScripts();
    } catch (e) {
      emit(ScriptError("Failed to delete script: $e"));
    }
  }

  /// Helper to find a script matching a podcast title
  DialogueScript? findScriptForPodcast(String podcastTitle) {
    if (state is ScriptLoaded) {
      final scripts = (state as ScriptLoaded).scripts;
      // Remove extension if present
      final title = podcastTitle.replaceAll(RegExp(r'\.(mp3|wav|m4a)$'), '');
      try {
        return scripts.firstWhere(
          (s) => s.title == title || s.title == podcastTitle,
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
