import '../models/difficulty.dart';
import '../models/puzzle.dart';

/// Estimates difficulty from clue structure and board shape rather than grid
/// size alone. A large board with obvious clues can be easier than a small
/// board packed with short, ambiguous groups.
class DifficultyEngine {
  const DifficultyEngine._();

  static Difficulty analyze(Puzzle p) {
    final size = p.rows > p.cols ? p.rows : p.cols;

    // Base score from board size.
    double score = switch (size) {
      <= 5 => 0,
      6 => 1,
      7 => 2,
      8 => 3,
      <= 10 => 4,
      <= 12 => 6,
      <= 15 => 8,
      <= 18 => 10,
      _ => 12,
    }
        .toDouble();

    // Clue complexity: more groups per line and more short groups raise it.
    var totalGroups = 0;
    var shortGroups = 0;
    var maxGroupsInLine = 0;
    for (final clue in [...p.rowClues, ...p.columnClues]) {
      if (clue.length == 1 && clue.first == 0) continue;
      totalGroups += clue.length;
      if (clue.length > maxGroupsInLine) maxGroupsInLine = clue.length;
      shortGroups += clue.where((g) => g == 1).length;
    }
    final lines = p.rows + p.cols;
    final avgGroupsPerLine = totalGroups / lines;

    score += avgGroupsPerLine * 1.2;
    score += (shortGroups / lines) * 1.5;
    score += (maxGroupsInLine - 1) * 0.4;

    // Extreme densities (very sparse or very full) are easier to read.
    final d = p.density;
    final densityDistance = (d - 0.5).abs(); // 0 hardest, 0.5 easiest
    score -= densityDistance * 2.5;

    if (score < 2) return Difficulty.veryEasy;
    if (score < 4.5) return Difficulty.easy;
    if (score < 8) return Difficulty.medium;
    if (score < 12) return Difficulty.hard;
    return Difficulty.expert;
  }
}
