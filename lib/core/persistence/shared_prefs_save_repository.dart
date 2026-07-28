import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_save.dart';
import 'save_repository.dart';

class SharedPrefsSaveRepository implements SaveRepository {
  static const _key = 'pixelguess.save.v1';

  @override
  Future<GameSave> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return GameSave.initial();
    try {
      return GameSave.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return GameSave.initial();
    }
  }

  @override
  Future<void> save(GameSave save) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(save.toJson()));
  }

  @override
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
