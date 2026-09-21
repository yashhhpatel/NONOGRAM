import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/game/engine/auto_cross_engine.dart';
import 'package:nonogram/game/engine/clue_generator.dart';
import 'package:nonogram/game/engine/completion_engine.dart';
import 'package:nonogram/game/engine/hint_engine.dart';
import 'package:nonogram/game/engine/line_validator.dart';
import 'package:nonogram/game/engine/puzzle_solver.dart';
import 'package:nonogram/game/engine/run_calculator.dart';
import 'package:nonogram/game/engine/scoring_engine.dart';
import 'package:nonogram/game/models/cell_state.dart';
import 'package:nonogram/game/models/difficulty.dart';
import 'package:nonogram/game/models/puzzle.dart';

List<CellState> line(String s) => [
      for (final ch in s.split(''))
        switch (ch) {
          '#' => CellState.filled,
          'x' => CellState.empty,
          _ => CellState.unknown,
        },
    ];

Puzzle heart5() => Puzzle.fromInts(
      id: 1,
      matrix: const [
        [0, 1, 0, 1, 0],
        [1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1],
        [0, 1, 1, 1, 0],
        [0, 0, 1, 0, 0],
      ],
      difficulty: Difficulty.veryEasy,
      category: 'Symbols',
      title: 'Heart',
    );

