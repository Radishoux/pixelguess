import '../game_config.dart';
import 'level_progress.dart';

/// The entire persisted game state, serialised as a single JSON blob.
class GameSave {
  final int energy;
  final DateTime lastEnergyUpdate;
  final int pixels;
  final Map<int, LevelProgress> levelProgress;
  final bool soundEnabled;
  final bool hapticsEnabled;

  const GameSave({
    required this.energy,
    required this.lastEnergyUpdate,
    required this.pixels,
    required this.levelProgress,
    required this.soundEnabled,
    required this.hapticsEnabled,
  });

  factory GameSave.initial() => GameSave(
        energy: GameConfig.energyCap,
        lastEnergyUpdate: DateTime.now(),
        pixels: 0,
        levelProgress: const {},
        soundEnabled: true,
        hapticsEnabled: true,
      );

  GameSave copyWith({
    int? energy,
    DateTime? lastEnergyUpdate,
    int? pixels,
    Map<int, LevelProgress>? levelProgress,
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) {
    return GameSave(
      energy: energy ?? this.energy,
      lastEnergyUpdate: lastEnergyUpdate ?? this.lastEnergyUpdate,
      pixels: pixels ?? this.pixels,
      levelProgress: levelProgress ?? this.levelProgress,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  factory GameSave.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['levelProgress'] as Map<String, dynamic>? ?? const {};
    return GameSave(
      energy: json['energy'] as int,
      lastEnergyUpdate: DateTime.parse(json['lastEnergyUpdate'] as String),
      pixels: json['pixels'] as int,
      levelProgress: rawProgress.map(
        (key, value) => MapEntry(
          int.parse(key),
          LevelProgress.fromJson(value as Map<String, dynamic>),
        ),
      ),
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'energy': energy,
        'lastEnergyUpdate': lastEnergyUpdate.toIso8601String(),
        'pixels': pixels,
        'levelProgress': levelProgress.map(
          (key, value) => MapEntry(key.toString(), value.toJson()),
        ),
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
      };
}
