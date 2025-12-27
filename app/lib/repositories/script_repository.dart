import '../models/dialogue_script.dart';

abstract class ScriptRepository {
  Future<List<DialogueScript>> getSavedScripts();
  Future<void> saveScript(DialogueScript script);
  Future<void> deleteScript(DialogueScript script);
}
