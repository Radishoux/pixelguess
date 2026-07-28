import '../models/game_save.dart';

/// Persistence boundary for [GameSave]. Kept as an interface so the
/// backing store (currently shared_preferences) can be swapped for
/// Hive/sqflite later without touching game logic.
abstract class SaveRepository {
  Future<GameSave> load();
  Future<void> save(GameSave save);
  Future<void> reset();
}
