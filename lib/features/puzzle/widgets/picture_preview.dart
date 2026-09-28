import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../game/models/puzzle.dart';

/// Renders the finished picture (the solution) as a compact filled-cell image.
class PicturePreview extends StatelessWidget {
  final Puzzle puzzle;
  final double size;

  /// 0..1 fraction of the picture's filled cells to draw, for a reveal
  /// animation. Defaults to fully drawn.
  final double revealProgress;

  const PicturePreview({
    super.key,
    required this.puzzle,
    this.size = 120,
    this.revealProgress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.boardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: CustomPaint(painter: _PreviewPainter(puzzle, revealProgress)),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final Puzzle puzzle;
  final double progress;
  _PreviewPainter(this.puzzle, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / puzzle.cols;
    final cellH = size.height / puzzle.rows;
    final s = cell < cellH ? cell : cellH;
    final offX = (size.width - s * puzzle.cols) / 2;
    final offY = (size.height - s * puzzle.rows) / 2;
    final paint = Paint()..color = AppTheme.filled;

    // Diagonal "wave" reveal order (top-left outward) rather than raster
    // order, purely for a nicer sweep on the Level Complete screen.
    final cells = <({int r, int c})>[];
    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        if (puzzle.solutionAt(r, c)) cells.add((r: r, c: c));
      }
    }
    cells.sort((a, b) => (a.r + a.c).compareTo(b.r + b.c));

    final toDraw = (cells.length * progress).ceil();
    for (var i = 0; i < toDraw && i < cells.length; i++) {
      final cellPos = cells[i];
      canvas.drawRect(
        Rect.fromLTWH(offX + cellPos.c * s, offY + cellPos.r * s, s + 0.5,
            s + 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) =>
      old.puzzle.id != puzzle.id || old.progress != progress;
}
