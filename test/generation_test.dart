import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/game/data/level_catalog.dart';
import 'package:nonogram/game/data/puzzle_repository.dart';
import 'package:nonogram/game/engine/clue_generator.dart';

void main() {
  final repo = PuzzleRepository();

  group('LevelCatalog', () {
    test('covers 1000 levels with correct size bands', () {
      expect(LevelCatalog.totalLevels, 1000);
      expect(LevelCatalog.sizeFor(1), 5);
      expect(LevelCatalog.sizeFor(20), 5);
      expect(LevelCatalog.sizeFor(21), 6);
      expect(LevelCatalog.sizeFor(50), 6);
      expect(LevelCatalog.sizeFor(51), 7);
      expect(LevelCatalog.sizeFor(200), 8);
      expect(LevelCatalog.sizeFor(350), 10);
      expect(LevelCatalog.sizeFor(500), 12);
      expect(LevelCatalog.sizeFor(700), 15);
      expect(LevelCatalog.sizeFor(850), 18);
      expect(LevelCatalog.sizeFor(1000), 20);
    });
  });

  group('Puzzle generation is valid and deterministic', () {
    for (final id in [1, 5, 20, 35, 75, 150, 300, 450, 650, 800, 950, 1000]) {
      test('level $id produces a well-formed puzzle', () {
        final p = repo.puzzleForLevel(id);
        // Non-empty picture.
        expect(p.filledCount, greaterThan(0));
        // Correct dimensions for its band.
        expect(p.rows, LevelCatalog.sizeFor(id));
        expect(p.cols, LevelCatalog.sizeFor(id));
        // Clues are consistent with the solution.
        expect(p.rowClues, ClueGenerator.generateRowClues(p.solution));
        expect(p.columnClues, ClueGenerator.generateColumnClues(p.solution));
      });
    }

    test('same level id yields identical puzzle across repositories', () {
      final a = PuzzleRepository().puzzleForLevel(650);
      final b = PuzzleRepository().puzzleForLevel(650);
      expect(a.solution, b.solution);
    });
  });

  group('Daily puzzles', () {
    test('daily id round-trips and generates a 10x10 puzzle', () {
      final id = PuzzleRepository.dailyIdFor(DateTime(2026, 9, 21));
      expect(PuzzleRepository.isDailyId(id), isTrue);
      final p = repo.puzzleForLevel(id);
      expect(p.rows, 10);
      expect(p.cols, 10);
      expect(p.category, 'Daily');
      expect(p.filledCount, greaterThan(0));
    });
  });
}
