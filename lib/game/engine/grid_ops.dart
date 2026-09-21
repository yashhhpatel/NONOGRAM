import '../models/cell_state.dart';

/// Small helpers for pulling rows and columns out of a player grid.
class GridOps {
  const GridOps._();

  static List<CellState> row(List<List<CellState>> grid, int r) => grid[r];

  static List<CellState> column(List<List<CellState>> grid, int c) =>
      [for (final row in grid) row[c]];

  /// Deep copy of a player grid so history snapshots are independent.
  static List<List<CellState>> copy(List<List<CellState>> grid) =>
      [for (final row in grid) List<CellState>.of(row)];

  static List<List<CellState>> blank(int rows, int cols) => [
        for (var r = 0; r < rows; r++)
          List<CellState>.filled(cols, CellState.unknown),
      ];
}
