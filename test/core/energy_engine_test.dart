import 'package:flutter_test/flutter_test.dart';
import 'package:pixelguess/core/game/energy_engine.dart';
import 'package:pixelguess/core/game_config.dart';

void main() {
  group('EnergyEngine.applyRegen', () {
    test('no time elapsed yields no change', () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      final result = EnergyEngine.applyRegen(currentEnergy: 10, lastUpdate: now, now: now);
      expect(result.energy, 10);
      expect(result.lastUpdate, now);
    });

    test('less than one interval yields no change', () {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      final now = start.add(const Duration(minutes: 4));
      final result = EnergyEngine.applyRegen(currentEnergy: 10, lastUpdate: start, now: now);
      expect(result.energy, 10);
      expect(result.lastUpdate, start);
    });

    test('exactly one interval grants one unit', () {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      final now = start.add(GameConfig.energyRegenInterval);
      final result = EnergyEngine.applyRegen(currentEnergy: 10, lastUpdate: start, now: now);
      expect(result.energy, 11);
      expect(result.lastUpdate, now);
    });

    test('multiple whole intervals grant multiple units and preserve remainder', () {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      final elapsed = GameConfig.energyRegenInterval * 3 + const Duration(minutes: 2);
      final now = start.add(elapsed);
      final result = EnergyEngine.applyRegen(currentEnergy: 5, lastUpdate: start, now: now);
      expect(result.energy, 8);
      expect(result.lastUpdate, start.add(GameConfig.energyRegenInterval * 3));
    });

    test('regen is clamped at the cap and remainder is discarded', () {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      final elapsed = GameConfig.energyRegenInterval * 100;
      final now = start.add(elapsed);
      final result = EnergyEngine.applyRegen(
        currentEnergy: GameConfig.energyCap - 2,
        lastUpdate: start,
        now: now,
      );
      expect(result.energy, GameConfig.energyCap);
      expect(result.lastUpdate, now);
    });

    test('already at cap keeps lastUpdate current', () {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      final now = start.add(const Duration(hours: 1));
      final result = EnergyEngine.applyRegen(
        currentEnergy: GameConfig.energyCap,
        lastUpdate: start,
        now: now,
      );
      expect(result.energy, GameConfig.energyCap);
      expect(result.lastUpdate, now);
    });

    test('future lastUpdate (clock changed) is clamped to now', () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      final future = now.add(const Duration(days: 1));
      final result = EnergyEngine.applyRegen(currentEnergy: 5, lastUpdate: future, now: now);
      expect(result.energy, 5);
      expect(result.lastUpdate, now);
    });
  });

  group('EnergyEngine.timeUntilNextUnit', () {
    test('returns zero at cap', () {
      final now = DateTime(2026, 1, 1);
      final remaining = EnergyEngine.timeUntilNextUnit(
        currentEnergy: GameConfig.energyCap,
        lastUpdate: now,
        now: now,
      );
      expect(remaining, Duration.zero);
    });

    test('returns remaining time within the current interval', () {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      final now = start.add(const Duration(minutes: 2));
      final remaining = EnergyEngine.timeUntilNextUnit(currentEnergy: 5, lastUpdate: start, now: now);
      expect(remaining, GameConfig.energyRegenInterval - const Duration(minutes: 2));
    });
  });
}
