import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../game/models/color_puzzle.dart';
import '../puzzle/board_metrics.dart';

/// Draws a colored nonogram: coloured clue numbers, coloured filled cells, and
/// X marks for empties.
class ColorBoardPainter extends CustomPainter {
  final ColorPuzzle puzzle;
  final List<List<int>> grid; // -1 unknown, 0 empty, 1..N colour
  final BoardMetrics m;
  final ({int r, int c})? highlight;

  ColorBoardPainter({
    required this.puzzle,
    required this.grid,
    required this.m,
    required this.highlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas);
    _paintCells(canvas);
    _paintGridLines(canvas);
    _paintClues(canvas);
    _paintHighlight(canvas);
  }

  void _paintBackground(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(m.rowGutter, m.colGutter, m.cols * m.cellSize,
          m.rows * m.cellSize),
      Paint()..color = AppTheme.boardBg,
    );
  }

  void _paintCells(Canvas canvas) {
    for (var r = 0; r < m.rows; r++) {
      for (var c = 0; c < m.cols; c++) {
        final v = grid[r][c];
        final left = m.rowGutter + c * m.cellSize;
        final top = m.colGutter + r * m.cellSize;
        if (v > 0) {
          final inset = m.cellSize * 0.06;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(left + inset, top + inset,
                  m.cellSize - inset * 2, m.cellSize - inset * 2),
              Radius.circular(m.cellSize * 0.14),
            ),
            Paint()..color = puzzle.palette[v],
          );
        } else if (v == 0) {
          final p = Paint()
            ..color = AppTheme.crossed
            ..strokeWidth = (m.cellSize * 0.08).clamp(1.5, 3.0)
            ..strokeCap = StrokeCap.round;
          final pad = m.cellSize * 0.3;
          canvas.drawLine(Offset(left + pad, top + pad),
              Offset(left + m.cellSize - pad, top + m.cellSize - pad), p);
          canvas.drawLine(Offset(left + m.cellSize - pad, top + pad),
              Offset(left + pad, top + m.cellSize - pad), p);
        }
      }
    }
  }

  void _paintGridLines(Canvas canvas) {
    final thin = Paint()
      ..color = AppTheme.gridLine
      ..strokeWidth = 1;
    final thick = Paint()
      ..color = AppTheme.gridMajor
      ..strokeWidth = 2;
    final gl = m.rowGutter, gt = m.colGutter;
    final gr = gl + m.cols * m.cellSize, gb = gt + m.rows * m.cellSize;
    for (var c = 0; c <= m.cols; c++) {
      final x = gl + c * m.cellSize;
      canvas.drawLine(Offset(x, gt), Offset(x, gb),
          (c % 5 == 0 || c == m.cols) ? thick : thin);
    }
    for (var r = 0; r <= m.rows; r++) {
      final y = gt + r * m.cellSize;
      canvas.drawLine(Offset(gl, y), Offset(gr, y),
          (r % 5 == 0 || r == m.rows) ? thick : thin);
    }
  }

  void _paintClues(Canvas canvas) {
    final fontSize = (m.clueSlot * 0.6).clamp(9.0, 20.0);

    for (var r = 0; r < m.rows; r++) {
      final clue = puzzle.rowClues[r];
      final top = m.colGutter + r * m.cellSize;
      for (var i = 0; i < clue.length; i++) {
        final slotFromRight = clue.length - i;
        final x = m.rowGutter - slotFromRight * m.clueSlot;
        _text(canvas, '${clue[i].count}', puzzle.palette[clue[i].colorIndex],
            fontSize, Rect.fromLTWH(x, top, m.clueSlot, m.cellSize));
      }
    }
    for (var c = 0; c < m.cols; c++) {
      final clue = puzzle.columnClues[c];
      final left = m.rowGutter + c * m.cellSize;
      for (var i = 0; i < clue.length; i++) {
        final slotFromBottom = clue.length - i;
        final y = m.colGutter - slotFromBottom * m.clueSlot;
        _text(canvas, '${clue[i].count}', puzzle.palette[clue[i].colorIndex],
            fontSize, Rect.fromLTWH(left, y, m.cellSize, m.clueSlot));
      }
    }
  }

  void _text(Canvas canvas, String s, Color color, double size, Rect rect) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              color: color, fontSize: size, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas,
        Offset(rect.left + (rect.width - tp.width) / 2,
            rect.top + (rect.height - tp.height) / 2));
  }

  void _paintHighlight(Canvas canvas) {
    final h = highlight;
    if (h == null) return;
    canvas.drawRect(
      Rect.fromLTWH(m.rowGutter + h.c * m.cellSize,
          m.colGutter + h.r * m.cellSize, m.cellSize, m.cellSize),
      Paint()
        ..color = AppTheme.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant ColorBoardPainter oldDelegate) =>
      oldDelegate.grid != grid ||
      oldDelegate.highlight != highlight ||
      oldDelegate.m.cellSize != m.cellSize;
}
