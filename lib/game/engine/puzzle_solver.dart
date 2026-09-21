import '../models/cell_state.dart';
import '../models/puzzle.dart';

/// Result of attempting to solve a puzzle purely by logical line deduction.
class SolveResult {
  /// `grid[r][c]` in {0 unknown, 1 filled, 2 empty} — the same codes used by
  /// [CellState.index].
  final List<List<int>> grid;

  /// True when every cell was resolved consistently with the clues.
  final bool solved;

  /// True when the clues led to an impossible line (over-constrained).
  final bool contradiction;

  const SolveResult({
    required this.grid,
    required this.solved,
    required this.contradiction,
  });

  bool get logicallySolvable => solved && !contradiction;
}

/// A constraint solver for Nonograms.
///
/// It repeatedly applies single-line deduction (rows then columns) until a
/// fixpoint. Line deduction is complete: for each cell it decides whether the
/// cell must be filled, must be empty, or is still ambiguous, given the clue and
/// the currently known cells in that line. Because the deduction is exact, a
/// puzzle that this solver drives from blank to a full grid has a *unique*
/// solution and is solvable without guessing — the quality bar we hold real
/// levels to.
class PuzzleSolver {
  const PuzzleSolver._();

  static const int unknown = 0;
  static const int filled = 1;
  static const int empty = 2;

  /// Attempts to solve [puzzle] from a blank grid using only line logic.
  static SolveResult solve(Puzzle puzzle) {
    final rows = puzzle.rows;
    final cols = puzzle.cols;
    final grid = [
      for (var r = 0; r < rows; r++) List<int>.filled(cols, unknown),
    ];

    var changed = true;
    while (changed) {
      changed = false;

      for (var r = 0; r < rows; r++) {
        final line = grid[r];
        final solved = _solveLine(line, puzzle.rowClues[r]);
        if (solved == null) {
          return SolveResult(grid: grid, solved: false, contradiction: true);
        }
        for (var c = 0; c < cols; c++) {
          if (grid[r][c] != solved[c]) {
            grid[r][c] = solved[c];
            changed = true;
          }
        }
      }

      for (var c = 0; c < cols; c++) {
        final line = [for (var r = 0; r < rows; r++) grid[r][c]];
        final solved = _solveLine(line, puzzle.columnClues[c]);
        if (solved == null) {
          return SolveResult(grid: grid, solved: false, contradiction: true);
        }
        for (var r = 0; r < rows; r++) {
          if (grid[r][c] != solved[r]) {
            grid[r][c] = solved[r];
            changed = true;
          }
        }
      }
    }

    final complete =
        grid.every((row) => row.every((cell) => cell != unknown));
    return SolveResult(grid: grid, solved: complete, contradiction: false);
  }

  /// Deduces forced cells in a single line.
  ///
  /// Returns a new line where every cell that is filled/empty in *all* valid
  /// arrangements is resolved, or `null` if no arrangement is consistent with
  /// the current [known] cells (a contradiction).
  static List<int>? _solveLine(List<int> known, List<int> clue) {
    final n = known.length;
    // Normalise the canonical empty clue [0] to "no groups".
    final groups =
        (clue.length == 1 && clue.first == 0) ? const <int>[] : clue;

    final result = List<int>.of(known);
    var anyFeasible = false;
    for (var i = 0; i < n; i++) {
      if (known[i] != unknown) continue;
      final canFill = _feasibleWith(n, groups, known, i, filled);
      final canEmpty = _feasibleWith(n, groups, known, i, empty);
      if (!canFill && !canEmpty) return null;
      if (canFill && !canEmpty) result[i] = filled;
      if (canEmpty && !canFill) result[i] = empty;
      anyFeasible = anyFeasible || canFill || canEmpty;
    }
    // If every cell was already known, verify the line is still feasible.
    if (!anyFeasible && known.contains(unknown) == false) {
      if (!_feasible(n, groups, known)) return null;
    }
    return result;
  }

  static bool _feasibleWith(
    int n,
    List<int> groups,
    List<int> known,
    int cell,
    int forced,
  ) {
    final trial = List<int>.of(known);
    trial[cell] = forced;
    return _feasible(n, groups, trial);
  }

  /// True if the groups can be placed in a line of length [n] consistently with
  /// [known] (0 unknown / 1 filled / 2 empty). Uses a memoised recursion over
  /// (groupIndex, cellIndex).
  static bool _feasible(int n, List<int> groups, List<int> known) {
    final k = groups.length;
    // memo[j][i]: -1 unknown, 0 false, 1 true.
    final memo = [
      for (var j = 0; j <= k; j++) List<int>.filled(n + 2, -1),
    ];

    bool place(int j, int i) {
      if (j == k) {
        // All remaining cells must be able to be empty.
        for (var t = i; t < n; t++) {
          if (known[t] == filled) return false;
        }
        return true;
      }
      if (i >= n) return false;
      final cached = memo[j][i];
      if (cached != -1) return cached == 1;

      var ok = false;

      // Option 1: leave cell i empty and advance.
      if (known[i] != filled) {
        ok = place(j, i + 1);
      }

      // Option 2: place group j starting at cell i.
      if (!ok) {
        final len = groups[j];
        final end = i + len; // exclusive
        if (end <= n) {
          var fits = true;
          for (var t = i; t < end; t++) {
            if (known[t] == empty) {
              fits = false;
              break;
            }
          }
          if (fits) {
            if (end == n) {
              ok = place(j + 1, end);
            } else if (known[end] != filled) {
              // The mandatory gap cell at `end` stays empty.
              ok = place(j + 1, end + 1);
            }
          }
        }
      }

      memo[j][i] = ok ? 1 : 0;
      return ok;
    }

    return place(0, 0);
  }

  /// Converts a solve grid to [CellState]s (unknown cells stay unknown).
  static List<List<CellState>> toCellStates(List<List<int>> grid) => [
        for (final row in grid)
          [for (final v in row) CellState.values[v]],
      ];
}
