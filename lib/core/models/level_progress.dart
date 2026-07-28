import '../game_config.dart';

/// Per-level player state. Intensity is sticky — it only ever moves up.
class LevelProgress {
  final int intensity;
  final bool solved;

  const LevelProgress({required this.intensity, required this.solved});

  factory LevelProgress.initial() =>
      const LevelProgress(intensity: GameConfig.intensityMin, solved: false);

  LevelProgress copyWith({int? intensity, bool? solved}) {
    return LevelProgress(
      intensity: intensity ?? this.intensity,
      solved: solved ?? this.solved,
    );
  }

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      intensity: json['intensity'] as int,
      solved: json['solved'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'intensity': intensity,
        'solved': solved,
      };
}
