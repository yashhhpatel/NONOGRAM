import 'run_calculator.dart';

/// Derives row and column clues from a binary solution matrix.
///
/// The solution is always the source of truth; clues are generated from it and
/// never hand-maintained separately.
class ClueGenerator {
  const ClueGenerator._();

  /// [solution] is indexed as `solution[row][col]`, `true` == filled.
  static List<List<int>> generateRowClues(List<List<bool>> solution) {
    return [for (final row in solution) RunCalculator.fromSolutionLine(row)];
  }

  static List<List<int>> generateColumnClues(List<List<bool>> solution) {
    if (solution.isEmpty) return const [];
    final rows = solution.length;
    final cols = solution.first.length;
    final clues = <List<int>>[];
    for (var c = 0; c < cols; c++) {
      final column = <bool>[for (var r = 0; r < rows; r++) solution[r][c]];
      clues.add(RunCalculator.fromSolutionLine(column));
    }
    return clues;
  }
}
