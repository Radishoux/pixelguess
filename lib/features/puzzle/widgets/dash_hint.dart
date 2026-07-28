import 'package:flutter/material.dart';

/// Renders a level's answer as a dash hint that shows word structure and
/// letter count without giving anything away, e.g. "mona lisa" renders as
/// "____ ____". Every non-space character becomes an underscore; spaces
/// are preserved so multi-word answers keep their shape.
class DashHint extends StatelessWidget {
  const DashHint({super.key, required this.answer});

  final String answer;

  static String hintFor(String answer) {
    final buffer = StringBuffer();
    for (final rune in answer.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(char == ' ' ? ' ' : '_');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      hintFor(answer),
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
          ),
      textAlign: TextAlign.center,
    );
  }
}
