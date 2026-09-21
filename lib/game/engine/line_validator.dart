import '../models/cell_state.dart';
import 'run_calculator.dart';

/// Validates a single line (row or column) of the player's grid against its
/// clue. Rows and columns use the identical algorithm — the caller simply
/// extracts the appropriate sequence of cells.
class LineValidator {
  const LineValidator._();

  /// A line satisfies its clue only when its filled runs match the clue exactly
  /// *and* no cell is still [CellState.unknown]. This rejects lines that have
  /// the right total filled count but wrong grouping (e.g. `[3]` is satisfied by
  /// `■■■××` but not by `■■×■×`).
  static bool isSatisfied(List<CellState> line, List<int> clue) {
    if (line.any((c) => c == CellState.unknown)) return false;
    final runs = RunCalculator.fromPlayerLine(line);
    return _runsEqual(runs, clue);
  }

  /// Whether the confirmed filled runs already equal the clue. Used to detect
  /// when the *filled* portion of a line is complete even if some cells remain
  /// unknown (the remaining cells are then provably empty).
  static bool filledRunsMatchClue(List<CellState> line, List<int> clue) {
    final runs = RunCalculator.fromPlayerLine(line);
    return _runsEqual(runs, clue);
  }

  static bool _runsEqual(List<int> runs, List<int> clue) {
    // The canonical empty clue is `[0]`; an empty line has no runs.
    if (clue.length == 1 && clue.first == 0) return runs.isEmpty;
    if (runs.length != clue.length) return false;
    for (var i = 0; i < runs.length; i++) {
      if (runs[i] != clue[i]) return false;
    }
    return true;
  }
}
