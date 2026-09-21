import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/game/data/color_puzzle_catalog.dart';
import 'package:nonogram/game/models/color_puzzle.dart';

void main() {
  group('Color clue generation', () {
    test('adjacent different colours need no gap; same colour merges', () {
      final p = ColorPuzzle.build(
        id: 0,
        solution: const [
          [1, 1, 2, 2, 1],
          [1, 0, 1, 0, 0],
        ],
        palette: const [Colors.transparent, Colors.red, Colors.green],
        title: 't',
        category: 'c',
      );

      List<(int, int)> runs(List<ColorRun> r) =>
          [for (final x in r) (x.count, x.colorIndex)];

      expect(runs(p.rowClues[0]), [(2, 1), (2, 2), (1, 1)]);
      expect(runs(p.rowClues[1]), [(1, 1), (1, 1)]);

      // Columns.
      expect(runs(p.columnClues[0]), [(2, 1)]);
      expect(runs(p.columnClues[2]), [(1, 2), (1, 1)]);
      expect(runs(p.columnClues[3]), [(1, 2)]);
    });
  });

  group('Color catalog', () {
    test('every puzzle is well-formed and non-empty', () {
      expect(ColorPuzzleCatalog.count, greaterThan(0));
      for (var i = 0; i < ColorPuzzleCatalog.count; i++) {
        final p = ColorPuzzleCatalog.puzzleAt(i);
        expect(p.filledCount, greaterThan(0), reason: p.title);
        expect(p.colorCount, greaterThanOrEqualTo(1), reason: p.title);
        // Every used colour index is within the palette.
        for (final row in p.solution) {
          for (final v in row) {
            expect(v, lessThan(p.palette.length), reason: p.title);
          }
        }
      }
    });
  });
}
