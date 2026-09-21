/// Metadata for the 1,000-level classic campaign. This describes each level's
/// shape and theme cheaply (no solution matrix) so the level map renders fast.
/// The actual puzzle for a level is produced on demand by the puzzle
/// repository.
class LevelInfo {
  final int id;
  final int size;
  final String category;
  final int bandStart;

  const LevelInfo({
    required this.id,
    required this.size,
    required this.category,
    required this.bandStart,
  });

  int get indexInBand => id - bandStart;
}

class _Band {
  final int start;
  final int end;
  final int size;
  const _Band(this.start, this.end, this.size);
}

class LevelCatalog {
  const LevelCatalog._();

  static const int totalLevels = 1000;

  static const List<_Band> _bands = [
    _Band(1, 20, 5),
    _Band(21, 50, 6),
    _Band(51, 100, 7),
    _Band(101, 200, 8),
    _Band(201, 350, 10),
    _Band(351, 500, 12),
    _Band(501, 700, 15),
    _Band(701, 850, 18),
    _Band(851, 1000, 20),
  ];

  static const List<String> _categories = [
    'Animals',
    'Nature',
    'Food',
    'Vehicles',
    'Sports',
    'Travel',
    'Buildings',
    'Space',
    'Ocean',
    'Plants',
    'Household',
    'Technology',
    'Symbols',
    'Fantasy',
    'Seasonal',
  ];

  static LevelInfo infoFor(int levelId) {
    assert(levelId >= 1 && levelId <= totalLevels);
    final band = _bands.firstWhere((b) => levelId >= b.start && levelId <= b.end);
    return LevelInfo(
      id: levelId,
      size: band.size,
      category: _categories[(levelId - 1) % _categories.length],
      bandStart: band.start,
    );
  }

  static int sizeFor(int levelId) => infoFor(levelId).size;
}
