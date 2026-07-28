import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/levels_provider.dart';
import '../../core/game/answer_matcher.dart';
import '../../core/game/game_save_controller.dart';
import '../../core/game_config.dart';
import '../../core/models/game_save.dart';
import '../../core/models/level.dart';
import '../../core/models/level_progress.dart';
import '../../core/pixelation/pixelation_service.dart';
import 'widgets/dash_hint.dart';
import 'widgets/pixelated_image.dart';
import 'widgets/solved_overlay.dart';

/// The core gameplay loop: shows the level's image pixelated to its
/// current intensity, lets the player spend energy to guess and pixels to
/// reveal more detail, and celebrates a correct answer before returning
/// to level select.
class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key, required this.levelId});

  final int levelId;

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen>
    with SingleTickerProviderStateMixin {
  late final PixelationService _pixelation;
  final _textController = TextEditingController();
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  Future<Uint8List>? _bytesFuture;
  bool _solved = false;
  bool _submitting = false;
  int _pixelsAwarded = 0;

  @override
  void initState() {
    super.initState();
    _pixelation = PixelationService();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _pixelation.evictLevel(widget.levelId);
    _pixelation.dispose();
    _textController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Loads the level's full-resolution source bytes once and memoizes the
  /// future for the lifetime of this screen (the level never changes).
  Future<Uint8List> _bytesFor(Level level) {
    return _bytesFuture ??= rootBundle
        .load(level.image)
        .then((data) => data.buffer.asUint8List());
  }

  Future<void> _submit(Level level, LevelProgress progress) async {
    if (_solved || _submitting) return;
    setState(() => _submitting = true);

    final energyOk = await ref.read(gameSaveProvider.notifier).spendEnergyForGuess();
    if (!mounted) return;

    if (!energyOk) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Out of energy — wait for it to regenerate.')),
      );
      return;
    }

    final isCorrect = AnswerMatcher.matches(
      _textController.text,
      level.answer,
      level.alternatives,
    );

    if (isCorrect) {
      final awarded = GameConfig.pixelAwardFor(progress.intensity);
      await ref.read(gameSaveProvider.notifier).solveLevel(widget.levelId);
      if (!mounted) return;
      setState(() {
        _solved = true;
        _submitting = false;
        _pixelsAwarded = awarded;
      });
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      setState(() => _submitting = false);
      _textController.clear();
      _shakeController.forward(from: 0);
    }
  }

  Future<void> _reveal() async {
    await ref.read(gameSaveProvider.notifier).revealLevel(widget.levelId);
  }

  @override
  Widget build(BuildContext context) {
    final levelsAsync = ref.watch(levelsProvider);
    final saveAsync = ref.watch(gameSaveProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Guess the image')),
      body: levelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load levels: $error')),
        data: (levels) {
          final level = levels.firstWhere(
            (l) => l.id == widget.levelId,
            orElse: () => throw StateError('Level ${widget.levelId} not found'),
          );
          return saveAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                Center(child: Text('Failed to load save: $error')),
            data: (gameSave) {
              final progress =
                  gameSave.levelProgress[widget.levelId] ?? LevelProgress.initial();
              return _PuzzleBody(
                level: level,
                progress: progress,
                gameSave: gameSave,
                pixelation: _pixelation,
                bytesFuture: _bytesFor(level),
                textController: _textController,
                shakeAnimation: _shakeAnimation,
                solved: _solved,
                submitting: _submitting,
                pixelsAwarded: _pixelsAwarded,
                onSubmit: () => _submit(level, progress),
                onReveal: _reveal,
              );
            },
          );
        },
      ),
    );
  }
}

class _PuzzleBody extends StatelessWidget {
  const _PuzzleBody({
    required this.level,
    required this.progress,
    required this.gameSave,
    required this.pixelation,
    required this.bytesFuture,
    required this.textController,
    required this.shakeAnimation,
    required this.solved,
    required this.submitting,
    required this.pixelsAwarded,
    required this.onSubmit,
    required this.onReveal,
  });

  final Level level;
  final LevelProgress progress;
  final GameSave gameSave;
  final PixelationService pixelation;
  final Future<Uint8List> bytesFuture;
  final TextEditingController textController;
  final Animation<double> shakeAnimation;
  final bool solved;
  final bool submitting;
  final int pixelsAwarded;
  final VoidCallback onSubmit;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final cost = GameConfig.pixelCostFor(progress.intensity);
    final atMaxIntensity = progress.intensity >= GameConfig.intensityMax;
    final canAffordReveal = gameSave.pixels >= cost && !atMaxIntensity;

    final String revealDisabledReason;
    if (atMaxIntensity) {
      revealDisabledReason = 'Already at maximum detail';
    } else if (!canAffordReveal) {
      revealDisabledReason = 'Need ${cost - gameSave.pixels} more pixels';
    } else {
      revealDisabledReason = '';
    }

    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: FutureBuilder<Uint8List>(
                      future: bytesFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        if (solved) {
                          return Image.asset(level.image, fit: BoxFit.contain);
                        }
                        return PixelatedImage(
                          pixelation: pixelation,
                          levelId: level.id,
                          intensity: progress.intensity,
                          sourceBytes: snapshot.data!,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DashHint(answer: level.answer),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: shakeAnimation,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(shakeAnimation.value, 0),
                    child: child,
                  ),
                  child: TextField(
                    controller: textController,
                    enabled: !solved,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Your guess',
                    ),
                    onSubmitted: (_) {
                      if (!solved && !submitting) onSubmit();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (solved || submitting) ? null : onSubmit,
                        child: const Text('Submit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Tooltip(
                        message: canAffordReveal
                            ? 'Reveal more detail for $cost pixels'
                            : revealDisabledReason,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: (solved || !canAffordReveal) ? null : onReveal,
                              child: Text('Reveal ($cost px)'),
                            ),
                            if (!canAffordReveal && !solved)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  revealDisabledReason,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (solved)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 300),
              child: SolvedOverlay(pixelsAwarded: pixelsAwarded),
            ),
          ),
      ],
    );
  }
}
