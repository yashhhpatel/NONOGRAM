import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../game/models/cell_state.dart';
import '../../game/models/puzzle.dart';
import 'board_metrics.dart';

/// Draws the clues and the grid. Uses direct canvas drawing so even a 20×20
/// board repaints cheaply.
class BoardPainter extends CustomPainter {
  final Puzzle puzzle;
  final List<List<CellState>> grid;
  final BoardMetrics m;
  final ({int r, int c})? highlight;
  final Color fillColor;

  /// Cells currently playing the fill "pop" animation, and its 0..1 progress.
  final Set<({int r, int c})> popCells;
  final double popValue;
  final bool solvedRowsColsHint;

  BoardPainter({
    required this.puzzle,
    required this.grid,
    required this.m,
    required this.highlight,
    required this.fillColor,
    this.popCells = const {},
    this.popValue = 1.0,
    this.solvedRowsColsHint = false,
  });

  double _scaleFor(int r, int c) {
    if (popCells.isEmpty || !popCells.contains((r: r, c: c))) return 1.0;
    // Ease-out-back-ish: pop up past 1 then settle.
    final t = popValue.clamp(0.0, 1.0);
    return 0.5 + 0.6 * t - 0.1 * (t * t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintGridBackground(canvas);
    _paintCells(canvas);
    _paintGridLines(canvas);
    _paintClues(canvas);
    _paintHighlight(canvas);
  }

  void _paintGridBackground(Canvas canvas) {
    final rect = Rect.fromLTWH(
      m.rowGutter,
      m.colGutter,
      m.cols * m.cellSize,
      m.rows * m.cellSize,
    );
    canvas.drawRect(rect, Paint()..color = AppTheme.boardBg);
  }

  void _paintCells(Canvas canvas) {
    final fill = Paint()..color = fillColor;
    for (var r = 0; r < m.rows; r++) {
      for (var c = 0; c < m.cols; c++) {
        final state = grid[r][c];
        final left = m.rowGutter + c * m.cellSize;
        final top = m.colGutter + r * m.cellSize;
        if (state == CellState.filled) {
          final scale = _scaleFor(r, c);
          final baseInset = m.cellSize * 0.06;
          final extra = m.cellSize * (1 - scale) / 2;
          final inset = baseInset + extra;
          final side = m.cellSize - inset * 2;
          if (side <= 0) continue;
          final rrect = RRect.fromRectAndRadius(
            Rect.fromLTWH(left + inset, top + inset, side, side),
            Radius.circular(m.cellSize * 0.14),
          );
          canvas.drawRRect(rrect, fill);
        } else if (state == CellState.empty) {
          _paintCross(canvas, left, top);
        }
      }
    }
  }

  void _paintCross(Canvas canvas, double left, double top) {
    final p = Paint()
      ..color = AppTheme.crossed
      ..strokeWidth = (m.cellSize * 0.08).clamp(1.5, 3.0)
      ..strokeCap = StrokeCap.round;
    final pad = m.cellSize * 0.3;
    canvas.drawLine(
      Offset(left + pad, top + pad),
      Offset(left + m.cellSize - pad, top + m.cellSize - pad),
      p,
    );
    canvas.drawLine(
      Offset(left + m.cellSize - pad, top + pad),
      Offset(left + pad, top + m.cellSize - pad),
      p,
    );
  }

  void _paintGridLines(Canvas canvas) {
    final thin = Paint()
      ..color = AppTheme.gridLine
      ..strokeWidth = 1;
    final thick = Paint()
      ..color = AppTheme.gridMajor
      ..strokeWidth = 2;

    final gridLeft = m.rowGutter;
    final gridTop = m.colGutter;
    final gridRight = gridLeft + m.cols * m.cellSize;
    final gridBottom = gridTop + m.rows * m.cellSize;

    for (var c = 0; c <= m.cols; c++) {
      final x = gridLeft + c * m.cellSize;
      final major = c % 5 == 0 || c == m.cols;
      canvas.drawLine(
        Offset(x, gridTop),
        Offset(x, gridBottom),
        major ? thick : thin,
      );
    }
    for (var r = 0; r <= m.rows; r++) {
      final y = gridTop + r * m.cellSize;
      final major = r % 5 == 0 || r == m.rows;
      canvas.drawLine(
        Offset(gridLeft, y),
        Offset(gridRight, y),
        major ? thick : thin,
      );
    }
  }

  void _paintClues(Canvas canvas) {
    final fontSize = (m.clueSlot * 0.62).clamp(9.0, 22.0);
    final style = TextStyle(
      color: AppTheme.ink,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
    );

    // Row clues (left gutter), right-aligned to the grid edge.
    for (var r = 0; r < m.rows; r++) {
      final clue = puzzle.rowClues[r];
      if (clue.length == 1 && clue.first == 0) continue;
      final top = m.colGutter + r * m.cellSize;
      for (var i = 0; i < clue.length; i++) {
        // Place from the right edge of the gutter backwards.
        final slotFromRight = clue.length - i;
        final x = m.rowGutter - slotFromRight * m.clueSlot;
        _drawCenteredText(
          canvas,
          '${clue[i]}',
          style,
          Rect.fromLTWH(x, top, m.clueSlot, m.cellSize),
        );
      }
    }

    // Column clues (top gutter), bottom-aligned to the grid edge.
    for (var c = 0; c < m.cols; c++) {
      final clue = puzzle.columnClues[c];
      if (clue.length == 1 && clue.first == 0) continue;
      final left = m.rowGutter + c * m.cellSize;
      for (var i = 0; i < clue.length; i++) {
        final slotFromBottom = clue.length - i;
        final y = m.colGutter - slotFromBottom * m.clueSlot;
        _drawCenteredText(
          canvas,
          '${clue[i]}',
          style,
          Rect.fromLTWH(left, y, m.cellSize, m.clueSlot),
        );
      }
    }
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    TextStyle style,
    Rect rect,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = Offset(
      rect.left + (rect.width - tp.width) / 2,
      rect.top + (rect.height - tp.height) / 2,
    );
    tp.paint(canvas, offset);
  }

  void _paintHighlight(Canvas canvas) {
    final h = highlight;
    if (h == null) return;
    final left = m.rowGutter + h.c * m.cellSize;
    final top = m.colGutter + h.r * m.cellSize;
    final paint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(
      Rect.fromLTWH(left, top, m.cellSize, m.cellSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.grid != grid ||
        oldDelegate.highlight != highlight ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.popValue != popValue ||
        oldDelegate.popCells != popCells ||
        oldDelegate.m.cellSize != m.cellSize;
  }
}
