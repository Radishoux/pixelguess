import '../game_config.dart';
import '../models/game_save.dart';
import '../models/level_progress.dart';
import '../models/spend_reason.dart';

/// Orchestrates pixel spend/award against a [GameSave]. Callers (UI) are
/// expected to check [canAfford] before invoking a spend — these throw on
/// an invariant violation rather than failing silently.
class Economy {
  Economy._();

  static bool canAfford(GameSave save, int cost) => save.pixels >= cost;

  static GameSave spendPixels(
    GameSave save, {
    required int amount,
    required SpendReason reason,
  }) {
    if (amount > save.pixels) {
      throw StateError(
        'Cannot spend $amount pixels for $reason: only ${save.pixels} available',
      );
    }
    return save.copyWith(pixels: save.pixels - amount);
  }

  static GameSave revealLevel(GameSave save, int levelId) {
    final progress = save.levelProgress[levelId] ?? LevelProgress.initial();
    final cost = GameConfig.pixelCostFor(progress.intensity);
    final spent = spendPixels(save, amount: cost, reason: SpendReason.reveal);

    final nextIntensity = (progress.intensity + GameConfig.intensityStepFor(progress.intensity))
        .clamp(GameConfig.intensityMin, GameConfig.intensityMax);

    return spent.copyWith(
      levelProgress: {
        ...spent.levelProgress,
        levelId: progress.copyWith(intensity: nextIntensity),
      },
    );
  }

  static GameSave solveLevel(GameSave save, int levelId) {
    final progress = save.levelProgress[levelId] ?? LevelProgress.initial();
    if (progress.solved) return save;

    final reward = GameConfig.pixelAwardFor(progress.intensity);
    return save.copyWith(
      pixels: save.pixels + reward,
      levelProgress: {
        ...save.levelProgress,
        levelId: progress.copyWith(solved: true),
      },
    );
  }
}
