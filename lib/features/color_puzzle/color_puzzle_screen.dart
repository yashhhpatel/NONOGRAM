import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/data/color_puzzle_catalog.dart';
import '../../game/models/color_puzzle.dart';
import '../../game/models/game_state.dart' show GameTool;
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
    with WidgetsBindingObserver {
  BoardMetrics? _metrics;
  ({int r, int c})? _lastPainted;

  ColorGameController get _controller =>
      ref.read(colorGameControllerProvider(widget.index).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
            child: CustomPaint(
              painter: ColorBoardPainter(
                puzzle: puzzle,
                grid: state.grid,
                m: metrics,
                highlight: state.highlight,
              ),
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
            Icon(i < hearts ? Icons.favorite : Icons.favorite_border,
                color: AppTheme.heart, size: 22),
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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.card,
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
                        fontWeight: FontWeight.w600, color: AppTheme.ink)),
              ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : null,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.card,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.line),
        ),
        child: Icon(icon,
            color: selected ? Colors.white : AppTheme.inkSoft, size: 22),
      ),
    );
  }
}

class _ColorPicturePainter extends CustomPainter {
  final ColorPuzzle puzzle;
  _ColorPicturePainter(this.puzzle);

  @override
  void paint(Canvas canvas, Size size) {
    final s = (size.width / puzzle.cols) < (size.height / puzzle.rows)
        ? size.width / puzzle.cols
        : size.height / puzzle.rows;
    final offX = (size.width - s * puzzle.cols) / 2;
    final offY = (size.height - s * puzzle.rows) / 2;
    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        final v = puzzle.colorAt(r, c);
        if (v > 0) {
          canvas.drawRect(
            Rect.fromLTWH(offX + c * s, offY + r * s, s + 0.5, s + 0.5),
            Paint()..color = puzzle.palette[v],
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ColorPicturePainter old) =>
      old.puzzle.id != puzzle.id;
}

class _CompleteOverlay extends ConsumerWidget {
  final int index;
  final ColorGameState state;
  const _CompleteOverlay({required this.index, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNext = index + 1 < ColorPuzzleCatalog.count;
    return _Scrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 150,
            height: 150,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.boardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.line),
            ),
            child: CustomPaint(painter: _ColorPicturePainter(state.puzzle)),
          ),
          const SizedBox(height: 14),
          const Text('Puzzle Complete!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(state.puzzle.title, style: TextStyle(color: AppTheme.inkSoft)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var s = 0; s < 3; s++)
                Icon(s < state.stars ? Icons.star : Icons.star_border,
                    color: AppTheme.accent, size: 40),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: AppTheme.accent),
              const SizedBox(width: 6),
              Text('+${state.earnedCoins} coins',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(colorGameControllerProvider(index).notifier)
                      .restart(),
                  child: const Text('Replay'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: hasNext
                      ? () =>
                          context.pushReplacement('/color/${index + 1}')
                      : () => context.pop(),
                  child: Text(hasNext ? 'Next' : 'Done'),
                ),
              ),
            ],
          ),
        ],
      ),
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
          OutlinedButton.icon(
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.restart,
                  child: const Text('Restart'),
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
