import 'package:flutter/material.dart';

import '../../../core/models/level.dart';
import '../../../core/models/level_progress.dart';

/// A single tappable level tile in the level-select grid.
///
/// Deliberately has no notion of "locked" — every level is always
/// tappable regardless of solved state or any other level's progress
/// (see SPEC.md, "No level gating").
class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.level,
    required this.progress,
    required this.onTap,
  });

  final Level level;
  final LevelProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${level.id}',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  if (!progress.solved)
                    Text(
                      'Intensity ${progress.intensity}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (progress.solved)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
