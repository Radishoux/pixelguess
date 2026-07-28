import 'package:flutter_test/flutter_test.dart';
import 'package:pixelguess/core/game/economy.dart';
import 'package:pixelguess/core/game_config.dart';
import 'package:pixelguess/core/models/game_save.dart';
import 'package:pixelguess/core/models/level_progress.dart';
import 'package:pixelguess/core/models/spend_reason.dart';

void main() {
  group('GameConfig.pixelCostFor', () {
    test('is the base cost at minimum intensity', () {
      expect(GameConfig.pixelCostFor(GameConfig.intensityMin), GameConfig.revealBaseCost);
    });

    test('strictly increases as intensity rises', () {
      var previous = GameConfig.pixelCostFor(GameConfig.intensityMin);
      for (var i = GameConfig.intensityMin + 1; i <= GameConfig.intensityMax; i++) {
        final cost = GameConfig.pixelCostFor(i);
        expect(cost, greaterThanOrEqualTo(previous));
        previous = cost;
      }
    });

    test('clamps intensity above the max', () {
      expect(GameConfig.pixelCostFor(200), GameConfig.pixelCostFor(GameConfig.intensityMax));
    });
  });

  group('GameConfig.pixelAwardFor', () {
    test('is base + max bonus at minimum intensity', () {
      expect(
        GameConfig.pixelAwardFor(GameConfig.intensityMin),
        GameConfig.solveBaseReward + GameConfig.solveMaxBonus,
      );
    });

    test('is base reward only at maximum intensity', () {
      expect(GameConfig.pixelAwardFor(GameConfig.intensityMax), GameConfig.solveBaseReward);
    });

    test('strictly decreases as intensity rises', () {
      var previous = GameConfig.pixelAwardFor(GameConfig.intensityMin);
      for (var i = GameConfig.intensityMin + 1; i <= GameConfig.intensityMax; i++) {
        final award = GameConfig.pixelAwardFor(i);
        expect(award, lessThanOrEqualTo(previous));
        previous = award;
      }
    });
  });

  group('Economy', () {
    GameSave saveWith({int pixels = 1000}) => GameSave.initial().copyWith(pixels: pixels);

    test('revealLevel raises intensity by the configured step and spends pixels', () {
      final save = saveWith();
      final cost = GameConfig.pixelCostFor(GameConfig.intensityMin);
      final result = Economy.revealLevel(save, 1);
      expect(result.pixels, save.pixels - cost);
      expect(
        result.levelProgress[1]!.intensity,
        GameConfig.intensityMin + GameConfig.intensityStepFor(GameConfig.intensityMin),
      );
    });

    test('revealLevel intensity persists and stacks across repeated calls', () {
      var save = saveWith();
      save = Economy.revealLevel(save, 1);
      save = Economy.revealLevel(save, 1);
      expect(save.levelProgress[1]!.intensity, GameConfig.intensityMin + 2);
    });

    test('revealLevel throws when pixels are insufficient', () {
      final save = saveWith(pixels: 0);
      expect(() => Economy.revealLevel(save, 1), throwsStateError);
    });

    test('revealLevel never raises intensity above the max', () {
      var save = saveWith(pixels: 1 << 30).copyWith(
        levelProgress: {1: const LevelProgress(intensity: GameConfig.intensityMax, solved: false)},
      );
      save = Economy.revealLevel(save, 1);
      expect(save.levelProgress[1]!.intensity, GameConfig.intensityMax);
    });

    test('revealLevel does not affect other levels', () {
      var save = saveWith();
      save = Economy.revealLevel(save, 1);
      expect(save.levelProgress.containsKey(2), isFalse);
    });

    test('solveLevel awards pixels and marks solved', () {
      var save = saveWith();
      save = Economy.revealLevel(save, 2);
      final pixelsBeforeSolve = save.pixels;
      final intensityAtSolve = save.levelProgress[2]!.intensity;
      save = Economy.solveLevel(save, 2);
      expect(save.levelProgress[2]!.solved, isTrue);
      expect(save.pixels, pixelsBeforeSolve + GameConfig.pixelAwardFor(intensityAtSolve));
    });

    test('solveLevel is a no-op if already solved', () {
      var save = saveWith();
      save = Economy.solveLevel(save, 1);
      final pixelsAfterFirstSolve = save.pixels;
      save = Economy.solveLevel(save, 1);
      expect(save.pixels, pixelsAfterFirstSolve);
    });

    test('spendPixels throws if amount exceeds balance', () {
      final save = saveWith(pixels: 5);
      expect(
        () => Economy.spendPixels(save, amount: 10, reason: SpendReason.hint),
        throwsStateError,
      );
    });

    test('canAfford reflects the current balance', () {
      final save = saveWith(pixels: 50);
      expect(Economy.canAfford(save, 50), isTrue);
      expect(Economy.canAfford(save, 51), isFalse);
    });
  });
}
