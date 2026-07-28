import 'dart:math' as math;

import '../game_config.dart';

/// Pure regen math. Never relies on a running timer — always derives the
/// current energy from a wall-clock [lastUpdate] timestamp, so it works
/// correctly across app kill/restart and backgrounding.
class EnergyEngine {
  EnergyEngine._();

  static ({int energy, DateTime lastUpdate}) applyRegen({
    required int currentEnergy,
    required DateTime lastUpdate,
    required DateTime now,
  }) {
    // Clock changed backwards (or forwards past "now") — clamp instead of
    // ever computing negative elapsed time.
    final effectiveLastUpdate = lastUpdate.isAfter(now) ? now : lastUpdate;

    if (currentEnergy >= GameConfig.energyCap) {
      return (energy: currentEnergy, lastUpdate: now);
    }

    final elapsed = now.difference(effectiveLastUpdate);
    final intervalMs = GameConfig.energyRegenInterval.inMilliseconds;
    final unitsGained = elapsed.inMilliseconds ~/ intervalMs;

    if (unitsGained <= 0) {
      return (energy: currentEnergy, lastUpdate: effectiveLastUpdate);
    }

    final newEnergy = math.min(GameConfig.energyCap, currentEnergy + unitsGained);
    if (newEnergy >= GameConfig.energyCap) {
      // Capped — no point preserving partial-interval progress toward a
      // unit that would just be discarded anyway.
      return (energy: newEnergy, lastUpdate: now);
    }

    // Advance lastUpdate only by the whole intervals actually consumed,
    // so leftover partial-interval progress keeps counting toward the
    // next unit rather than being reset.
    final consumed = Duration(milliseconds: unitsGained * intervalMs);
    return (energy: newEnergy, lastUpdate: effectiveLastUpdate.add(consumed));
  }

  static Duration timeUntilNextUnit({
    required int currentEnergy,
    required DateTime lastUpdate,
    required DateTime now,
  }) {
    if (currentEnergy >= GameConfig.energyCap) return Duration.zero;
    final effectiveLastUpdate = lastUpdate.isAfter(now) ? now : lastUpdate;
    final remaining = GameConfig.energyRegenInterval - now.difference(effectiveLastUpdate);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
