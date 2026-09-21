import '../engine/clue_generator.dart';
import 'difficulty.dart';

/// An immutable, fully-specified Nonogram puzzle.
///
/// The [solution] is the single source of truth. Row and column clues are
/// derived from it so the two can never disagree.
class Puzzle {
  final int id;
  final int rows;
  final int cols;

  /// `solution[row][col]` — `true` means the cell belongs to the picture.
  final List<List<bool>> solution;

  final List<List<int>> rowClues;
  final List<List<int>> columnClues;
  final Difficulty difficulty;
  final String category;
  final String title;

  const Puzzle._({
    required this.id,
    required this.rows,
    required this.cols,
    required this.solution,
    required this.rowClues,
    required this.columnClues,
    required this.difficulty,
    required this.category,
    required this.title,
  });

  /// Builds a puzzle from a solution matrix, generating clues from it.
  factory Puzzle.fromSolution({
    required int id,
    required List<List<bool>> solution,
    required Difficulty difficulty,
    required String category,
    required String title,
  }) {
    assert(solution.isNotEmpty, 'Solution must have at least one row');
    final rows = solution.length;
    final cols = solution.first.length;
    assert(
      solution.every((r) => r.length == cols),
      'All solution rows must share the same length',
    );
    return Puzzle._(
      id: id,
      rows: rows,
      cols: cols,
      solution: solution,
      rowClues: ClueGenerator.generateRowClues(solution),
      columnClues: ClueGenerator.generateColumnClues(solution),
      difficulty: difficulty,
      category: category,
      title: title,
    );
  }

  /// Convenience constructor from a matrix of 0/1 ints.
  factory Puzzle.fromInts({
    required int id,
    required List<List<int>> matrix,
    required Difficulty difficulty,
    required String category,
    required String title,
  }) {
    final solution = [
      for (final row in matrix) [for (final v in row) v != 0],
    ];
    return Puzzle.fromSolution(
      id: id,
      solution: solution,
      difficulty: difficulty,
      category: category,
      title: title,
    );
  }

  /// Longest side of the board.
  int get size => rows > cols ? rows : cols;

  int get filledCount =>
      solution.fold(0, (sum, row) => sum + row.where((c) => c).length);

  double get density => filledCount / (rows * cols);

  bool solutionAt(int r, int c) => solution[r][c];
}
