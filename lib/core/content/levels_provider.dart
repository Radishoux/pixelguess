import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game_config.dart';
import '../models/level.dart';
import 'level_repository.dart';

/// Loads and schema-validates the level manifest once per app run.
/// Throws (surfacing via AsyncError) with LevelRepository's clear message
/// if levels.json is malformed — this is meant to fail loudly, not
/// silently drop bad levels.
final levelsProvider = FutureProvider<List<Level>>((ref) async {
  final jsonString = await rootBundle.loadString(GameConfig.levelsManifestPath);
  return LevelRepository.parse(jsonString);
});
