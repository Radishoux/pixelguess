import 'package:flutter_test/flutter_test.dart';
import 'package:pixelguess/core/content/level_repository.dart';
import 'package:pixelguess/core/models/level.dart';

void main() {
  test('parses a well-formed manifest', () {
    const json = '''
    {
      "levels": [
        {"id": 1, "image": "assets/images/levels/level_01.png", "answer": "mona lisa", "alternatives": ["monalisa"]},
        {"id": 2, "image": "assets/images/levels/level_02.png", "answer": "donut", "alternatives": []}
      ]
    }
    ''';
    final levels = LevelRepository.parse(json);
    expect(levels.length, 2);
    expect(levels[0].id, 1);
    expect(levels[0].alternatives, ['monalisa']);
    expect(levels[1].alternatives, isEmpty);
  });

  test('throws on invalid JSON', () {
    expect(() => LevelRepository.parse('not json'), throwsA(isA<LevelDataException>()));
  });

  test('throws on missing levels array', () {
    expect(() => LevelRepository.parse('{}'), throwsA(isA<LevelDataException>()));
  });

  test('throws on empty levels array', () {
    expect(() => LevelRepository.parse('{"levels": []}'), throwsA(isA<LevelDataException>()));
  });

  test('throws with a clear message on a malformed level', () {
    const json = '{"levels": [{"id": 1, "image": "", "answer": "x", "alternatives": []}]}';
    expect(
      () => LevelRepository.parse(json),
      throwsA(
        isA<LevelDataException>().having((e) => e.message, 'message', contains('image')),
      ),
    );
  });

  test('throws on duplicate level ids', () {
    const json = '''
    {
      "levels": [
        {"id": 1, "image": "a.png", "answer": "a", "alternatives": []},
        {"id": 1, "image": "b.png", "answer": "b", "alternatives": []}
      ]
    }
    ''';
    expect(
      () => LevelRepository.parse(json),
      throwsA(
        isA<LevelDataException>().having((e) => e.message, 'message', contains('Duplicate')),
      ),
    );
  });

  test('throws when an alternatives entry is not a string', () {
    const json = '{"levels": [{"id": 1, "image": "a.png", "answer": "a", "alternatives": [123]}]}';
    expect(() => LevelRepository.parse(json), throwsA(isA<LevelDataException>()));
  });
}
