import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/data/level_catalog.dart';
import '../../game/engine/auto_cross_engine.dart';
import '../../game/models/board_theme.dart';
import '../../game/models/cell_state.dart';
import '../../game/models/game_state.dart';
import '../../game/models/puzzle.dart';
import 'board_metrics.dart';
import 'board_painter.dart';
import 'game_controller.dart';
import 'widgets/picture_preview.dart';
import '../../shared/widgets/pressable_scale.dart';
import 'widgets/tutorial_overlay.dart';

class PuzzleScreen extends ConsumerStatefulWidget {
  final int levelId;
  const PuzzleScreen({super.key, required this.levelId});

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen>
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
      vsync: this, duration: const Duration(milliseconds: 900));
  Set<({int r, int c})> _popCells = {};
  Set<int> _glowingRows = {};
  Set<int> _glowingCols = {};
  bool _entranceStarted = false;

  bool get _motion =>
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  GameController get _controller =>
      ref.read(gameControllerProvider(widget.levelId).notifier);

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

  /// Detects newly-filled cells (for the pop animation), mistakes (for the
  /// shake), and newly-completed rows/columns (for the line glow) between
  /// consecutive game states.
  void _onStateChange(GameState? prev, GameState next) {
    if (prev == null || !_motion) return;
    if (next.mistakes > prev.mistakes) {
      _shake.forward(from: 0);
    }
    final added = <({int r, int c})>{};
    for (var r = 0; r < next.puzzle.rows; r++) {
      for (var c = 0; c < next.puzzle.cols; c++) {
        final now = next.playerGrid[r][c];
        final was = prev.playerGrid[r][c];
        if (now != was && now != CellState.unknown) {
          added.add((r: r, c: c));
        }
      }
    }
    if (added.isNotEmpty) {
      _popCells = added;
      _pop.forward(from: 0);

      final rows = <int>{};
      final cols = <int>{};
      for (final cell in added) {
        if (AutoCrossEngine.isRowSolved(next.puzzle, next.playerGrid, cell.r) &&
            !AutoCrossEngine.isRowSolved(prev.puzzle, prev.playerGrid, cell.r)) {
          rows.add(cell.r);
        }
        if (AutoCrossEngine.isColumnSolved(
                next.puzzle, next.playerGrid, cell.c) &&
            !AutoCrossEngine.isColumnSolved(
                prev.puzzle, prev.playerGrid, cell.c)) {
          cols.add(cell.c);
        }
      }
      if (rows.isNotEmpty || cols.isNotEmpty) {
        _glowingRows = rows;
        _glowingCols = cols;
        _lineGlow.forward(from: 0);
      }
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

  void _onTap(Offset local) {
    final cell = _metrics?.cellAt(local.dx, local.dy);
    if (cell != null) _controller.act(cell.r, cell.c);
  }

  void _onPan(Offset local, GameTool tool) {
    final cell = _metrics?.cellAt(local.dx, local.dy);
    if (cell == null) return;
    if (_lastPainted != null &&
        _lastPainted!.r == cell.r &&
        _lastPainted!.c == cell.c) {
      return;
    }
    _lastPainted = cell;
    if (tool == GameTool.fill) {
      _controller.paintFill(cell.r, cell.c);
    } else {
      _controller.paintCross(cell.r, cell.c);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameControllerProvider(widget.levelId), _onStateChange);
    final gameState = ref.watch(gameControllerProvider(widget.levelId));
    final puzzle = gameState.puzzle;
    final profile = ref.watch(profileControllerProvider);
    final fillColor = BoardThemes.byId(profile.selectedTheme).fillColor;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(state: gameState),
                Expanded(child: _buildBoard(gameState, puzzle, fillColor)),
                _Controls(
                  state: gameState,
                  hintsAvailable: profile.hints,
                  onUndo: _controller.undo,
                  onHint: _onHint,
                  onToggleTool: (t) => _controller.setTool(t),
                ),
              ],
            ),
            if (widget.levelId == 1 &&
                !profile.tutorialDone &&
                !gameState.isComplete &&
                !gameState.isGameOver)
              PuzzleTutorialOverlay(
                onFinish: () => ref
                    .read(profileControllerProvider.notifier)
                    .completeTutorial(),
              ),
            if (gameState.isComplete)
              _CompleteOverlay(levelId: widget.levelId, state: gameState),
            if (gameState.isGameOver)
              _GameOverOverlay(levelId: widget.levelId, controller: _controller),
          ],
        ),
      ),
    );
  }

  Future<void> _onHint() async {
    final ok = _controller.useHint();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hints left. Get more in the Store.')),
      );
    }
  }

  Widget _buildBoard(GameState state, Puzzle puzzle, Color fillColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const pad = 12.0;
        final availW = constraints.maxWidth - pad * 2;
        final availH = constraints.maxHeight - pad * 2;
        final metrics = BoardMetrics.compute(puzzle, availW, availH);
        _metrics = metrics;

        final board = SizedBox(
          width: metrics.boardWidth,
          height: metrics.boardHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _onTap(d.localPosition),
            onPanStart: (d) {
              _lastPainted = null;
              _onPan(d.localPosition, state.tool);
            },
            onPanUpdate: (d) => _onPan(d.localPosition, state.tool),
            onPanEnd: (_) => _lastPainted = null,
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([_pop, _shake, _entrance, _lineGlow]),
              builder: (context, _) {
                // Subtle horizontal shake on a wrong tap; a parent transform
                // does not affect the gesture's local coordinates, so touch
                // mapping stays exact.
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
                      painter: BoardPainter(
                        puzzle: puzzle,
                        grid: state.playerGrid,
                        m: metrics,
                        highlight: state.highlight,
                        fillColor: fillColor,
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
}

class _TopBar extends StatelessWidget {
  final GameState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.puzzle.category == 'Daily'
                    ? 'Daily Challenge'
                    : 'Level ${state.puzzle.id}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Text(
                '${state.puzzle.difficulty.label} · ${state.puzzle.category}',
                style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          _Timer(seconds: state.elapsedSeconds),
          const SizedBox(width: 12),
          _Hearts(hearts: state.hearts, max: state.maxHearts),
        ],
      ),
    );
  }
}

