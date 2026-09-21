/// Per-level saved result.
class LevelProgress {
  final int levelId;
  final bool completed;
  final int stars;
  final int bestTimeSeconds; // 0 = none
  final int bestMistakes;
  final int hintsUsed;

  const LevelProgress({
    required this.levelId,
    this.completed = false,
    this.stars = 0,
    this.bestTimeSeconds = 0,
    this.bestMistakes = 0,
    this.hintsUsed = 0,
  });

  LevelProgress mergeBest({
    required int stars,
    required int timeSeconds,
    required int mistakes,
    required int hintsUsed,
  }) {
    final betterTime =
        bestTimeSeconds == 0 || timeSeconds < bestTimeSeconds;
    return LevelProgress(
      levelId: levelId,
      completed: true,
      stars: stars > this.stars ? stars : this.stars,
      bestTimeSeconds: betterTime ? timeSeconds : bestTimeSeconds,
      bestMistakes: completed && bestMistakes <= mistakes
          ? bestMistakes
          : mistakes,
      hintsUsed: hintsUsed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': levelId,
        'c': completed,
        's': stars,
        't': bestTimeSeconds,
        'm': bestMistakes,
        'h': hintsUsed,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> j) => LevelProgress(
        levelId: j['id'] as int,
        completed: j['c'] as bool? ?? false,
        stars: j['s'] as int? ?? 0,
        bestTimeSeconds: j['t'] as int? ?? 0,
        bestMistakes: j['m'] as int? ?? 0,
        hintsUsed: j['h'] as int? ?? 0,
      );
}
