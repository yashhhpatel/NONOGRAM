import 'dart:math' as math;

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

  /// Cells currently playing the fill/mark "pop" animation, and its 0..1
  /// progress (scale-in plus a brief success glow for filled cells).
  final Set<({int r, int c})> popCells;
  final double popValue;

  /// Rows/columns that just became fully satisfied, and a shared 0..1
  /// progress for their one-shot completion glow (peaks mid-animation).
  final Set<int> glowingRows;
  final Set<int> glowingCols;
  final double lineGlowValue;

  /// 0..1 entrance progress: staggers the clue numbers in and fades/scales
  /// the grid in when a level first opens. 1.0 = fully settled (default).
  final double entrance;

  final bool solvedRowsColsHint;

  BoardPainter({
    required this.puzzle,
    required this.grid,
    required this.m,
    required this.highlight,
    required this.fillColor,
    this.popCells = const {},
    this.popValue = 1.0,
    this.glowingRows = const {},
    this.glowingCols = const {},
    this.lineGlowValue = 0.0,
    this.entrance = 1.0,
    this.solvedRowsColsHint = false,
  });

  double _scaleFor(int r, int c) {
    if (popCells.isEmpty || !popCells.contains((r: r, c: c))) return 1.0;
    // Ease-out-back-ish: pop up past 1 then settle.
    final t = popValue.clamp(0.0, 1.0);
    return 0.5 + 0.6 * t - 0.1 * (t * t);
  }

  /// Brief success glow behind a cell that was *just* correctly filled.
  double _glowFor(int r, int c) {
    if (popCells.isEmpty || !popCells.contains((r: r, c: c))) return 0.0;
    if (grid[r][c] != CellState.filled) return 0.0;
    // Fades out over the pop's lifetime.
    return (1.0 - popValue.clamp(0.0, 1.0));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final e = entrance.clamp(0.0, 1.0);
    canvas.save();
    if (e < 1.0) {
      // Scale the whole board slightly up from the center while fading in.
      final cx = m.rowGutter + m.cols * m.cellSize / 2;
      final cy = m.colGutter + m.rows * m.cellSize / 2;
      final scale = 0.94 + 0.06 * Curves.easeOutCubic.transform(e);
      canvas.translate(cx, cy);
      canvas.scale(scale);
      canvas.translate(-cx, -cy);
    }
    _paintGridBackground(canvas);
    _paintLineGlow(canvas);
    _paintCells(canvas);
    _paintGridLines(canvas);
    _paintClues(canvas, e);
    _paintHighlight(canvas);
    canvas.restore();
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
          final glow = _glowFor(r, c);
          if (glow > 0) {
            final glowPaint = Paint()
              ..color = AppTheme.success.withOpacity(0.55 * glow)
              ..maskFilter = MaskFilter.blur(
                BlurStyle.normal,
                m.cellSize * 0.35,
              );
            canvas.drawCircle(
              Offset(left + m.cellSize / 2, top + m.cellSize / 2),
              m.cellSize * 0.62,
              glowPaint,
            );
          }
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
          _paintCross(canvas, left, top, _scaleFor(r, c));
        }
      }
    }
  }

  void _paintCross(Canvas canvas, double left, double top, double scale) {
    final p = Paint()
      ..color = AppTheme.crossed
      ..strokeWidth = (m.cellSize * 0.08).clamp(1.5, 3.0)
      ..strokeCap = StrokeCap.round;
    final cx = left + m.cellSize / 2;
    final cy = top + m.cellSize / 2;
    final pad = m.cellSize * 0.3 + m.cellSize * 0.2 * (1 - scale);
    canvas.drawLine(
      Offset(cx - (m.cellSize / 2 - pad), cy - (m.cellSize / 2 - pad)),
      Offset(cx + (m.cellSize / 2 - pad), cy + (m.cellSize / 2 - pad)),
      p,
    );
    canvas.drawLine(
      Offset(cx + (m.cellSize / 2 - pad), cy - (m.cellSize / 2 - pad)),
      Offset(cx - (m.cellSize / 2 - pad), cy + (m.cellSize / 2 - pad)),
      p,
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
    // A bright band that travels along the solved line, like a word being
    // traced out, fading as it reaches the end.
    final bandLen = m.cellSize * 1.6;
    final sweepColor = AppTheme.success.withOpacity(0.38 * (1 - t));

    for (final r in glowingRows) {
      final rect = Rect.fromLTWH(
        m.rowGutter,
        m.colGutter + r * m.cellSize,
        m.cols * m.cellSize,
        m.cellSize,
      );
      canvas.drawRect(rect, paint);
      final x = rect.left - bandLen + (rect.width + bandLen) * t;
      _paintSweep(canvas, rect,
          Rect.fromLTWH(x, rect.top, bandLen, rect.height), sweepColor,
          horizontal: true);
    }
    for (final c in glowingCols) {
      final rect = Rect.fromLTWH(
        m.rowGutter + c * m.cellSize,
        m.colGutter,
        m.cellSize,
        m.rows * m.cellSize,
      );
      canvas.drawRect(rect, paint);
      final y = rect.top - bandLen + (rect.height + bandLen) * t;
      _paintSweep(canvas, rect,
          Rect.fromLTWH(rect.left, y, rect.width, bandLen), sweepColor,
          horizontal: false);
    }
  }

  void _paintSweep(Canvas canvas, Rect clip, Rect band, Color color,
      {required bool horizontal}) {
    final shader = LinearGradient(
      begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
      end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
      colors: [color.withOpacity(0), color, color.withOpacity(0)],
    ).createShader(band);
    canvas.save();
    canvas.clipRect(clip);
    canvas.drawRect(band, Paint()..shader = shader);
    canvas.restore();
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

  void _paintClues(Canvas canvas, double entranceProgress) {
    final fontSize = (m.clueSlot * 0.62).clamp(9.0, 22.0);
    final staggered = entranceProgress < 1.0;
    final maxIndex = (m.rows + m.cols).clamp(1, 1 << 30);

    // Row clues (left gutter), right-aligned to the grid edge.
    for (var r = 0; r < m.rows; r++) {
      final clue = puzzle.rowClues[r];
      if (clue.length == 1 && clue.first == 0) continue;
      final top = m.colGutter + r * m.cellSize;
      final opacity = staggered
          ? _staggerOpacity(r, maxIndex, entranceProgress)
          : 1.0;
      if (opacity <= 0) continue;
      final style = TextStyle(
        color: AppTheme.ink.withOpacity(opacity),
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      );
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
      final opacity = staggered
          ? _staggerOpacity(m.rows + c, maxIndex, entranceProgress)
          : 1.0;
      if (opacity <= 0) continue;
      final style = TextStyle(
        color: AppTheme.ink.withOpacity(opacity),
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      );
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

  /// Staggers clue opacity by index so clues sweep in rather than popping
  /// in all at once. Each clue gets its own short opacity ramp within the
  /// overall entrance window.
  double _staggerOpacity(int index, int count, double progress) {
    const window = 0.55; // fraction of the entrance each clue ramps over
    final start = (index / count) * (1 - window);
    final local = ((progress - start) / window).clamp(0.0, 1.0);
    return Curves.easeOut.transform(local);
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
        oldDelegate.glowingRows != glowingRows ||
        oldDelegate.glowingCols != glowingCols ||
        oldDelegate.lineGlowValue != lineGlowValue ||
        oldDelegate.entrance != entrance ||
        oldDelegate.m.cellSize != m.cellSize;
  }
}
