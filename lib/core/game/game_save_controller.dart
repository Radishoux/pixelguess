import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game_config.dart';
import '../models/game_save.dart';
import '../persistence/save_repository.dart';
import '../persistence/shared_prefs_save_repository.dart';
import 'economy.dart';
import 'energy_engine.dart';

final saveRepositoryProvider = Provider<SaveRepository>((ref) {
  return SharedPrefsSaveRepository();
});

/// Single source of truth for [GameSave]. All game-state mutation goes
/// through this controller so it's always persisted and every screen
/// observing [gameSaveProvider] stays in sync.
class GameSaveController extends AsyncNotifier<GameSave> {
  @override
  Future<GameSave> build() async {
    final repo = ref.read(saveRepositoryProvider);
    final loaded = await repo.load();
    return _withRegenApplied(loaded);
  }

  GameSave _withRegenApplied(GameSave save) {
    final result = EnergyEngine.applyRegen(
      currentEnergy: save.energy,
      lastUpdate: save.lastEnergyUpdate,
      now: DateTime.now(),
    );
    return save.copyWith(energy: result.energy, lastEnergyUpdate: result.lastUpdate);
  }

  Future<void> _commit(GameSave save) async {
    state = AsyncData(save);
    await ref.read(saveRepositoryProvider).save(save);
  }

  /// Re-derives energy from the persisted timestamp against the current
  /// wall clock. Call this whenever the UI needs an up-to-date value
  /// (app resume, a countdown tick reaching zero, before a guess).
  Future<void> refreshEnergy() async {
    final current = state.value;
    if (current == null) return;
    final updated = _withRegenApplied(current);
    if (updated.energy != current.energy || updated.lastEnergyUpdate != current.lastEnergyUpdate) {
      await _commit(updated);
    }
  }

  /// Attempts to spend the energy cost of a guess. Returns false without
  /// mutating state if there isn't enough energy.
  Future<bool> spendEnergyForGuess() async {
    await refreshEnergy();
    final current = state.value;
    if (current == null || current.energy < GameConfig.guessEnergyCost) {
      return false;
    }
    await _commit(current.copyWith(energy: current.energy - GameConfig.guessEnergyCost));
    return true;
  }

  Future<void> revealLevel(int levelId) async {
    final current = state.value;
    if (current == null) return;
    await _commit(Economy.revealLevel(current, levelId));
  }

  Future<void> solveLevel(int levelId) async {
    final current = state.value;
    if (current == null) return;
    await _commit(Economy.solveLevel(current, levelId));
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return;
    await _commit(current.copyWith(soundEnabled: enabled));
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return;
    await _commit(current.copyWith(hapticsEnabled: enabled));
  }

  Future<void> resetProgress() async {
    await ref.read(saveRepositoryProvider).reset();
    await _commit(GameSave.initial());
  }
}

final gameSaveProvider = AsyncNotifierProvider<GameSaveController, GameSave>(
  GameSaveController.new,
);
