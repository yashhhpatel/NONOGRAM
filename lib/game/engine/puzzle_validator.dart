import '../models/puzzle.dart';
import 'clue_generator.dart';
import 'puzzle_solver.dart';

class ValidationResult {
  final bool valid;
  final List<String> problems;
  const ValidationResult(this.valid, this.problems);

  static const ValidationResult ok = ValidationResult(true, []);
}

/// Verifies a puzzle is well-formed, non-trivial, and solvable by logic with a
/// unique solution. Broken puzzles must never reach players.
class PuzzleValidator {
  const PuzzleValidator._();

  static ValidationResult validate(Puzzle p) {
    final problems = <String>[];

    // Dimensions.
    if (p.rows <= 0 || p.cols <= 0) {
      problems.add('Non-positive dimensions');
    }
    if (p.solution.length != p.rows ||
        p.solution.any((r) => r.length != p.cols)) {
      problems.add('Solution shape mismatch');
    }

    // Non-trivial: must contain at least one filled cell.
    if (p.filledCount == 0) {
      problems.add('Empty picture');
    }

    // Clues must match those derived from the solution.
    final expectedRows = ClueGenerator.generateRowClues(p.solution);
    final expectedCols = ClueGenerator.generateColumnClues(p.solution);
    if (!_cluesEqual(expectedRows, p.rowClues)) {
      problems.add('Row clues inconsistent with solution');
    }
    if (!_cluesEqual(expectedCols, p.columnClues)) {
      problems.add('Column clues inconsistent with solution');
    }

    if (problems.isNotEmpty) return ValidationResult(false, problems);

    // Solvable by pure logic (implies a unique solution).
    final result = PuzzleSolver.solve(p);
    if (result.contradiction) {
      problems.add('Clues are contradictory');
    } else if (!result.solved) {
      problems.add('Requires guessing (not uniquely logic-solvable)');
    } else {
      // The logic solution must match the intended picture.
      for (var r = 0; r < p.rows; r++) {
        for (var c = 0; c < p.cols; c++) {
          final solvedFilled = result.grid[r][c] == PuzzleSolver.filled;
          if (solvedFilled != p.solutionAt(r, c)) {
            problems.add('Logic solution differs from intended picture');
            break;
          }
        }
      }
    }

    return ValidationResult(problems.isEmpty, problems);
  }

  static bool _cluesEqual(List<List<int>> a, List<List<int>> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].length != b[i].length) return false;
      for (var j = 0; j < a[i].length; j++) {
        if (a[i][j] != b[i][j]) return false;
      }
    }
    return true;
  }
}
