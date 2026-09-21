import 'package:flutter/material.dart';

/// One clue group in a colored nonogram: a run of [count] consecutive cells of
/// colour [colorIndex]. Adjacent runs of *different* colours need no gap;
/// adjacent runs of the *same* colour do (they'd otherwise merge).
class ColorRun {
  final int count;
  final int colorIndex; // 1..N
  const ColorRun(this.count, this.colorIndex);
}

/// A fully-specified colored nonogram.
///
/// [solution] holds a colour index per cell: 0 = empty, 1..N = a colour from
/// [palette] (whose index 0 is an unused placeholder).
class ColorPuzzle {
  final int id;
  final int rows;
  final int cols;
  final List<List<int>> solution;
  final List<Color> palette; // index 0 unused; 1..N are the colours
  final List<List<ColorRun>> rowClues;
  final List<List<ColorRun>> columnClues;
  final String title;
  final String category;

  const ColorPuzzle._({
    required this.id,
    required this.rows,
    required this.cols,
    required this.solution,
    required this.palette,
    required this.rowClues,
    required this.columnClues,
    required this.title,
    required this.category,
  });

  factory ColorPuzzle.build({
    required int id,
    required List<List<int>> solution,
    required List<Color> palette,
    required String title,
    required String category,
  }) {
    final rows = solution.length;
    final cols = solution.first.length;
    return ColorPuzzle._(
      id: id,
      rows: rows,
      cols: cols,
      solution: solution,
      palette: palette,
      rowClues: [for (final row in solution) _runsFor(row)],
      columnClues: [
        for (var c = 0; c < cols; c++)
          _runsFor([for (var r = 0; r < rows; r++) solution[r][c]]),
      ],
      title: title,
      category: category,
    );
  }

  static List<ColorRun> _runsFor(List<int> line) {
    final runs = <ColorRun>[];
    var count = 0;
    var color = 0;
    for (final v in line) {
      if (v == color && v != 0) {
        count++;
      } else {
        if (count > 0) runs.add(ColorRun(count, color));
        color = v;
        count = v == 0 ? 0 : 1;
      }
    }
    if (count > 0) runs.add(ColorRun(count, color));
    return runs;
  }

  int colorAt(int r, int c) => solution[r][c];

  int get colorCount => palette.length - 1;

  int get filledCount =>
      solution.fold(0, (s, row) => s + row.where((v) => v != 0).length);
}
