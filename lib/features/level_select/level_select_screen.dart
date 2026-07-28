import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/levels_provider.dart';
import '../../core/game/game_save_controller.dart';
import '../../core/models/level.dart';
import '../../core/models/level_progress.dart';
import '../puzzle/puzzle_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/hud.dart';
import 'widgets/level_card.dart';

/// Level select — a grid of every level, always fully unlocked.
///
/// There is deliberately no level gating, no unlock conditions, and no
/// linear progression (see SPEC.md): every card is tappable at all
/// times regardless of solved state or any other level's progress.
/// Also hosts the persistent energy/pixels HUD and the entry point to
/// settings.
class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(levelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PixelGuess'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(44),
          child: LevelSelectHud(),
        ),
      ),
      body: levelsAsync.when(
        data: (levels) => _LevelGrid(levels: levels),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load levels: $error'),
          ),
        ),
      ),
    );
  }
}

/// Renders the grid once both levels and the save are available. Kept as
/// its own widget so it can watch [gameSaveProvider] independently of the
/// (rarely-changing) [levelsProvider] result passed down from the parent.
class _LevelGrid extends ConsumerWidget {
  const _LevelGrid({required this.levels});

  final List<Level> levels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameSaveAsync = ref.watch(gameSaveProvider);

    return gameSaveAsync.when(
      data: (gameSave) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: levels.length,
          itemBuilder: (context, index) {
            final level = levels[index];
            final progress =
                gameSave.levelProgress[level.id] ?? LevelProgress.initial();
            return LevelCard(
              level: level,
              progress: progress,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PuzzleScreen(levelId: level.id),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to load save: $error'),
        ),
      ),
    );
  }
}
