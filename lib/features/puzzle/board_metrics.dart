import '../../game/models/puzzle.dart';

/// Computes the geometry of the board (clue gutters + grid) for a given amount
/// of available space. Guarantees cells never shrink below a usable minimum;
/// when the board would not fit, it overflows and the screen wraps it in an
/// InteractiveViewer for pan/zoom.
class BoardMetrics {
  final double cellSize;
  final double clueSlot; // size of one clue number cell
  final double rowGutter; // width of the left clue area
  final double colGutter; // height of the top clue area
  final int maxRowClue;
  final int maxColClue;
  final int rows;
  final int cols;
  final bool needsZoom;

  const BoardMetrics({
    required this.cellSize,
    required this.clueSlot,
    required this.rowGutter,
    required this.colGutter,
    required this.maxRowClue,
    required this.maxColClue,
    required this.rows,
    required this.cols,
    required this.needsZoom,
  });

  double get boardWidth => rowGutter + cols * cellSize;
  double get boardHeight => colGutter + rows * cellSize;

  static const double _minCell = 16.0;
  static const double _fallbackCell = 26.0;
  static const double _maxCell = 46.0;
  static const double _clueRatio = 0.72;

  static BoardMetrics compute(
    Puzzle puzzle,
    double availableWidth,
    double availableHeight,
  ) {
    final maxRowClue = puzzle.rowClues
        .map((c) => c.length)
        .fold<int>(1, (a, b) => a > b ? a : b);
    final maxColClue = puzzle.columnClues
        .map((c) => c.length)
        .fold<int>(1, (a, b) => a > b ? a : b);
    return computeFor(
      rows: puzzle.rows,
      cols: puzzle.cols,
      maxRowClue: maxRowClue,
      maxColClue: maxColClue,
      availableWidth: availableWidth,
      availableHeight: availableHeight,
    );
  }

  static BoardMetrics computeFor({
    required int rows,
    required int cols,
    required int maxRowClue,
    required int maxColClue,
    required double availableWidth,
    required double availableHeight,
  }) {
    final wCell = availableWidth / (cols + maxRowClue * _clueRatio);
    final hCell = availableHeight / (rows + maxColClue * _clueRatio);
    final fitCell = wCell < hCell ? wCell : hCell;

    double cell;
    bool needsZoom;
    if (fitCell >= _minCell) {
      cell = fitCell > _maxCell ? _maxCell : fitCell;
      needsZoom = false;
    } else {
      cell = _fallbackCell;
      needsZoom = true;
    }

    final clueSlot = cell * _clueRatio;
    return BoardMetrics(
      cellSize: cell,
      clueSlot: clueSlot,
      rowGutter: maxRowClue * clueSlot,
      colGutter: maxColClue * clueSlot,
      maxRowClue: maxRowClue,
      maxColClue: maxColClue,
      rows: rows,
      cols: cols,
      needsZoom: needsZoom,
    );
  }

  /// Maps a local position (within the board) to a grid cell, or null if the
  /// touch is in a clue gutter or outside the grid.
  ({int r, int c})? cellAt(double x, double y) {
    final gx = x - rowGutter;
    final gy = y - colGutter;
    if (gx < 0 || gy < 0) return null;
    final c = (gx / cellSize).floor();
    final r = (gy / cellSize).floor();
    if (r < 0 || r >= rows || c < 0 || c >= cols) return null;
    return (r: r, c: c);
  }
}
