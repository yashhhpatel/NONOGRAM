import 'dart:math';

import '../data/level_catalog.dart';
import '../models/difficulty.dart';
import '../models/puzzle.dart';
import 'puzzle_solver.dart';
import 'run_calculator.dart';

/// Deterministically generates original puzzle solutions with a difficulty that
/// rises smoothly across the campaign.
///
/// Difficulty is driven by a per-level [hardness] in `[0,1]`:
///  - only the earliest levels are vertically symmetric (symmetry makes a
///    puzzle much easier — solve one half, mirror the rest);
///  - fragmentation (the number of clue groups per line) scales up with
///    hardness, so higher levels have shorter, more numerous runs that demand
///    real deduction;
///  - candidates are generated and the one whose average clue-group count is
///    closest to a rising target is chosen, which enforces a monotonic ramp
///    within each grid-size band and across the whole game.
///
/// Gameplay validates taps against the stored solution, so a puzzle is always
/// playable; the generator additionally prefers puzzles the logic solver can
/// crack without guessing so difficulty comes from reading, not luck.
class PuzzleGenerator {
  const PuzzleGenerator._();

  static const int _candidates = 22;
  static const int _maxSolverChecks = 4;

  /// Campaign hardness for a level: a smooth 0..1 ramp over all levels, curved
  /// so difficulty builds up noticeably through the early and middle game
  /// rather than staying easy for hundreds of levels.
  static double hardnessForLevel(int levelId) {
    final t = (levelId - 1) / (LevelCatalog.totalLevels - 1);
    return pow(t.clamp(0.0, 1.0), 0.65).toDouble();
  }

  static Puzzle generate({
    required int id,
    required int size,
    required String category,
    required String title,
    required double hardness,
  }) {
    final target = _targetAvgGroups(size, hardness);

    // A diverse candidate pool spanning blobby (few groups, easy) to fragmented
    // (many groups, hard); selection then picks the one closest to the rising
    // target, which is what actually sets the difficulty.
    final built = <_Candidate>[];
    for (var attempt = 0; attempt < _candidates; attempt++) {
      final passes = attempt % 4; // 0..3 smoothing passes
      final density = 0.42 + (attempt % 3) * 0.06; // 0.42 / 0.48 / 0.54
      final seed = _seedFor(id, attempt);
      final sol = _generateSolution(size, seed, density, passes);
      if (_isEmpty(sol) || _isFull(sol)) continue;
      final avg = _avgGroups(sol);
      // Drop degenerate near-solid blobs (a single giant group reads as trivial
      // and barely looks like a picture).
      if (avg < 1.0) continue;
      built.add(_Candidate(sol, avg));
    }

    if (built.isEmpty) {
      return _finish(id, _fallback(size), category, title, hardness);
    }

    // Closest to the difficulty target first.
    built.sort((a, b) =>
        (a.avgGroups - target).abs().compareTo((b.avgGroups - target).abs()));

    // Prefer a logic-solvable puzzle among the best matches.
    List<List<bool>> chosen = built.first.solution;
    final checks = built.length < _maxSolverChecks ? built.length : _maxSolverChecks;
    for (var i = 0; i < checks; i++) {
      final candidate = _finish(id, built[i].solution, category, title, hardness);
      if (PuzzleSolver.solve(candidate).logicallySolvable) {
        chosen = built[i].solution;
        break;
      }
    }
    return _finish(id, chosen, category, title, hardness);
  }

  static Puzzle _finish(
    int id,
    List<List<bool>> solution,
    String category,
    String title,
    double hardness,
  ) {
    return Puzzle.fromSolution(
      id: id,
      solution: solution,
      difficulty: labelForHardness(hardness),
      category: category,
      title: title,
    );
  }

  /// Maps hardness to a difficulty label so the shown difficulty always tracks
  /// the level's real (targeted) hardness and increases monotonically.
  static Difficulty labelForHardness(double h) {
    if (h < 0.14) return Difficulty.veryEasy;
    if (h < 0.34) return Difficulty.easy;
    if (h < 0.60) return Difficulty.medium;
    if (h < 0.82) return Difficulty.hard;
    return Difficulty.expert;
  }

  /// Target average clue-group count per line — grows with both grid size and
  /// hardness, producing a rising ramp within and across bands. Clamped so it
  /// stays picture-like and solvable rather than pure noise.
  static double _targetAvgGroups(int size, double hardness) {
    final t = 1.2 + hardness * (size * 0.42);
    return t.clamp(1.05, size * 0.45);
  }

  static int _seedFor(int id, int attempt) => (id * 1000003) ^ (attempt + 17);

  static List<List<bool>> _generateSolution(
    int size,
    int seed,
    double density,
    int smoothPasses,
  ) {
    final rng = Random(seed);
    var grid = [
      for (var r = 0; r < size; r++)
        [for (var c = 0; c < size; c++) rng.nextDouble() < density],
    ];

    // Cellular smoothing grows blobs and removes speckles, cutting the number
    // of clue groups. Fewer passes => more fragmented (harder) candidates.
    for (var p = 0; p < smoothPasses; p++) {
      grid = _smooth(grid);
    }
    return grid;
  }

  static List<List<bool>> _smooth(List<List<bool>> g) {
    final size = g.length;
    return [
      for (var r = 0; r < size; r++)
        [
          for (var c = 0; c < size; c++) _majorityFilled(g, r, c, size),
        ],
    ];
  }

  static bool _majorityFilled(List<List<bool>> g, int r, int c, int size) {
    var count = 0;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final nr = r + dr, nc = c + dc;
        if (nr >= 0 && nr < size && nc >= 0 && nc < size && g[nr][nc]) count++;
      }
    }
    return count >= 5;
  }

  static double _avgGroups(List<List<bool>> solution) {
    final size = solution.length;
    final cols = solution.first.length;
    var total = 0;
    for (final row in solution) {
      final runs = RunCalculator.fromSolutionLine(row);
      if (!(runs.length == 1 && runs.first == 0)) total += runs.length;
    }
    for (var c = 0; c < cols; c++) {
      final col = [for (var r = 0; r < size; r++) solution[r][c]];
      final runs = RunCalculator.fromSolutionLine(col);
      if (!(runs.length == 1 && runs.first == 0)) total += runs.length;
    }
    return total / (size + cols);
  }

  static List<List<bool>> _fallback(int size) {
    final grid = [
      for (var r = 0; r < size; r++) List<bool>.filled(size, false),
    ];
    final mid = (size - 1) / 2.0;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (((r - mid).abs() + (c - mid).abs()) <= size / 2) grid[r][c] = true;
      }
    }
    return grid;
  }

  static bool _isEmpty(List<List<bool>> g) =>
      g.every((row) => row.every((c) => !c));

  static bool _isFull(List<List<bool>> g) =>
      g.every((row) => row.every((c) => c));
}

class _Candidate {
  final List<List<bool>> solution;
  final double avgGroups;
  const _Candidate(this.solution, this.avgGroups);
}
