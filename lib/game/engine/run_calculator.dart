import '../models/cell_state.dart';

/// Reusable run-length calculation shared by clue generation and validation.
///
/// A "run" is a group of consecutive filled cells. This is the single source of
/// the counting algorithm; rows and columns both funnel through it so the logic
/// is never duplicated.
class RunCalculator {
  const RunCalculator._();

  /// Computes the clue list for a line of the *solution* matrix.
  ///
  /// [line] holds `true` for filled cells and `false` for empty cells.
  /// Returns the length of each consecutive filled group in order.
  /// A line with no filled cells returns `[0]` (the canonical empty clue).
  static List<int> fromSolutionLine(List<bool> line) {
    final runs = <int>[];
    var current = 0;
    for (final filled in line) {
      if (filled) {
        current++;
      } else if (current > 0) {
        runs.add(current);
        current = 0;
      }
    }
    if (current > 0) runs.add(current);
    if (runs.isEmpty) return const [0];
    return runs;
  }

  /// Computes the runs of confirmed [CellState.filled] cells in a player line.
  ///
  /// Only [CellState.filled] contributes; both [CellState.empty] and
  /// [CellState.unknown] act as separators. Returns an empty list when the line
  /// contains no filled cells (distinct from the `[0]` solution clue so callers
  /// can compare against the clue precisely).
  static List<int> fromPlayerLine(List<CellState> line) {
    final runs = <int>[];
    var current = 0;
    for (final cell in line) {
      if (cell == CellState.filled) {
        current++;
      } else if (current > 0) {
        runs.add(current);
        current = 0;
      }
    }
    if (current > 0) runs.add(current);
    return runs;
  }
}