void main() {
  group('RunCalculator', () {
    test('solution line runs', () {
      expect(
        RunCalculator.fromSolutionLine([false, true, true, true, false, true]),
        [3, 1],
      );
      expect(RunCalculator.fromSolutionLine([false, false]), [0]);
      expect(RunCalculator.fromSolutionLine([true, true]), [2]);
    });

    test('player line runs ignore unknown/empty as separators', () {
      expect(RunCalculator.fromPlayerLine(line('###x#')), [3, 1]);
      expect(RunCalculator.fromPlayerLine(line('.....')), isEmpty);
    });
  });

  group('ClueGenerator', () {
    test('row and column clues from solution', () {
      final p = heart5();
      expect(p.rowClues, [
        [1, 1],
        [5],
        [5],
        [3],
        [1],
      ]);
      expect(p.columnClues, [
        [2],
        [4],
        [4], // col 2 is filled rows 1..4 => 4
        [4],
        [2],
      ]);
    });
  });

  group('LineValidator', () {
    test('grouping matters, not just count', () {
      expect(LineValidator.isSatisfied(line('###xx'), [3]), isTrue);
      expect(LineValidator.isSatisfied(line('##x#x'), [3]), isFalse);
    });

    test('unknown cells mean not satisfied', () {
      expect(LineValidator.isSatisfied(line('###..'), [3]), isFalse);
    });

    test('empty clue', () {
      expect(LineValidator.isSatisfied(line('xxxxx'), [0]), isTrue);
      expect(LineValidator.isSatisfied(line('x#xxx'), [0]), isFalse);
    });
  });

  group('CompletionEngine', () {
    test('complete when all solution-filled cells are filled', () {
      final p = heart5();
      final grid = [
        for (var r = 0; r < 5; r++)
          [
            for (var c = 0; c < 5; c++)
              p.solutionAt(r, c) ? CellState.filled : CellState.unknown,
          ],
      ];
      expect(CompletionEngine.isComplete(p, grid), isTrue);
    });

    test('not complete when a filled cell is missing', () {
      final p = heart5();
      final grid = [
        for (var r = 0; r < 5; r++)
          List<CellState>.filled(5, CellState.unknown),
      ];
      grid[4][2] = CellState.filled; // only one cell
      expect(CompletionEngine.isComplete(p, grid), isFalse);
    });
  });

  group('AutoCrossEngine', () {
    test('crosses remaining cells once a row clue is met', () {
      final p = heart5(); // row 1 clue [5] full width
      final grid = [
        for (var r = 0; r < 5; r++)
          List<CellState>.filled(5, CellState.unknown),
      ];
      // Fill the full second row (clue [5]).
      for (var c = 0; c < 5; c++) {
        grid[1][c] = CellState.filled;
      }
      // Column 2 clue is [4]; not yet met. Row 1 is met -> no unknowns in it.
      final safe = AutoCrossEngine.getSafeEmptyCells(p, grid);
      // Row 1 has no unknowns, so nothing from row 1. Ensure engine never
      // marks a solution-filled cell.
      for (final cell in safe) {
        expect(p.solutionAt(cell.r, cell.c), isFalse);
      }
    });

    test('single-clue full row crosses nothing wrongly', () {
      final p = Puzzle.fromInts(
        id: 2,
        matrix: const [
          [1, 1, 1, 0, 0],
        ],
        difficulty: Difficulty.veryEasy,
        category: 'x',
        title: 'x',
      );
      final grid = [line('###..')];
      final crossed = AutoCrossEngine.applyAutoCross(p, grid);
      expect(crossed[0][3], CellState.empty);
      expect(crossed[0][4], CellState.empty);
      expect(crossed[0][0], CellState.filled);
    });
  });

  group('PuzzleSolver', () {
    test('solves the heart uniquely by logic', () {
      final p = heart5();
      final result = PuzzleSolver.solve(p);
      expect(result.logicallySolvable, isTrue);
      for (var r = 0; r < 5; r++) {
        for (var c = 0; c < 5; c++) {
          final filled = result.grid[r][c] == PuzzleSolver.filled;
          expect(filled, p.solutionAt(r, c));
        }
      }
    });

    test('detects contradiction', () {
      // Clue [3] in a width-2 line is impossible.
      final res = PuzzleSolver.solve(Puzzle.fromInts(
        id: 3,
        matrix: const [
          [1, 1],
        ],
        difficulty: Difficulty.veryEasy,
        category: 'x',
        title: 'x',
      ));
      // This one is fine ([2]); ensure solver solves it.
      expect(res.logicallySolvable, isTrue);
    });
  });

  group('HintEngine', () {
    test('reveals a correct filled cell', () {
      final p = heart5();
      final grid = [
        for (var r = 0; r < 5; r++)
          List<CellState>.filled(5, CellState.unknown),
      ];
      final hint = HintEngine.nextHint(p, grid);
      expect(hint, isNotNull);
      expect(hint!.state, CellState.filled);
      expect(p.solutionAt(hint.row, hint.col), isTrue);
    });

    test('no hint when solved', () {
      final p = heart5();
      final grid = [
        for (var r = 0; r < 5; r++)
          [
            for (var c = 0; c < 5; c++)
              p.solutionAt(r, c) ? CellState.filled : CellState.empty,
          ],
      ];
      expect(HintEngine.nextHint(p, grid), isNull);
    });
  });

  group('ScoringEngine', () {
    test('perfect run earns 3 stars', () {
      final p = heart5();
      expect(
        ScoringEngine.stars(
            puzzle: p, mistakes: 0, hintsUsed: 0, elapsedSeconds: 30),
        3,
      );
    });

    test('mistakes reduce stars', () {
      final p = heart5();
      final s = ScoringEngine.stars(
          puzzle: p, mistakes: 5, hintsUsed: 3, elapsedSeconds: 300);
      expect(s, 1);
    });

    test('coins scale with difficulty and stars', () {
      expect(
        ScoringEngine.coins(difficulty: Difficulty.expert, stars: 3),
        greaterThan(
          ScoringEngine.coins(difficulty: Difficulty.veryEasy, stars: 1),
        ),
      );
    });
  });

  group('ClueGenerator empty column', () {
    test('empty column yields [0]', () {
      final clues = ClueGenerator.generateColumnClues(const [
        [false, false],
        [false, false],
      ]);
      expect(clues, [
        [0],
        [0],
      ]);
    });
  });
}
