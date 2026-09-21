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
        color: Colors.white,
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

    final totalFilled = puzzle.filledCount;
    final toDraw = (totalFilled * progress).ceil();
    var drawn = 0;

    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        if (!puzzle.solutionAt(r, c)) continue;
        if (drawn >= toDraw) return;
        drawn++;
        canvas.drawRect(
          Rect.fromLTWH(offX + c * s, offY + r * s, s + 0.5, s + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) =>
      old.puzzle.id != puzzle.id || old.progress != progress;
}
