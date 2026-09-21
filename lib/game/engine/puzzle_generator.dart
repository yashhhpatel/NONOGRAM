import 'dart:math';

import '../models/difficulty.dart';
import '../models/puzzle.dart';
import 'difficulty_engine.dart';
import 'puzzle_solver.dart';

/// Deterministically generates original puzzle solutions.
///
/// Gameplay validates every tap against the stored solution, so a puzzle is
/// always playable and fair as long as its solution is non-empty and its clues
/// are consistent (guaranteed by [Puzzle.fromSolution]). On top of that
/// baseline the generator *prefers* puzzles the logic solver can crack without
/// guessing, retrying a bounded number of deterministic seeds. If none passes
/// within budget it keeps the best-formed candidate, so generation never fails
/// or hangs.
class PuzzleGenerator {
  const PuzzleGenerator._();

  static const int _maxAttempts = 14;

  static Puzzle generate({
    required int id,
    required int size,
    required String category,
    required String title,
  }) {
    Puzzle? best;
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final seed = _seedFor(id, attempt);
      final solution = _structuredSolution(size, seed);
      if (_isEmpty(solution) || _isFull(solution)) continue;

      final candidate = Puzzle.fromSolution(
        id: id,
        solution: solution,
        difficulty: Difficulty.easy, // recomputed below
        category: category,
        title: title,
      );
      best ??= candidate;

      if (PuzzleSolver.solve(candidate).logicallySolvable) {
        best = candidate;
        break;
      }
    }

    final chosen = best ?? _fallback(id, size, category, title);
    return Puzzle.fromSolution(
      id: id,
      solution: chosen.solution,
      difficulty: DifficultyEngine.analyze(chosen),
      category: category,
      title: title,
    );
  }

  /// Stable per-level, per-attempt seed so a level always yields the same
  /// puzzle across launches and devices.
  static int _seedFor(int id, int attempt) => (id * 1000003) ^ (attempt + 17);

  /// Builds a vertically-symmetric filled pattern, which reads as an
  /// intentional shape rather than random noise.
  static List<List<bool>> _structuredSolution(int size, int seed) {
    final rng = Random(seed);
    final grid = [
      for (var r = 0; r < size; r++) List<bool>.filled(size, false),
    ];
    final half = (size / 2).ceil();
    final density = 0.42 + rng.nextDouble() * 0.20;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < half; c++) {
        final on = rng.nextDouble() < density;
        grid[r][c] = on;
        grid[r][size - 1 - c] = on;
      }
    }
    return grid;
  }

  static Puzzle _fallback(int id, int size, String category, String title) {
    // A guaranteed non-empty, well-formed pattern (a framed diamond).
    final grid = [
      for (var r = 0; r < size; r++) List<bool>.filled(size, false),
    ];
    final mid = (size - 1) / 2.0;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (((r - mid).abs() + (c - mid).abs()) <= size / 2) {
          grid[r][c] = true;
        }
      }
    }
    return Puzzle.fromSolution(
      id: id,
      solution: grid,
      difficulty: Difficulty.easy,
      category: category,
      title: title,
    );
  }

  static bool _isEmpty(List<List<bool>> g) =>
      g.every((row) => row.every((c) => !c));

  static bool _isFull(List<List<bool>> g) =>
      g.every((row) => row.every((c) => c));
}
