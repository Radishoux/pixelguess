import 'package:flutter_test/flutter_test.dart';
import 'package:pixelguess/core/game/answer_matcher.dart';

void main() {
  group('AnswerMatcher.normalize', () {
    test('lowercases input', () {
      expect(AnswerMatcher.normalize('MONA LISA'), 'mona lisa');
    });

    test('strips diacritics', () {
      expect(AnswerMatcher.normalize('café'), 'cafe');
      expect(AnswerMatcher.normalize('La Joconde'), 'la joconde');
    });

    test('removes punctuation but keeps word spacing', () {
      expect(AnswerMatcher.normalize('Mona-Lisa!'), 'monalisa');
      expect(AnswerMatcher.normalize('mona, lisa.'), 'mona lisa');
    });

    test('collapses repeated whitespace and trims', () {
      expect(AnswerMatcher.normalize('  mona   lisa  '), 'mona lisa');
    });
  });

  group('AnswerMatcher.matches', () {
    const answer = 'mona lisa';
    const alternatives = ['monalisa', 'la joconde'];

    test('matches the exact answer', () {
      expect(AnswerMatcher.matches('Mona Lisa', answer, alternatives), isTrue);
    });

    test('matches an alternative', () {
      expect(AnswerMatcher.matches('La Joconde', answer, alternatives), isTrue);
    });

    test('matches ignoring accents and extra punctuation', () {
      expect(AnswerMatcher.matches('  lá Joconde!!', answer, alternatives), isTrue);
    });

    test('rejects an unrelated guess', () {
      expect(AnswerMatcher.matches('microphone', answer, alternatives), isFalse);
    });

    test('rejects an empty guess', () {
      expect(AnswerMatcher.matches('   ', answer, alternatives), isFalse);
    });

    test('rejects a partial match', () {
      expect(AnswerMatcher.matches('mona', answer, alternatives), isFalse);
    });
  });
}
