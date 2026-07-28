const _withDiacritics = 'àáâãäåèéêëìíîïòóôõöùúûüçñýÿ';
const _withoutDiacritics = 'aaaaaaeeeeiiiiooooouuuucnyy';

/// Normalises and matches guesses against a level's answer/alternatives.
/// No partial credit — a guess either matches or it doesn't.
class AnswerMatcher {
  AnswerMatcher._();

  static String normalize(String input) {
    final lowered = input.toLowerCase();
    final stripped = _stripDiacritics(lowered);
    final alnumAndSpaces = stripped.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    return alnumAndSpaces.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool matches(String input, String answer, List<String> alternatives) {
    final normalizedInput = normalize(input);
    if (normalizedInput.isEmpty) return false;
    if (normalizedInput == normalize(answer)) return true;
    return alternatives.any((alt) => normalizedInput == normalize(alt));
  }

  static String _stripDiacritics(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final index = _withDiacritics.indexOf(char);
      buffer.write(index == -1 ? char : _withoutDiacritics[index]);
    }
    return buffer.toString();
  }
}
