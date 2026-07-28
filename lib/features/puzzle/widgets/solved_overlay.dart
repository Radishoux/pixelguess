import 'package:flutter/material.dart';

/// Brief award overlay shown after a correct guess, before popping back to
/// level select. Purely presentational — the caller controls when it's
/// mounted, for how long, and is responsible for sizing/positioning it
/// (e.g. via `Positioned.fill` as the direct child of the enclosing
/// `Stack` — this widget intentionally does not position itself so it can
/// be wrapped in transition widgets like `AnimatedOpacity` without
/// breaking `Positioned`'s "must be a direct Stack child" requirement).
class SolvedOverlay extends StatelessWidget {
  const SolvedOverlay({super.key, required this.pixelsAwarded});

  final int pixelsAwarded;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Solved!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+$pixelsAwarded pixels',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
