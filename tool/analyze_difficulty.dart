// Standalone difficulty audit. Run: dart run tool/analyze_difficulty.dart
import 'package:nonogram/game/data/puzzle_repository.dart';
import 'package:nonogram/game/models/puzzle.dart';

double _avgGroups(Puzzle p) {
  var total = 0;
  for (final clue in [...p.rowClues, ...p.columnClues]) {
    if (clue.length == 1 && clue.first == 0) continue;
    total += clue.length;
  }
  return total / (p.rows + p.cols);
}

int _maxGroups(Puzzle p) {
  var m = 0;
  for (final clue in [...p.rowClues, ...p.columnClues]) {
    if (clue.length == 1 && clue.first == 0) continue;
    if (clue.length > m) m = clue.length;
  }
  return m;
}

bool _vSymmetric(Puzzle p) {
  for (var r = 0; r < p.rows; r++) {
    for (var c = 0; c < p.cols; c++) {
      if (p.solutionAt(r, c) != p.solutionAt(r, p.cols - 1 - c)) return false;
    }
  }
  return true;
}

void main() {
  final repo = PuzzleRepository();
  final levels = [
    1, 8, 15, 25, 35, 45, 55, 75, 100, 150, 200, 250, 300,
    400, 500, 600, 700, 800, 900, 1000
  ];
  print('lvl  size  diff        dens  avgGrp maxGrp sym');
  for (final id in levels) {
    final p = repo.puzzleForLevel(id);
    final line = [
      id.toString().padLeft(4),
      '${p.rows}x${p.cols}'.padLeft(5),
      p.difficulty.label.padRight(10),
      p.density.toStringAsFixed(2),
      _avgGroups(p).toStringAsFixed(2).padLeft(6),
      _maxGroups(p).toString().padLeft(6),
      _vSymmetric(p) ? 'yes' : 'no',
    ].join('  ');
    print(line);
  }
}
