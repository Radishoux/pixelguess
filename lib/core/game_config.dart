import 'dart:math' as math;

/// Every tunable number in the game lives here. Nothing numeric should
/// be hardcoded anywhere else — retuning the game means editing only
/// this file.
class GameConfig {
  GameConfig._();

  // ---------------------------------------------------------------------
  // Energy
  // ---------------------------------------------------------------------

  /// Maximum energy a player can hold.
  static const int energyCap = 20;

  /// How often one unit of energy regenerates.
  static const Duration energyRegenInterval = Duration(minutes: 5);

  /// Energy spent per guess submission.
  static const int guessEnergyCost = 1;

  // ---------------------------------------------------------------------
  // Intensity (pixelation resolution, 1-99, always sticky/persistent)
  // ---------------------------------------------------------------------

  static const int intensityMin = 1;
  static const int intensityMax = 99;

  /// How much intensity increases per reveal purchase, given the level's
  /// current intensity. A function rather than a constant: 1->2 doubles
  /// linear resolution and is a huge visual jump, while 50->51 is nearly
  /// invisible, so this is the hook for a future curve that grows the
  /// step at higher intensities. Default: flat +1.
  static int intensityStepFor(int currentIntensity) => 1;

  /// Pixel cost to raise a level from [currentIntensity] to
  /// currentIntensity + intensityStepFor(currentIntensity). Grows
  /// geometrically so early reveals are cheap and late-game polish
  /// is expensive.
  static const int revealBaseCost = 15;
  static const double revealCostGrowthPerIntensity = 1.15;

  static int pixelCostFor(int currentIntensity) {
    final clamped = currentIntensity.clamp(intensityMin, intensityMax);
    final scaled = revealBaseCost *
        math.pow(revealCostGrowthPerIntensity, clamped - intensityMin);
    return scaled.round();
  }

  // ---------------------------------------------------------------------
  // Pixel rewards
  // ---------------------------------------------------------------------

  /// Flat pixels awarded for any correct guess.
  static const int solveBaseReward = 100;

  /// Extra pixels for solving at low intensity — rewards restraint.
  /// Scales linearly from [solveMaxBonus] at intensityMin down to 0 at
  /// intensityMax.
  static const int solveMaxBonus = 200;

  static int pixelAwardFor(int intensityAtSolve) {
    final clamped = intensityAtSolve.clamp(intensityMin, intensityMax);
    final remainingFraction =
        (intensityMax - clamped) / (intensityMax - intensityMin);
    final bonus = (solveMaxBonus * remainingFraction).round();
    return solveBaseReward + bonus;
  }

  // ---------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------

  static const String levelsManifestPath = 'assets/data/levels.json';
  static const String levelImageBasePath = 'assets/images/levels/';
}
