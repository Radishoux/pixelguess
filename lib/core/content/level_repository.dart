import 'dart:convert';

import '../models/level.dart';

/// Parses and schema-validates `levels.json`. Pure Dart — asset loading
/// happens at the call site so this stays testable without a widget tree.
class LevelRepository {
  LevelRepository._();

  static List<Level> parse(String jsonSource) {
    final Map<String, dynamic> root;
    try {
      root = jsonDecode(jsonSource) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw LevelDataException('levels.json is not valid JSON: ${e.message}');
    }

    final rawLevels = root['levels'];
    if (rawLevels is! List || rawLevels.isEmpty) {
      throw const LevelDataException('levels.json must contain a non-empty "levels" array');
    }

    final levels = <Level>[];
    final seenIds = <int>{};
    for (var i = 0; i < rawLevels.length; i++) {
      final entry = rawLevels[i];
      if (entry is! Map<String, dynamic>) {
        throw LevelDataException('levels[$i] must be a JSON object');
      }

      final Level level;
      try {
        level = Level.fromJson(entry);
      } on LevelDataException catch (e) {
        throw LevelDataException('levels[$i]: ${e.message}');
      }

      if (!seenIds.add(level.id)) {
        throw LevelDataException('Duplicate level id: ${level.id}');
      }
      levels.add(level);
    }

    return levels;
  }
}
