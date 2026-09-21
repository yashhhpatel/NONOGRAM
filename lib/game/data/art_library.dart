/// Original hand-authored pixel-art solutions used for early/teaching levels and
/// milestones. `#` = filled, anything else = empty. All artwork here is
/// original to this project.
class ArtPiece {
  final String category;
  final String title;
  final List<String> rows;
  const ArtPiece(this.category, this.title, this.rows);

  int get size => rows.length;

  List<List<bool>> toSolution() =>
      [for (final row in rows) [for (final ch in row.split('')) ch == '#']];
}

class ArtLibrary {
  const ArtLibrary._();

  /// Featured art grouped by grid size. Placed at the first levels of the
  /// matching size band; remaining levels in the band are generated.
  static const Map<int, List<ArtPiece>> bySize = {
    5: _fives,
    6: _sixes,
    7: _sevens,
    8: _eights,
  };

  static const List<ArtPiece> _fives = [
    ArtPiece('Symbols', 'Heart', [
      '.#.#.',
      '#####',
      '#####',
      '.###.',
      '..#..',
    ]),
    ArtPiece('Symbols', 'Plus', [
      '..#..',
      '..#..',
      '#####',
      '..#..',
      '..#..',
    ]),
    ArtPiece('Symbols', 'Arrow Up', [
      '..#..',
      '.###.',
      '#####',
      '..#..',
      '..#..',
    ]),
    ArtPiece('Symbols', 'Diamond', [
      '..#..',
      '.###.',
      '#####',
      '.###.',
      '..#..',
    ]),
    ArtPiece('Buildings', 'House', [
      '..#..',
      '.###.',
      '#####',
      '#.#.#',
      '#####',
    ]),
    ArtPiece('Plants', 'Tree', [
      '.###.',
      '#####',
      '#####',
      '..#..',
      '..#..',
    ]),
    ArtPiece('Travel', 'Sailboat', [
      '..#..',
      '..##.',
      '..###',
      '#####',
      '.###.',
    ]),
    ArtPiece('Symbols', 'Star', [
      '..#..',
      '.###.',
      '#####',
      '.###.',
      '#...#',
    ]),
    ArtPiece('Food', 'Ice Cream', [
      '.###.',
      '.###.',
      '.###.',
      '..#..',
      '..#..',
    ]),
    ArtPiece('Ocean', 'Fish', [
      '#....',
      '##.##',
      '#####',
      '##.##',
      '#....',
    ]),
  ];

  static const List<ArtPiece> _sixes = [
    ArtPiece('Animals', 'Cat', [
      '#....#',
      '##..##',
      '######',
      '#.##.#',
      '######',
      '.####.',
    ]),
    ArtPiece('Nature', 'Cloud', [
      '..##..',
      '.####.',
      '######',
      '######',
      '.####.',
      '......',
    ]),
    ArtPiece('Ocean', 'Fish', [
      '#...##',
      '#..###',
      '######',
      '######',
      '#..###',
      '#...##',
    ]),
    ArtPiece('Symbols', 'Heart', [
      '.##.##',
      '######',
      '######',
      '.####.',
      '..##..',
      '......',
    ]),
    ArtPiece('Food', 'Apple', [
      '...#..',
      '..#...',
      '.####.',
      '######',
      '######',
      '.####.',
    ]),
    ArtPiece('Space', 'Rocket', [
      '..##..',
      '.####.',
      '.####.',
      '.####.',
      '######',
      '#.##.#',
    ]),
    ArtPiece('Plants', 'Flower', [
      '.#..#.',
      '######',
      '.####.',
      '..##..',
      '..##..',
      '..##..',
    ]),
    ArtPiece('Nature', 'Sun', [
      '#.#..#',
      '.####.',
      '######',
      '######',
      '.####.',
      '#..#.#',
    ]),
  ];

  static const List<ArtPiece> _sevens = [
    ArtPiece('Animals', 'Duck', [
      '..###..',
      '.####..',
      '######.',
      '#######',
      '#######',
      '.#####.',
      '..###..',
    ]),
    ArtPiece('Space', 'Rocket', [
      '...#...',
      '..###..',
      '..###..',
      '.#####.',
      '.#####.',
      '#######',
      '#.#.#.#',
    ]),
    ArtPiece('Plants', 'Mushroom', [
      '.#####.',
      '#######',
      '#######',
      '.#####.',
      '..###..',
      '..###..',
      '..###..',
    ]),
    ArtPiece('Travel', 'Anchor', [
      '..###..',
      '..#.#..',
      '..###..',
      '#..#..#',
      '#..#..#',
      '#.###.#',
      '.#####.',
    ]),
  ];

  static const List<ArtPiece> _eights = [
    ArtPiece('Animals', 'Rabbit', [
      '.#....#.',
      '.##..##.',
      '.######.',
      '########',
      '##.##.##',
      '########',
      '.######.',
      '..####..',
    ]),
    ArtPiece('Food', 'Cupcake', [
      '..#..#..',
      '.######.',
      '########',
      '.######.',
      '.######.',
      '..####..',
      '..####..',
      '.######.',
    ]),
  ];

  /// Returns the art for a level within its size band, or null to generate.
  static ArtPiece? forBandIndex(int size, int indexInBand) {
    final list = bySize[size];
    if (list == null || indexInBand < 0 || indexInBand >= list.length) {
      return null;
    }
    return list[indexInBand];
  }
}
