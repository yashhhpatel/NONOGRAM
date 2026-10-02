import 'dart:math' as math;

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

  /// Cells playing the fill/mark pop-in, and its 0..1 progress.
  final Set<({int r, int c})> popCells;
  final double popValue;

  /// Rows/columns that just became fully correct, and their shared 0..1
  /// glow progress.
  final Set<int> glowingRows;
  final Set<int> glowingCols;
  final double lineGlowValue;

  /// 0..1 level-start entrance (grid scale-in + staggered clues).
  final double entrance;

  ColorBoardPainter({
    required this.puzzle,
    required this.grid,
    required this.m,
    required this.highlight,
    this.popCells = const {},
    this.popValue = 1.0,
    this.glowingRows = const {},
    this.glowingCols = const {},
    this.lineGlowValue = 0.0,
    this.entrance = 1.0,
  });

  bool _popping(int r, int c) =>
      popCells.isNotEmpty && popCells.contains((r: r, c: c));

  double _scaleFor(int r, int c) {
    if (!_popping(r, c)) return 1.0;
    final t = popValue.clamp(0.0, 1.0);
    return 0.5 + 0.6 * t - 0.1 * (t * t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final e = entrance.clamp(0.0, 1.0);
    canvas.save();
    if (e < 1.0) {
      final cx = m.rowGutter + m.cols * m.cellSize / 2;
      final cy = m.colGutter + m.rows * m.cellSize / 2;
      final scale = 0.94 + 0.06 * Curves.easeOutCubic.transform(e);
      canvas.translate(cx, cy);
      canvas.scale(scale);
      canvas.translate(-cx, -cy);
    }
    _paintBackground(canvas);
    _paintLineGlow(canvas);
    _paintCells(canvas);
    _paintGridLines(canvas);
    _paintClues(canvas, e);
    _paintHighlight(canvas);
    canvas.restore();
  }

  void _paintBackground(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(m.rowGutter, m.colGutter, m.cols * m.cellSize,
          m.rows * m.cellSize),
      Paint()..color = AppTheme.boardBg,
    );
  }

  void _paintLineGlow(Canvas canvas) {
    if ((glowingRows.isEmpty && glowingCols.isEmpty) || lineGlowValue <= 0) {
      return;
    }
    final t = lineGlowValue.clamp(0.0, 1.0);
    final opacity = math.sin(t * math.pi);
    if (opacity <= 0) return;
    final paint = Paint()..color = AppTheme.success.withOpacity(0.16 * opacity);
    for (final r in glowingRows) {
      canvas.drawRect(
          Rect.fromLTWH(m.rowGutter, m.colGutter + r * m.cellSize,
              m.cols * m.cellSize, m.cellSize),
          paint);
    }
    for (final c in glowingCols) {
      canvas.drawRect(
          Rect.fromLTWH(m.rowGutter + c * m.cellSize, m.colGutter,
              m.cellSize, m.rows * m.cellSize),
          paint);
    }
  }

  void _paintCells(Canvas canvas) {
    for (var r = 0; r < m.rows; r++) {
      for (var c = 0; c < m.cols; c++) {
        final v = grid[r][c];
        final left = m.rowGutter + c * m.cellSize;
        final top = m.colGutter + r * m.cellSize;
        final scale = _scaleFor(r, c);
        if (v > 0) {
          final color = puzzle.palette[v];
          if (_popping(r, c)) {
            // A soft halo in the cell's own colour as it lands.
            canvas.drawCircle(
              Offset(left + m.cellSize / 2, top + m.cellSize / 2),
              m.cellSize * 0.62,
              Paint()
                ..color = color.withOpacity(0.5 * (1 - popValue.clamp(0, 1)))
                ..maskFilter =
                    MaskFilter.blur(BlurStyle.normal, m.cellSize * 0.35),
            );
          }
          final inset = m.cellSize * 0.06 + m.cellSize * (1 - scale) / 2;
          final side = m.cellSize - inset * 2;
          if (side <= 0) continue;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(left + inset, top + inset, side, side),
              Radius.circular(m.cellSize * 0.14),
            ),
            Paint()..color = color,
          );
        } else if (v == 0) {
          final p = Paint()
            ..color = AppTheme.crossed
            ..strokeWidth = (m.cellSize * 0.08).clamp(1.5, 3.0)
            ..strokeCap = StrokeCap.round;
          final cx = left + m.cellSize / 2, cy = top + m.cellSize / 2;
          final half = m.cellSize / 2 - (m.cellSize * 0.3 + m.cellSize * 0.2 * (1 - scale));
          canvas.drawLine(Offset(cx - half, cy - half),
              Offset(cx + half, cy + half), p);
          canvas.drawLine(Offset(cx + half, cy - half),
              Offset(cx - half, cy + half), p);
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

  double _staggerOpacity(int index, int count, double progress) {
    if (progress >= 1.0) return 1.0;
    const window = 0.55;
    final start = (index / count) * (1 - window);
    return Curves.easeOut
        .transform(((progress - start) / window).clamp(0.0, 1.0));
  }

  void _paintClues(Canvas canvas, double entranceProgress) {
    final fontSize = (m.clueSlot * 0.6).clamp(9.0, 20.0);
    final count = math.max(1, m.rows + m.cols);

    for (var r = 0; r < m.rows; r++) {
      final a = _staggerOpacity(r, count, entranceProgress);
      if (a <= 0) continue;
      final clue = puzzle.rowClues[r];
      final top = m.colGutter + r * m.cellSize;
      for (var i = 0; i < clue.length; i++) {
        final slotFromRight = clue.length - i;
        final x = m.rowGutter - slotFromRight * m.clueSlot;
        _text(canvas, '${clue[i].count}',
            puzzle.palette[clue[i].colorIndex].withOpacity(a), fontSize,
            Rect.fromLTWH(x, top, m.clueSlot, m.cellSize));
      }
    }
    for (var c = 0; c < m.cols; c++) {
      final a = _staggerOpacity(m.rows + c, count, entranceProgress);
      if (a <= 0) continue;
      final clue = puzzle.columnClues[c];
      final left = m.rowGutter + c * m.cellSize;
      for (var i = 0; i < clue.length; i++) {
        final slotFromBottom = clue.length - i;
        final y = m.colGutter - slotFromBottom * m.clueSlot;
        _text(canvas, '${clue[i].count}',
            puzzle.palette[clue[i].colorIndex].withOpacity(a), fontSize,
            Rect.fromLTWH(left, y, m.cellSize, m.clueSlot));
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
      oldDelegate.popValue != popValue ||
      oldDelegate.popCells != popCells ||
      oldDelegate.glowingRows != glowingRows ||
      oldDelegate.glowingCols != glowingCols ||
      oldDelegate.lineGlowValue != lineGlowValue ||
      oldDelegate.entrance != entrance ||
      oldDelegate.m.cellSize != m.cellSize;
}
