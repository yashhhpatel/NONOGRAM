import '../models/cell_state.dart';
import '../models/puzzle.dart';
import 'puzzle_solver.dart';

/// A hint reveals the correct state of one cell. It is always truthful: the
/// revealed state comes from the solution, so it can never mislead the player.
class Hint {
  final int row;
  final int col;
  final CellState state; // filled or empty
  const Hint(this.row, this.col, this.state);
}

class HintEngine {
  const HintEngine._();

  /// Chooses a cell to reveal for the current [grid].
  ///
  /// It reveals a cell the logic solver can prove is filled but that the player
  /// has not filled yet. For any valid level the solver resolves the whole
  /// board, so such a cell always exists while the puzzle is unfinished. The
  /// revealed state is taken from the solver's proof, so it is guaranteed
  /// correct.
  static Hint? nextHint(Puzzle puzzle, List<List<CellState>> grid) {
    final solved = PuzzleSolver.solve(puzzle).grid;

    // Prefer a cell the solver proves filled and the player still needs.
    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        final needsFill = puzzle.solutionAt(r, c) &&
            grid[r][c] != CellState.filled;
        if (needsFill && solved[r][c] == PuzzleSolver.filled) {
          return Hint(r, c, CellState.filled);
        }
      }
    }

    // Fallback (solver could not fully resolve): reveal any missing filled cell.
    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        if (puzzle.solutionAt(r, c) && grid[r][c] != CellState.filled) {
          return Hint(r, c, CellState.filled);
        }
      }
    }
    return null;
  }
}
