import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/energy_engine.dart';
import '../../../core/game/energy_ticker_provider.dart';
import '../../../core/game/game_save_controller.dart';
import '../../../core/game_config.dart';

/// Persistent HUD showing live energy (with regen countdown) and the
/// current pixel balance. Meant to live in the level-select AppBar.
class LevelSelectHud extends ConsumerWidget {
  const LevelSelectHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force a rebuild once a second so the countdown stays live. The
    // actual energy value is always re-derived from the persisted
    // timestamp (never from the ticker's count), so missed ticks while
    // backgrounded are harmless.
    ref.watch(energyTickerProvider);

    // On every tick, nudge the save controller to re-derive energy from
    // the persisted timestamp so a completed regen interval is actually
    // applied (and persisted) rather than just displayed optimistically.
    ref.listen<AsyncValue<int>>(energyTickerProvider, (previous, next) {
      ref.read(gameSaveProvider.notifier).refreshEnergy();
    });

    final gameSaveAsync = ref.watch(gameSaveProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: gameSaveAsync.when(
        data: (gameSave) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, size: 18),
                const SizedBox(width: 4),
                Text(_energyText(gameSave.energy, gameSave.lastEnergyUpdate)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.grain, size: 18),
                const SizedBox(width: 4),
                Text('${gameSave.pixels}'),
              ],
            ),
          ],
        ),
        loading: () => const SizedBox.shrink(),
        error: (error, stackTrace) => Text('HUD error: $error'),
      ),
    );
  }

  String _energyText(int energy, DateTime lastEnergyUpdate) {
    final cap = GameConfig.energyCap;
    if (energy >= cap) {
      return 'Energy: $energy/$cap';
    }

    final remaining = EnergyEngine.timeUntilNextUnit(
      currentEnergy: energy,
      lastUpdate: lastEnergyUpdate,
      now: DateTime.now(),
    );
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds.remainder(60);
    final countdown = '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    return 'Energy: $energy/$cap (next in $countdown)';
  }
}
