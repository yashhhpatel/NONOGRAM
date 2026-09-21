import '../engine/puzzle_generator.dart';
import '../engine/puzzle_validator.dart';
import '../models/difficulty.dart';
import '../models/puzzle.dart';
import 'art_library.dart';
import 'level_catalog.dart';

/// Produces the concrete [Puzzle] for a classic-campaign level.
///
/// Featured hand-authored art is used when available and well-formed; otherwise
/// a deterministic puzzle is generated. Results are cached in memory so opening
/// the same level twice is cheap.
class PuzzleRepository {
  final Map<int, Puzzle> _cache = {};

  /// Ids at or above this base are Daily Challenge puzzles, encoded as
  /// `base + yyyymmdd`, kept out of the 1..1000 campaign range.
  static const int dailyIdBase = 90000000;

  static int dailyIdFor(DateTime date) =>
      dailyIdBase + date.year * 10000 + date.month * 100 + date.day;

  static bool isDailyId(int id) => id >= dailyIdBase;

  Puzzle puzzleForLevel(int levelId) {
    final cached = _cache[levelId];
    if (cached != null) return cached;

    final puzzle =
        isDailyId(levelId) ? _buildDaily(levelId) : _build(LevelCatalog.infoFor(levelId));
    _cache[levelId] = puzzle;
    return puzzle;
  }

  /// Levels at or below this use hand-authored art (a gentle, recognizable
  /// teaching zone). Beyond it, puzzles follow the difficulty ramp.
  static const int _artTeachingLevels = 10;

  Puzzle _buildDaily(int id) {
    // Deterministic 10×10 daily at a fixed medium hardness.
    return PuzzleGenerator.generate(
      id: id,
      size: 10,
      category: 'Daily',
      title: 'Daily Challenge',
      hardness: 0.45,
    );
  }

  Puzzle _build(LevelInfo info) {
    // Recognizable teaching pictures for the very first levels only, so the
    // generated ramp governs difficulty everywhere else.
    if (info.id <= _artTeachingLevels) {
      final art = ArtLibrary.forBandIndex(info.size, info.indexInBand);
      if (art != null) {
        final candidate = Puzzle.fromSolution(
          id: info.id,
          solution: art.toSolution(),
          difficulty: Difficulty.veryEasy,
          category: art.category,
          title: art.title,
        );
        if (PuzzleValidator.validate(candidate).valid) {
          return candidate;
        }
      }
    }

    return PuzzleGenerator.generate(
      id: info.id,
      size: info.size,
      category: info.category,
      title: '${info.category} #${info.id}',
      hardness: PuzzleGenerator.hardnessForLevel(info.id),
    );
  }
}
