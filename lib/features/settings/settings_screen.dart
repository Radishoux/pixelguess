import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/game/game_save_controller.dart';
import '../../core/models/game_save.dart';

/// Options / settings screen: sound & haptics toggles, destructive reset,
/// version info, and credits. Always pushed on top of level select.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset all progress?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await ref.read(gameSaveProvider.notifier).resetProgress();

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameSaveAsync = ref.watch(gameSaveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: gameSaveAsync.when(
        data: (gameSave) => _SettingsList(
          gameSave: gameSave,
          onSoundChanged: (value) =>
              ref.read(gameSaveProvider.notifier).setSoundEnabled(value),
          onHapticsChanged: (value) =>
              ref.read(gameSaveProvider.notifier).setHapticsEnabled(value),
          onResetPressed: () => _confirmReset(context, ref),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Failed to load settings: $error'),
        ),
      ),
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({
    required this.gameSave,
    required this.onSoundChanged,
    required this.onHapticsChanged,
    required this.onResetPressed,
  });

  final GameSave gameSave;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onHapticsChanged;
  final VoidCallback onResetPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        const _SectionHeader('Preferences'),
        SwitchListTile(
          title: const Text('Sound'),
          subtitle: const Text('Play sound effects'),
          value: gameSave.soundEnabled,
          onChanged: onSoundChanged,
        ),
        SwitchListTile(
          title: const Text('Haptics'),
          subtitle: const Text('Vibrate on key actions'),
          value: gameSave.hapticsEnabled,
          onChanged: onHapticsChanged,
        ),
        const Divider(height: 32),
        const _SectionHeader('Progress'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: onResetPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Reset progress'),
          ),
        ),
        const Divider(height: 32),
        const _SectionHeader('About'),
        const ListTile(
          title: Text('Version'),
          subtitle: Text('Version 1.0.0'),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: _CreditsSection(),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _CreditsSection extends StatelessWidget {
  const _CreditsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PixelGuess', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Built with Flutter', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          'Artwork: placeholder',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
