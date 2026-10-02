import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/data/color_puzzle_catalog.dart';
import '../../game/models/color_puzzle.dart';
import '../../game/models/game_state.dart' show GameTool;
import '../../shared/widgets/pop_in.dart';
import '../../shared/widgets/pressable_scale.dart';
import '../puzzle/board_metrics.dart';
import 'color_board_painter.dart';
import 'color_game_controller.dart';

class ColorPuzzleScreen extends ConsumerStatefulWidget {
  final int index;
  const ColorPuzzleScreen({super.key, required this.index});

  @override
  ConsumerState<ColorPuzzleScreen> createState() => _ColorPuzzleScreenState();
}

class _ColorPuzzleScreenState extends ConsumerState<ColorPuzzleScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  BoardMetrics? _metrics;
  ({int r, int c})? _lastPainted;

  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 160));
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  late final AnimationController _entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 560));
  late final AnimationController _lineGlow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  Set<({int r, int c})> _popCells = {};
  Set<int> _glowingRows = {};
  Set<int> _glowingCols = {};
  bool _entranceStarted = false;

  bool get _motion =>
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  ColorGameController get _controller =>
      ref.read(colorGameControllerProvider(widget.index).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;
    if (_motion) {
      _entrance.forward();
    } else {
      _entrance.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _shake.dispose();
    _entrance.dispose();
    _lineGlow.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Purely visual: whether row [r] currently matches the picture exactly.
  static bool _rowDone(ColorPuzzle p, List<List<int>> g, int r) {
    for (var c = 0; c < p.cols; c++) {
      final want = p.colorAt(r, c);
      if (want > 0 ? g[r][c] != want : g[r][c] > 0) return false;
    }
    return true;
  }

  static bool _colDone(ColorPuzzle p, List<List<int>> g, int c) {
    for (var r = 0; r < p.rows; r++) {
      final want = p.colorAt(r, c);
      if (want > 0 ? g[r][c] != want : g[r][c] > 0) return false;
    }
    return true;
  }

  /// Diffs consecutive states to drive the pop, shake and line-glow effects.
  void _onStateChange(ColorGameState? prev, ColorGameState next) {
    if (prev == null || !_motion) return;
    if (next.mistakes > prev.mistakes) _shake.forward(from: 0);
    final added = <({int r, int c})>{};
    for (var r = 0; r < next.puzzle.rows; r++) {
      for (var c = 0; c < next.puzzle.cols; c++) {
        final now = next.grid[r][c];
        if (now != prev.grid[r][c] && now >= 0) added.add((r: r, c: c));
      }
    }
    if (added.isEmpty) return;
    _popCells = added;
    _pop.forward(from: 0);

    final p = next.puzzle;
    final rows = <int>{}, cols = <int>{};
    for (final cell in added) {
      if (_rowDone(p, next.grid, cell.r) && !_rowDone(p, prev.grid, cell.r)) {
        rows.add(cell.r);
      }
      if (_colDone(p, next.grid, cell.c) && !_colDone(p, prev.grid, cell.c)) {
        cols.add(cell.c);
      }
    }
    if (rows.isNotEmpty || cols.isNotEmpty) {
      _glowingRows = rows;
      _glowingCols = cols;
      _lineGlow.forward(from: 0);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.resumeTimer();
    } else {
      _controller.pauseTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(colorGameControllerProvider(widget.index), _onStateChange);
    final state = ref.watch(colorGameControllerProvider(widget.index));
    final puzzle = state.puzzle;
    final hints = ref.watch(profileControllerProvider).hints;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(
                  title: puzzle.title,
                  category: puzzle.category,
                  hearts: state.hearts,
                  maxHearts: state.maxHearts,
                  elapsed: state.elapsedSeconds,
                ),
                Expanded(child: _buildBoard(state)),
                _Controls(
                  puzzle: puzzle,
                  activeColor: state.activeColor,
                  tool: state.tool,
                  hints: hints,
                  canUndo: state.canUndo,
                  onColor: (c) {
                    _controller.setActiveColor(c);
                    _controller.setTool(GameTool.fill);
                  },
                  onCross: () => _controller.setTool(GameTool.cross),
                  onUndo: _controller.undo,
                  onHint: () {
                    if (!_controller.useHint()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('No hints left. Get more in the Store.')),
                      );
                    }
                  },
                ),
              ],
            ),
            if (state.isComplete)
              _CompleteOverlay(index: widget.index, state: state),
            if (state.isGameOver)
              _GameOverOverlay(controller: _controller),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(ColorGameState state) {
    final puzzle = state.puzzle;
    final maxRow = puzzle.rowClues
        .map((c) => c.length)
        .fold<int>(1, (a, b) => a > b ? a : b);
    final maxCol = puzzle.columnClues
        .map((c) => c.length)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        const pad = 12.0;
        final metrics = BoardMetrics.computeFor(
          rows: puzzle.rows,
          cols: puzzle.cols,
          maxRowClue: maxRow,
          maxColClue: maxCol,
          availableWidth: constraints.maxWidth - pad * 2,
          availableHeight: constraints.maxHeight - pad * 2,
        );
        _metrics = metrics;

        final board = SizedBox(
          width: metrics.boardWidth,
          height: metrics.boardHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final cell = metrics.cellAt(d.localPosition.dx, d.localPosition.dy);
              if (cell != null) _controller.act(cell.r, cell.c);
            },
            onPanStart: (d) {
              _lastPainted = null;
              _paint(d.localPosition);
            },
            onPanUpdate: (d) => _paint(d.localPosition),
            onPanEnd: (_) => _lastPainted = null,
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([_pop, _shake, _entrance, _lineGlow]),
              builder: (context, _) {
                // A parent transform doesn't affect the gesture's local
                // coordinates, so touch mapping stays exact while shaking.
                final dx = _shake.isAnimating
                    ? (1 - _shake.value) *
                        6 *
                        math.sin(_shake.value * math.pi * 5)
                    : 0.0;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: Opacity(
                    opacity: _entrance.value.clamp(0.0, 1.0),
                    child: CustomPaint(
                      painter: ColorBoardPainter(
                        puzzle: puzzle,
                        grid: state.grid,
                        m: metrics,
                        highlight: state.highlight,
                        popCells: _pop.isAnimating ? _popCells : const {},
                        popValue: _pop.value,
                        glowingRows:
                            _lineGlow.isAnimating ? _glowingRows : const {},
                        glowingCols:
                            _lineGlow.isAnimating ? _glowingCols : const {},
                        lineGlowValue: _lineGlow.value,
                        entrance: _entrance.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        final content = metrics.needsZoom
            ? InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(80),
                child: board,
              )
            : Center(child: board);
        return Padding(padding: const EdgeInsets.all(pad), child: content);
      },
    );
  }

  void _paint(Offset local) {
    final cell = _metrics?.cellAt(local.dx, local.dy);
    if (cell == null) return;
    if (_lastPainted?.r == cell.r && _lastPainted?.c == cell.c) return;
    _lastPainted = cell;
    _controller.paint(cell.r, cell.c);
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final String category;
  final int hearts;
  final int maxHearts;
  final int elapsed;
  const _TopBar({
    required this.title,
    required this.category,
    required this.hearts,
    required this.maxHearts,
    required this.elapsed,
  });

  @override
  Widget build(BuildContext context) {
    final m = (elapsed ~/ 60).toString().padLeft(2, '0');
    final s = (elapsed % 60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              Text('Color · $category',
                  style: TextStyle(color: AppTheme.inkSoft, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Text('$m:$s',
              style: TextStyle(
                  color: AppTheme.inkSoft, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          for (var i = 0; i < maxHearts; i++)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(i < hearts ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(i < hearts),
                  color: AppTheme.heart,
                  size: 22),
            ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final ColorPuzzle puzzle;
  final int activeColor;
  final GameTool tool;
  final int hints;
  final bool canUndo;
  final ValueChanged<int> onColor;
  final VoidCallback onCross;
  final VoidCallback onUndo;
  final VoidCallback onHint;

  const _Controls({
    required this.puzzle,
    required this.activeColor,
    required this.tool,
    required this.hints,
    required this.canUndo,
    required this.onColor,
    required this.onCross,
    required this.onUndo,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= puzzle.colorCount; i++)
                  _Swatch(
                    color: puzzle.palette[i],
                    selected: tool == GameTool.fill && activeColor == i,
                    onTap: () => onColor(i),
                  ),
                const SizedBox(width: 8),
                _ToolButton(
                  icon: Icons.close,
                  selected: tool == GameTool.cross,
                  onTap: onCross,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _flatButton(Icons.undo, 'Undo', canUndo ? onUndo : null),
              const SizedBox(width: 10),
              _flatButton(Icons.lightbulb_outline, '$hints', onHint),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flatButton(IconData icon, String label, VoidCallback? onTap) {
    return Expanded(
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: PressableScale(
          enabled: onTap != null,
          child: Material(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: AppTheme.ink),
                    const SizedBox(width: 6),
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _Swatch(
      {required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleDown: 0.88,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          width: selected ? 48 : 40,
          height: selected ? 48 : 40,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppTheme.ink : AppTheme.line,
              width: selected ? 3 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: selected
              ? const PopIn(
                  duration: Duration(milliseconds: 420),
                  child: Icon(Icons.check, color: Colors.white, size: 22),
                )
              : null,
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ToolButton(
      {required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleDown: 0.88,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.card,
            shape: BoxShape.circle,
            border:
                Border.all(color: selected ? AppTheme.primary : AppTheme.line),
          ),
          child: Icon(icon,
              color: selected ? Colors.white : AppTheme.inkSoft, size: 22),
        ),
      ),
    );
  }
}

class _ColorPicturePainter extends CustomPainter {
  final ColorPuzzle puzzle;

  /// 0..1 fraction of cells drawn, revealed as a diagonal wave.
  final double progress;
  _ColorPicturePainter(this.puzzle, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final s = (size.width / puzzle.cols) < (size.height / puzzle.rows)
        ? size.width / puzzle.cols
        : size.height / puzzle.rows;
    final offX = (size.width - s * puzzle.cols) / 2;
    final offY = (size.height - s * puzzle.rows) / 2;
    final cells = <({int r, int c, int v})>[];
    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        final v = puzzle.colorAt(r, c);
        if (v > 0) cells.add((r: r, c: c, v: v));
      }
    }
    cells.sort((a, b) => (a.r + a.c).compareTo(b.r + b.c));
    final toDraw = (cells.length * progress).ceil();
    for (var i = 0; i < toDraw && i < cells.length; i++) {
      final cell = cells[i];
      canvas.drawRect(
        Rect.fromLTWH(offX + cell.c * s, offY + cell.r * s, s + 0.5, s + 0.5),
        Paint()..color = puzzle.palette[cell.v],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ColorPicturePainter old) =>
      old.puzzle.id != puzzle.id || old.progress != progress;
}

class _CompleteOverlay extends ConsumerStatefulWidget {
  final int index;
  final ColorGameState state;
  const _CompleteOverlay({required this.index, required this.state});

  @override
  ConsumerState<_CompleteOverlay> createState() => _CompleteOverlayState();
}

class _CompleteOverlayState extends ConsumerState<_CompleteOverlay>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));
  late final AnimationController _reveal = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _card = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
  bool _started = false;

  bool get _motion =>
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_motion) {
      _card.forward();
      _reveal.forward();
      _confetti.play();
    } else {
      _card.value = 1;
      _reveal.value = 1;
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _reveal.dispose();
    _card.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final index = widget.index;
    final hasNext = index + 1 < ColorPuzzleCatalog.count;
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _card,
          builder: (context, child) {
            final t = Curves.easeOutCubic.transform(_card.value);
            return Opacity(
              opacity: t,
              child: Transform.scale(scale: 0.88 + 0.12 * t, child: child),
            );
          },
          child: _Scrim(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _reveal,
                  builder: (context, _) => Transform.scale(
                    scale: 0.6 +
                        0.4 * Curves.easeOutBack.transform(_reveal.value),
                    child: Container(
                      width: 150,
                      height: 150,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.boardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: CustomPaint(
                          painter: _ColorPicturePainter(
                              state.puzzle, _reveal.value)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Puzzle Complete!',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                Text(state.puzzle.title,
                    style: TextStyle(color: AppTheme.inkSoft)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var s = 0; s < 3; s++)
                      PopIn(
                        delay: Duration(milliseconds: 500 + s * 220),
                        duration: const Duration(milliseconds: 700),
                        child: Icon(
                            s < state.stars ? Icons.star : Icons.star_border,
                            color: AppTheme.accent,
                            size: 40),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: AppTheme.accent),
                    const SizedBox(width: 6),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: state.earnedCoins),
                      duration: Duration(milliseconds: _motion ? 900 : 0),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Text('+$v coins',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: PressableScale(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Back'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PressableScale(
                        child: OutlinedButton(
                          onPressed: () => ref
                              .read(colorGameControllerProvider(index).notifier)
                              .restart(),
                          child: const Text('Replay'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PressableScale(
                        child: FilledButton(
                          onPressed: hasNext
                              ? () => context
                                  .pushReplacement('/color/${index + 1}')
                              : () => context.pop(),
                          child: Text(hasNext ? 'Next' : 'Done'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirection: math.pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            maxBlastForce: 18,
            minBlastForce: 8,
            gravity: 0.25,
            colors: [
              for (var i = 1; i <= state.puzzle.colorCount; i++)
                state.puzzle.palette[i],
              AppTheme.accent,
            ],
          ),
        ),
      ],
    );
  }
}

class _GameOverOverlay extends ConsumerWidget {
  final ColorGameController controller;
  const _GameOverOverlay({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Scrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.heart_broken, color: AppTheme.heart, size: 56),
          const SizedBox(height: 12),
          const Text('Out of Hearts',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          PressableScale(
            child: OutlinedButton.icon(
              onPressed: () {
                final ok = ref
                    .read(profileControllerProvider.notifier)
                    .spendCoins(20);
                if (ok) {
                  controller.restoreHearts();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not enough coins.')),
                  );
                }
              },
              icon: const Icon(Icons.monetization_on, color: AppTheme.accent),
              label: const Text('Restore for 20 coins'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PressableScale(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PressableScale(
                  child: OutlinedButton(
                    onPressed: controller.restart,
                    child: const Text('Restart'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Scrim extends StatelessWidget {
  final Widget child;
  const _Scrim({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        ),
      ),
    );
  }
}
