/// Thrown when level content fails schema validation. Callers should let
/// this surface loudly rather than silently skipping bad content.
class LevelDataException implements Exception {
  final String message;

  const LevelDataException(this.message);

  @override
  String toString() => 'LevelDataException: $message';
}

class Level {
  final int id;
  final String image;
  final String answer;
  final List<String> alternatives;

  const Level({
    required this.id,
    required this.image,
    required this.answer,
    required this.alternatives,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! int) {
      throw LevelDataException('"id" must be an integer, got: ${json['id']}');
    }

    final image = json['image'];
    if (image is! String || image.trim().isEmpty) {
      throw LevelDataException('id $rawId: "image" must be a non-empty string');
    }

    final answer = json['answer'];
    if (answer is! String || answer.trim().isEmpty) {
      throw LevelDataException('id $rawId: "answer" must be a non-empty string');
    }

    final rawAlternatives = json['alternatives'] ?? const <dynamic>[];
    if (rawAlternatives is! List) {
      throw LevelDataException('id $rawId: "alternatives" must be a list of strings');
    }
    final alternatives = <String>[];
    for (final entry in rawAlternatives) {
      if (entry is! String || entry.trim().isEmpty) {
        throw LevelDataException('id $rawId: every "alternatives" entry must be a non-empty string');
      }
      alternatives.add(entry);
    }

    return Level(id: rawId, image: image, answer: answer, alternatives: alternatives);
  }
}
