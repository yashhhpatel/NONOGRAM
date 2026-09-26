import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// The signature Home ambience: faint mini Nonogram grids that solve
/// cell-by-cell, give a brief celebratory pulse, fade out, and begin a new
/// puzzle — looping seamlessly. Purely decorative and low-contrast so content
/// stays readable. Honors the platform reduced-motion setting.
class PuzzleRevealBackground extends StatefulWidget {
  const PuzzleRevealBackground({super.key});

  @override
  State<PuzzleRevealBackground> createState() => _PuzzleRevealBackgroundState();
}

class _PuzzleRevealBackgroundState extends State<PuzzleRevealBackground>
    with SingleTickerProviderStateMixin {
  // A 30s master loop; per-grid cycles divide 30 so the loop is seamless.
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 30));

  // Grid layout as fractions of the canvas: (centerX, centerY, sizeFraction,
  // gridCount, cycleSeconds, phaseSeconds).
  static const _grids = <_GridSpec>[
    _GridSpec(0.18, 0.30, 0.20, 4, 6, 0.0),
    _GridSpec(0.82, 0.22, 0.16, 4, 5, 1.6),
    _GridSpec(0.72, 0.62, 0.22, 5, 6, 3.1),
    _GridSpec(0.24, 0.74, 0.17, 4, 5, 2.2),
    _GridSpec(0.50, 0.90, 0.15, 4, 6, 4.4),
    _GridSpec(0.90, 0.86, 0.14, 4, 5, 0.8),
  ];

  bool _motion = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduce && !_controller.isAnimating) {
      _controller.repeat();
    }
    _motion = !reduce;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _PuzzlePainter(
              clock: _motion ? _controller.value * 30 : 6.0, // static frame
              grids: _grids,
              fill: AppTheme.filled,
              accent: AppTheme.accent,
              baseAlpha: dark ? 0.10 : 0.07,
              lineAlpha: dark ? 0.06 : 0.05,
              animate: _motion,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _GridSpec {
  final double cx, cy, sizeFrac;
  final int n;
  final int cycle;
  final double phase;
  const _GridSpec(
      this.cx, this.cy, this.sizeFrac, this.n, this.cycle, this.phase);
}

class _PuzzlePainter extends CustomPainter {
  final double clock;
  final List<_GridSpec> grids;
  final Color fill;
  final Color accent;
  final double baseAlpha;
  final double lineAlpha;
  final bool animate;

  _PuzzlePainter({
    required this.clock,
    required this.grids,
    required this.fill,
    required this.accent,
    required this.baseAlpha,
    required this.lineAlpha,
    required this.animate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    for (final g in grids) {
      final gridSize = shortest * g.sizeFrac;
      final left = size.width * g.cx - gridSize / 2;
      final top = size.height * g.cy - gridSize / 2;
      _paintGrid(canvas, g, left, top, gridSize);
    }
  }

  void _paintGrid(
      Canvas canvas, _GridSpec g, double left, double top, double gridSize) {
    final cell = gridSize / g.n;
    final t = (clock + g.phase) % g.cycle;
    final progress = t / g.cycle; // 0..1
    final cycleIndex = ((clock + g.phase) / g.cycle).floor();

    // Cell pattern for this cycle (deterministic).
    final pattern = _pattern(g, cycleIndex);
    final filled = <int>[];
    for (var i = 0; i < g.n * g.n; i++) {
      if (pattern[i]) filled.add(i);
    }
    if (filled.isEmpty) return;

    // Phase windows: reveal -> celebrate -> fade -> rest.
    final revealFrac = animate ? (progress / 0.55).clamp(0.0, 1.0) : 1.0;
    final celebrate = animate && progress > 0.55 && progress < 0.70;
    double groupAlpha = 1.0;
    if (animate) {
      if (progress > 0.72 && progress < 0.92) {
        groupAlpha = 1 - (progress - 0.72) / 0.20;
      } else if (progress >= 0.92) {
        groupAlpha = 0;
      }
    }
    if (groupAlpha <= 0) {
      _paintLines(canvas, left, top, gridSize, g.n, cell);
      return;
    }

    final revealed = revealFrac * filled.length;
    final paint = Paint();
    for (var k = 0; k < filled.length; k++) {
      final cellProgress = (revealed - k).clamp(0.0, 1.0);
      if (cellProgress <= 0) continue;
      final idx = filled[k];
      final r = idx ~/ g.n;
      final c = idx % g.n;
      final pulse = celebrate ? 1.0 + 0.12 * _celebratePulse(progress) : 1.0;
      final scale = (0.55 + 0.45 * cellProgress) * pulse;
      final a = baseAlpha * cellProgress * groupAlpha;
      // The most-recently revealed cell gets a subtle accent highlight.
      final isLeadingEdge =
          animate && !celebrate && (revealed - k) > 0 && (revealed - k) < 1;
      paint.color = (isLeadingEdge ? accent : fill).withOpacity(a);

      final inset = cell * (1 - scale) / 2 + cell * 0.08;
      final rect = Rect.fromLTWH(
        left + c * cell + inset,
        top + r * cell + inset,
        cell - inset * 2,
        cell - inset * 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.18)),
        paint,
      );
    }

    _paintLines(canvas, left, top, gridSize, g.n, cell, groupAlpha);
  }

  void _paintLines(
      Canvas canvas, double left, double top, double gridSize, int n, double cell,
      [double groupAlpha = 1.0]) {
    final p = Paint()
      ..color = fill.withOpacity(lineAlpha * groupAlpha)
      ..strokeWidth = 1;
    for (var i = 0; i <= n; i++) {
      canvas.drawLine(Offset(left + i * cell, top),
          Offset(left + i * cell, top + gridSize), p);
      canvas.drawLine(Offset(left, top + i * cell),
          Offset(left + gridSize, top + i * cell), p);
    }
  }

  double _celebratePulse(double progress) {
    final x = (progress - 0.55) / 0.15; // 0..1
    return (x < 0.5 ? x * 2 : (1 - x) * 2).clamp(0.0, 1.0);
  }

  List<bool> _pattern(_GridSpec g, int cycleIndex) {
    // Deterministic pseudo-random pattern, ~45-60% density, always non-empty.
    var seed = (g.n * 2654435761) ^ (cycleIndex * 40503) ^ (g.cycle * 97);
    final total = g.n * g.n;
    final out = List<bool>.filled(total, false);
    var count = 0;
    for (var i = 0; i < total; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final on = (seed >> 16) % 100 < 52;
      out[i] = on;
      if (on) count++;
    }
    if (count == 0) out[0] = true;
    return out;
  }

  @override
  bool shouldRepaint(covariant _PuzzlePainter old) =>
      old.clock != clock ||
      old.fill != fill ||
      old.baseAlpha != baseAlpha ||
      old.animate != animate;
}
