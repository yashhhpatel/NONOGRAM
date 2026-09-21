/// The player's belief about a single grid cell.
///
/// This is distinct from the puzzle's solution: [CellState] describes what the
/// player has marked, never the source of truth. The solution is stored
/// separately in [Puzzle] as a binary matrix.
enum CellState {
  /// The player has not decided about this cell yet.
  unknown,

  /// The player believes this cell is part of the picture.
  filled,

  /// The player believes (or the engine has proven) this cell is blank.
  empty,
}

extension CellStateX on CellState {
  bool get isUnknown => this == CellState.unknown;
  bool get isFilled => this == CellState.filled;
  bool get isEmpty => this == CellState.empty;

  int toJson() => index;

  static CellState fromJson(int value) => CellState.values[value];
}