class _Timer extends StatelessWidget {
  final int seconds;
  const _Timer({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 16, color: AppTheme.inkSoft),
        const SizedBox(width: 4),
        Text('$m:$s',
            style: TextStyle(
                color: AppTheme.inkSoft, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Hearts extends StatelessWidget {
  final int hearts;
  final int max;
  const _Hearts({required this.hearts, required this.max});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < max; i++)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              i < hearts ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(i < hearts),
              color: AppTheme.heart,
              size: 22,
            ),
          ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  final GameState state;
  final int hintsAvailable;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final ValueChanged<GameTool> onToggleTool;

  const _Controls({
    required this.state,
    required this.hintsAvailable,
    required this.onUndo,
    required this.onHint,
    required this.onToggleTool,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ControlButton(
            icon: Icons.undo,
            label: 'Undo',
            enabled: state.canUndo,
            onTap: onUndo,
          ),
          const SizedBox(width: 8),
          _ControlButton(
            icon: Icons.lightbulb_outline,
            label: '$hintsAvailable',
            enabled: true,
            onTap: onHint,
          ),
          const SizedBox(width: 8),
          Flexible(child: _ToolToggle(tool: state.tool, onToggle: onToggleTool)),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: PressableScale(
        enabled: enabled,
        child: Material(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: AppTheme.ink),
                  const SizedBox(width: 5),
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: AppTheme.ink)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolToggle extends StatelessWidget {
  final GameTool tool;
  final ValueChanged<GameTool> onToggle;
  const _ToolToggle({required this.tool, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    Widget seg(GameTool t, IconData icon, String label) {
      final selected = tool == t;
      return PressableScale(
        child: GestureDetector(
          onTap: () => onToggle(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 20,
                    color: selected ? Colors.white : AppTheme.inkSoft),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppTheme.inkSoft,
                    )),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(GameTool.fill, Icons.crop_square, 'Fill'),
          seg(GameTool.cross, Icons.close, 'X'),
        ],
      ),
    );
  }
}

class _CompleteOverlay extends ConsumerStatefulWidget {
  final int levelId;
  final GameState state;
  const _CompleteOverlay({required this.levelId, required this.state});

  @override
  ConsumerState<_CompleteOverlay> createState() => _CompleteOverlayState();
}

class _CompleteOverlayState extends ConsumerState<_CompleteOverlay>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _reveal;
  late final AnimationController _cardEntrance;
  final GlobalKey _shareKey = GlobalKey();
  bool _sharing = false;
  bool _entranceStarted = false;

  bool get _motion =>
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardEntrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _reveal.forward();
    _confetti.play();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;
    // Smooth entrance, then the completed-grid wave, then celebrate.
    if (_motion) {
      _cardEntrance.forward();
    } else {
      _cardEntrance.value = 1.0;
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _reveal.dispose();
    _cardEntrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final levelId = widget.levelId;
    final hasNext =
        levelId < LevelCatalog.totalLevels && state.puzzle.category != 'Daily';

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _cardEntrance,
          builder: (context, child) {
            final t = Curves.easeOutCubic.transform(
              _cardEntrance.value.clamp(0.0, 1.0),
            );
            return Opacity(
              opacity: t,
              child: Transform.scale(scale: 0.88 + 0.12 * t, child: child),
            );
          },
          child: _OverlayScaffold(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Captured for sharing (picture + title).
              RepaintBoundary(
                key: _shareKey,
                child: Container(
                  color: AppTheme.surface,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _reveal,
                        builder: (context, _) => Transform.scale(
                          scale: 0.6 + 0.4 * Curves.easeOutBack
                              .transform(_reveal.value.clamp(0.0, 1.0)),
                          child: PicturePreview(
                            puzzle: state.puzzle,
                            size: 140,
                            revealProgress: _reveal.value,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(state.puzzle.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Puzzle Complete!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text(
                  state.puzzle.category == 'Daily'
                      ? 'Daily Challenge'
                      : 'Level $levelId',
                  style: TextStyle(color: AppTheme.inkSoft)),
              const SizedBox(height: 14),
              _AnimatedStars(stars: state.stars),
              const SizedBox(height: 12),
              _statsRow(state),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: state.earnedCoins),
                    duration: Duration(
                        milliseconds: _motion ? 900 : 0),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Text('+$v coins',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              if (state.earnedChestBonus > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2, color: AppTheme.accent),
                    const SizedBox(width: 6),
                    Text('Milestone chest: +${state.earnedChestBonus}!',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.accent)),
                  ],
                ),
              ],
              if (state.stars < 3) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: PressableScale(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent),
                      onPressed: () => _watchAdForStars(context, ref, levelId),
                      icon: const Icon(Icons.play_circle_outline, size: 18),
                      label: const Text('Watch Ad → 3★'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PressableScale(
                      child: OutlinedButton.icon(
                        onPressed: _sharing ? null : _share,
                        icon: const Icon(Icons.ios_share, size: 18),
                        label: const Text('Share'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PressableScale(
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(gameControllerProvider(levelId).notifier)
                            .restart(),
                        child: const Text('Replay'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PressableScale(
                      child: OutlinedButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Home'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PressableScale(
                      child: FilledButton(
                        onPressed: hasNext
                            ? () =>
                                context.pushReplacement('/game/${levelId + 1}')
                            : () => context.go('/'),
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
        // Confetti from the top center.
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
            colors: const [
              AppTheme.primary,
              AppTheme.accent,
              AppTheme.success,
              Colors.amber,
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _watchAdForStars(
      BuildContext context, WidgetRef ref, int levelId) async {
    final granted = await ref.read(adManagerProvider).showRewarded();
    if (!context.mounted) return;
    if (granted) {
      ref.read(gameControllerProvider(levelId).notifier).upgradeToThreeStars();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ad available right now.')),
      );
    }
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pixelcross_${widget.state.puzzle.id}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'I solved "${widget.state.puzzle.title}" in Pixel Cross! Can you?',
      );
    } catch (_) {
      // Sharing is best-effort; ignore failures.
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Widget _statsRow(GameState s) {
    final m = (s.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (s.elapsedSeconds % 60).toString().padLeft(2, '0');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat('Time', '$m:$sec'),
        _stat('Mistakes', '${s.mistakes}'),
        _stat('Hints', '${s.hintsUsed}'),
      ],
    );
  }

  Widget _stat(String label, String value) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label,
              style: TextStyle(color: AppTheme.inkSoft, fontSize: 12)),
        ],
      );
}

/// Stars that pop in one after another when the puzzle completes.
class _AnimatedStars extends StatelessWidget {
  final int stars;
  const _AnimatedStars({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + i * 220),
            curve: Curves.elasticOut,
            builder: (context, v, child) =>
                Transform.scale(scale: v.clamp(0.0, 1.4), child: child),
            child: Icon(
              i < stars ? Icons.star : Icons.star_border,
              color: AppTheme.accent,
              size: 42,
            ),
          ),
      ],
    );
  }
}

class _GameOverOverlay extends ConsumerWidget {
  final int levelId;
  final GameController controller;
  const _GameOverOverlay({required this.levelId, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _OverlayScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.heart_broken, color: AppTheme.heart, size: 56),
          const SizedBox(height: 12),
          const Text('Out of Hearts',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Restore hearts to keep going, or restart the level.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.inkSoft)),
          const SizedBox(height: 20),
          PressableScale(
            child: FilledButton.icon(
              onPressed: () => _restoreWithAd(context, ref),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Watch Ad · Restore Hearts'),
            ),
          ),
          const SizedBox(height: 8),
          PressableScale(
            child: OutlinedButton.icon(
              onPressed: () => _restoreWithCoins(context, ref),
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
                    onPressed: () => context.go('/'),
                    child: const Text('Home'),
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

  Future<void> _restoreWithAd(BuildContext context, WidgetRef ref) async {
    final granted = await ref.read(adManagerProvider).showRewarded();
    if (granted) {
      controller.restoreHearts();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ads are not available right now.')),
      );
    }
  }

  void _restoreWithCoins(BuildContext context, WidgetRef ref) {
    final ok = ref.read(profileControllerProvider.notifier).spendCoins(20);
    if (ok) {
      controller.restoreHearts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins.')),
      );
    }
  }
}

class _OverlayScaffold extends StatelessWidget {
  final Widget child;
  const _OverlayScaffold({required this.child});

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
