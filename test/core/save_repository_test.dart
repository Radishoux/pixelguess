import 'package:flutter_test/flutter_test.dart';
import 'package:pixelguess/core/models/game_save.dart';
import 'package:pixelguess/core/models/level_progress.dart';
import 'package:pixelguess/core/persistence/shared_prefs_save_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load returns an initial save when nothing is persisted yet', () async {
    final repo = SharedPrefsSaveRepository();
    final save = await repo.load();
    expect(save.pixels, 0);
    expect(save.levelProgress, isEmpty);
  });

  test('save/load round-trip preserves energy, pixels, and level intensity', () async {
    final repo = SharedPrefsSaveRepository();
    final original = GameSave.initial().copyWith(
      energy: 7,
      pixels: 340,
      levelProgress: {
        1: const LevelProgress(intensity: 42, solved: false),
        2: const LevelProgress(intensity: 99, solved: true),
      },
      soundEnabled: false,
    );

    await repo.save(original);
    final loaded = await repo.load();

    expect(loaded.energy, 7);
    expect(loaded.pixels, 340);
    expect(loaded.soundEnabled, isFalse);
    expect(loaded.levelProgress[1]!.intensity, 42);
    expect(loaded.levelProgress[1]!.solved, isFalse);
    expect(loaded.levelProgress[2]!.intensity, 99);
    expect(loaded.levelProgress[2]!.solved, isTrue);
    expect(
      loaded.lastEnergyUpdate.toIso8601String(),
      original.lastEnergyUpdate.toIso8601String(),
    );
  });

  test('reset clears persisted data back to initial', () async {
    final repo = SharedPrefsSaveRepository();
    await repo.save(GameSave.initial().copyWith(pixels: 500));
    await repo.reset();
    final loaded = await repo.load();
    expect(loaded.pixels, 0);
  });
}
