import '../models/difficulty.dart';
import '../models/puzzle.dart';

/// Converts a completed attempt into stars and coins. Stars depend on mistakes
/// and hints (and lightly on time), never on time alone. Thresholds are
/// configurable per difficulty.
class ScoringEngine {
  const ScoringEngine._();

  static int stars({
    required Puzzle puzzle,
    required int mistakes,
    required int hintsUsed,
    required int elapsedSeconds,
  }) {
    // A hint is weighted like two mistakes: it hands over a cell outright.
    final penalty = mistakes + hintsUsed * 2;

    // Larger boards allow a little more slack.
    final slack = (puzzle.rows * puzzle.cols) ~/ 60; // 0 for small, grows big

    if (penalty <= 0 + slack) return 3;
    if (penalty <= 3 + slack) return 2;
    return 1;
  }

  static int coins({
    required Difficulty difficulty,
    required int stars,
  }) {
    final base = 10 + difficulty.index * 6;
    return base + stars * 5;
  }
}
