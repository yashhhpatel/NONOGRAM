import '../models/cell_state.dart';
import '../models/puzzle.dart';

/// Determines whether a puzzle is fully solved.
///
/// Completion is NOT "every cell filled" — a Nonogram also contains empty
/// cells. The definitive test compares the player grid against the solution:
/// every solution-filled cell must be [CellState.filled]. Cells that are empty
/// in the solution may be either [CellState.empty] or still [CellState.unknown]
/// (the player is never required to cross out every blank).
class CompletionEngine {
  const CompletionEngine._();

  static bool isComplete(Puzzle puzzle, List<List<CellState>> grid) {
    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        if (puzzle.solutionAt(r, c)) {
          if (grid[r][c] != CellState.filled) return false;
        }
      }
    }
    return true;
  }
}
