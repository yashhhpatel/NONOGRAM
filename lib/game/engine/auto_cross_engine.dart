import '../models/cell_state.dart';
import '../models/puzzle.dart';
import 'grid_ops.dart';
import 'line_validator.dart';

/// Marks cells as [CellState.empty] only when it is logically guaranteed that
/// they cannot be filled.
///
/// The engine relies on a game invariant: the move layer never places an
/// incorrect filled cell (wrong taps cost a heart and leave the cell unknown).
/// Therefore every [CellState.filled] cell is genuinely part of the solution.
/// Given that, once a line's filled runs already equal its clue, no further
/// fills are permitted in that line, so any remaining unknown cell there is
/// provably empty. The engine never touches a solution-filled cell.
class AutoCrossEngine {
  const AutoCrossEngine._();

  static bool isRowSolved(Puzzle p, List<List<CellState>> grid, int r) =>
      LineValidator.filledRunsMatchClue(GridOps.row(grid, r), p.rowClues[r]);

  static bool isColumnSolved(Puzzle p, List<List<CellState>> grid, int c) =>
      LineValidator.filledRunsMatchClue(
          GridOps.column(grid, c), p.columnClues[c]);

  /// Returns the coordinates of unknown cells that can be safely crossed out.
  static List<({int r, int c})> getSafeEmptyCells(
    Puzzle p,
    List<List<CellState>> grid,
  ) {
    final solvedRows = <int>{
      for (var r = 0; r < p.rows; r++)
        if (isRowSolved(p, grid, r)) r,
    };
    final solvedCols = <int>{
      for (var c = 0; c < p.cols; c++)
        if (isColumnSolved(p, grid, c)) c,
    };

    final safe = <({int r, int c})>[];
    for (var r = 0; r < p.rows; r++) {
      for (var c = 0; c < p.cols; c++) {
        if (grid[r][c] != CellState.unknown) continue;
        if (solvedRows.contains(r) || solvedCols.contains(c)) {
          safe.add((r: r, c: c));
        }
      }
    }
    return safe;
  }

  /// Returns a new grid with all safe cells crossed out. The input is not
  /// mutated.
  static List<List<CellState>> applyAutoCross(
    Puzzle p,
    List<List<CellState>> grid,
  ) {
    final next = GridOps.copy(grid);
    for (final cell in getSafeEmptyCells(p, grid)) {
      next[cell.r][cell.c] = CellState.empty;
    }
    return next;
  }
}
