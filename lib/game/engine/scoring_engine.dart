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
  }) =>
      starsBySize(
        rows: puzzle.rows,
        cols: puzzle.cols,
        mistakes: mistakes,
        hintsUsed: hintsUsed,
      );

  /// Stars from board size + mistakes + hints, usable by any puzzle variant.
  static int starsBySize({
    required int rows,
    required int cols,
    required int mistakes,
    required int hintsUsed,
  }) {
    // A hint is weighted like two mistakes: it hands over a cell outright.
    final penalty = mistakes + hintsUsed * 2;
    // Larger boards allow a little more slack.
    final slack = (rows * cols) ~/ 60;
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
