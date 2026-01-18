import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/dialogue_script.dart';
import 'script_repository.dart';

class LocalScriptRepository implements ScriptRepository {
  Future<Directory> _getScriptsDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final scriptsDir = Directory(path.join(docsDir.path, 'scripts'));
    if (!await scriptsDir.exists()) {
      await scriptsDir.create(recursive: true);
    }
    return scriptsDir;
  }

  String _getFileName(DialogueScript script) {
    // Use timestamp and title to create a unique filename
    final timestamp = script.createdAt.millisecondsSinceEpoch;
    // Sanitize title for filename
    final safeTitle = script.title
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return '${timestamp}_$safeTitle.json';
  }

  @override
  Future<List<DialogueScript>> getSavedScripts() async {
    try {
      final dir = await _getScriptsDirectory();
      final entities = await dir.list().toList();
      final scripts = <DialogueScript>[];

      for (var entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final content = await entity.readAsString();
            final json = jsonDecode(content);
            scripts.add(DialogueScript.fromJson(json));
          } catch (e) {
            debugPrint('Error reading script file ${entity.path}: $e');
          }
        }
      }

      // Sort by createdAt descending (newest first)
      scripts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return scripts;
    } catch (e) {
      debugPrint('Error listing scripts: $e');
      return [];
    }
  }

  @override
  Future<void> saveScript(DialogueScript script) async {
    try {
      final dir = await _getScriptsDirectory();
      final file = File(path.join(dir.path, _getFileName(script)));
      await file.writeAsString(jsonEncode(script.toJson()));
    } catch (e) {
      debugPrint('Error saving script: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteScript(DialogueScript script) async {
    try {
      final dir = await _getScriptsDirectory();
      final fileName = _getFileName(script);
      final file = File(path.join(dir.path, fileName));

      if (await file.exists()) {
        await file.delete();
      } else {
        debugPrint('File not found for deletion: $fileName');
        // Try searching by matching content if strictly necessary,
        // but for now assume filename consistency.
      }
    } catch (e) {
      debugPrint('Error deleting script: $e');
      rethrow;
    }
  }
}
