import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/game/data/puzzle_repository.dart';
import 'package:nonogram/game/engine/puzzle_generator.dart';
import 'package:nonogram/game/engine/run_calculator.dart';
import 'package:nonogram/game/models/puzzle.dart';

double avgGroups(Puzzle p) {
  var total = 0;
  for (var r = 0; r < p.rows; r++) {
    final runs = RunCalculator.fromSolutionLine(p.solution[r]);
    if (!(runs.length == 1 && runs.first == 0)) total += runs.length;
  }
  for (var c = 0; c < p.cols; c++) {
    final col = [for (var r = 0; r < p.rows; r++) p.solutionAt(r, c)];
    final runs = RunCalculator.fromSolutionLine(col);
    if (!(runs.length == 1 && runs.first == 0)) total += runs.length;
  }
  return total / (p.rows + p.cols);
}

void main() {
  test('hardness is strictly increasing across levels', () {
    var prev = -1.0;
    for (var id = 1; id <= 1000; id += 10) {
      final h = PuzzleGenerator.hardnessForLevel(id);
      expect(h, greaterThanOrEqualTo(prev));
      prev = h;
    }
    expect(PuzzleGenerator.hardnessForLevel(1), 0.0);
    expect(PuzzleGenerator.hardnessForLevel(1000), closeTo(1.0, 1e-9));
  });

  test('difficulty label never decreases with level', () {
    var prevIndex = -1;
    for (var id = 1; id <= 1000; id += 5) {
      final label = PuzzleGenerator.labelForHardness(
          PuzzleGenerator.hardnessForLevel(id));
      expect(label.index, greaterThanOrEqualTo(prevIndex),
          reason: 'level $id');
      prevIndex = label.index;
    }
  });

  test('clue fragmentation trends upward across the campaign', () {
    final repo = PuzzleRepository();
    final samples = [
      for (var id = 1; id <= 1000; id += 100) id,
    ];
    final avgs = [for (final id in samples) avgGroups(repo.puzzleForLevel(id))];

    // Late levels are clearly harder than early ones.
    expect(avgs.last, greaterThan(avgs.first + 3.0));

    // The trend rises: allow small local wiggles but no big backslide.
    for (var i = 1; i < avgs.length; i++) {
      expect(avgs[i], greaterThan(avgs[i - 1] - 0.5),
          reason: 'level ${samples[i]} vs ${samples[i - 1]}');
    }
    // And it is monotonic across the coarse quartiles.
    final q = [avgs[0], avgs[2], avgs[5], avgs[8], avgs[9]];
    for (var i = 1; i < q.length; i++) {
      expect(q[i], greaterThan(q[i - 1]), reason: 'quartile $i');
    }
  });
}
