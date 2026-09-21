import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/audio/audio_service.dart';
import '../../game/data/color_puzzle_catalog.dart';
import '../../game/engine/scoring_engine.dart';
import '../../game/models/color_puzzle.dart';
import '../../game/models/game_state.dart' show GameTool;

/// State for a colored nonogram. Cells hold: -1 unknown, 0 empty (X),
/// 1..N a filled colour index.
class ColorGameState {
  final ColorPuzzle puzzle;
  final List<List<int>> grid;
  final int maxHearts;
  final int hearts;
  final int mistakes;
  final int hintsUsed;
  final int elapsedSeconds;
  final int activeColor; // 1..N
  final GameTool tool;
  final bool isComplete;
  final int stars;
  final int earnedCoins;
  final List<List<List<int>>> history;
  final ({int r, int c})? highlight;

  const ColorGameState({
    required this.puzzle,
    required this.grid,
    required this.maxHearts,
    required this.hearts,
    required this.mistakes,
    required this.hintsUsed,
    required this.elapsedSeconds,
    required this.activeColor,
    required this.tool,
    required this.isComplete,
    required this.stars,
    required this.earnedCoins,
    required this.history,
    required this.highlight,
  });

  factory ColorGameState.initial(ColorPuzzle p) => ColorGameState(
        puzzle: p,
        grid: [
          for (var r = 0; r < p.rows; r++) List<int>.filled(p.cols, -1),
        ],
        maxHearts: 3,
        hearts: 3,
        mistakes: 0,
        hintsUsed: 0,
        elapsedSeconds: 0,
        activeColor: 1,
        tool: GameTool.fill,
        isComplete: false,
        stars: 0,
        earnedCoins: 0,
        history: const [],
        highlight: null,
      );

  bool get isGameOver => hearts <= 0 && !isComplete;
  bool get canUndo => history.isNotEmpty;

  ColorGameState copyWith({
    List<List<int>>? grid,
    int? hearts,
    int? mistakes,
    int? hintsUsed,
    int? elapsedSeconds,
    int? activeColor,
    GameTool? tool,
    bool? isComplete,
    int? stars,
    int? earnedCoins,
    List<List<List<int>>>? history,
    ({int r, int c})? highlight,
    bool clearHighlight = false,
  }) {
    return ColorGameState(
      puzzle: puzzle,
      grid: grid ?? this.grid,
      maxHearts: maxHearts,
      hearts: hearts ?? this.hearts,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      activeColor: activeColor ?? this.activeColor,
      tool: tool ?? this.tool,
      isComplete: isComplete ?? this.isComplete,
      stars: stars ?? this.stars,
      earnedCoins: earnedCoins ?? this.earnedCoins,
      history: history ?? this.history,
      highlight: clearHighlight ? null : (highlight ?? this.highlight),
    );
  }
}

class ColorGameController extends StateNotifier<ColorGameState> {
  final Ref _ref;
  final int _index;
  Timer? _timer;
  bool _recorded = false;

  ColorGameController(this._ref, this._index, ColorPuzzle puzzle)
      : super(ColorGameState.initial(puzzle)) {
    _startTimer();
  }

  AudioService get _audio => _ref.read(audioServiceProvider);
  bool get _soundOn => _ref.read(profileControllerProvider).soundOn;
  bool get _hapticsOn => _ref.read(profileControllerProvider).hapticsOn;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isComplete || state.isGameOver) return;
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void pauseTimer() => _timer?.cancel();
  void resumeTimer() {
    if (state.isComplete || state.isGameOver) return;
    _startTimer();
  }

  void setActiveColor(int c) => state = state.copyWith(activeColor: c);
  void setTool(GameTool t) => state = state.copyWith(tool: t);

  void act(int r, int c) {
    if (state.isComplete || state.isGameOver) return;
    if (state.tool == GameTool.fill) {
      _fill(r, c);
    } else {
      _cross(r, c);
    }
  }

  void paint(int r, int c) {
    if (state.isComplete || state.isGameOver) return;
    if (state.tool == GameTool.fill) {
      if (state.grid[r][c] == state.activeColor) return;
      _fill(r, c, allowErase: false);
    } else {
      if (state.grid[r][c] != -1) return;
      _cross(r, c, allowToggle: false);
    }
  }

  void _fill(int r, int c, {bool allowErase = true}) {
    final current = state.grid[r][c];
    final active = state.activeColor;

    if (current == active) {
      if (!allowErase) return;
      _push();
      final grid = _copy(state.grid);
      grid[r][c] = -1;
      state = state.copyWith(grid: grid, clearHighlight: true);
      return;
    }

    if (state.puzzle.colorAt(r, c) == active) {
      _push();
      final grid = _copy(state.grid);
      grid[r][c] = active;
      state = state.copyWith(grid: grid, clearHighlight: true);
      _ref.read(hapticsServiceProvider).cellSelect(_hapticsOn);
      _audio.play(GameSound.correct, soundEnabled: _soundOn);
      _checkComplete();
    } else {
      state = state.copyWith(
        hearts: state.hearts - 1,
        mistakes: state.mistakes + 1,
        clearHighlight: true,
      );
      _ref.read(hapticsServiceProvider).wrong(_hapticsOn);
      _audio.play(GameSound.wrong, soundEnabled: _soundOn);
    }
  }

  void _cross(int r, int c, {bool allowToggle = true}) {
    final current = state.grid[r][c];
    if (current > 0) return; // don't cross a filled cell
    _push();
    final grid = _copy(state.grid);
    if (current == 0) {
      if (!allowToggle) return;
      grid[r][c] = -1;
    } else {
      grid[r][c] = 0;
    }
    state = state.copyWith(grid: grid, clearHighlight: true);
    _ref.read(hapticsServiceProvider).lightTap(_hapticsOn);
    _audio.play(GameSound.cross, soundEnabled: _soundOn);
  }

  bool useHint() {
    if (state.isComplete || state.isGameOver) return true;
    final profile = _ref.read(profileControllerProvider.notifier);
    if (!profile.consumeHint()) return false;

    for (var r = 0; r < state.puzzle.rows; r++) {
      for (var c = 0; c < state.puzzle.cols; c++) {
        final want = state.puzzle.colorAt(r, c);
        if (want > 0 && state.grid[r][c] != want) {
          _push();
          final grid = _copy(state.grid);
          grid[r][c] = want;
          state = state.copyWith(
            grid: grid,
            hintsUsed: state.hintsUsed + 1,
            activeColor: want,
            highlight: (r: r, c: c),
          );
          _audio.play(GameSound.hint, soundEnabled: _soundOn);
          _checkComplete();
          return true;
        }
      }
    }
    profile.addHints(1); // nothing to reveal; refund
    return true;
  }

  void undo() {
    if (state.history.isEmpty) return;
    final history = List<List<List<int>>>.of(state.history);
    final prev = history.removeLast();
    state = state.copyWith(
      grid: _copy(prev),
      history: history,
      clearHighlight: true,
    );
  }

  void restart() {
    _recorded = false;
    state = ColorGameState.initial(state.puzzle);
    _startTimer();
  }

  void restoreHearts() {
    state = state.copyWith(hearts: state.maxHearts);
    resumeTimer();
  }

  void _push() {
    final history = List<List<List<int>>>.of(state.history)
      ..add(_copy(state.grid));
    if (history.length > 200) history.removeAt(0);
    state = state.copyWith(history: history);
  }

  void _checkComplete() {
    for (var r = 0; r < state.puzzle.rows; r++) {
      for (var c = 0; c < state.puzzle.cols; c++) {
        final want = state.puzzle.colorAt(r, c);
        if (want > 0 && state.grid[r][c] != want) return;
      }
    }
    _timer?.cancel();
    final stars = ScoringEngine.starsBySize(
      rows: state.puzzle.rows,
      cols: state.puzzle.cols,
      mistakes: state.mistakes,
      hintsUsed: state.hintsUsed,
    );
    const coins = 25;
    state = state.copyWith(isComplete: true, stars: stars, earnedCoins: coins);
    _ref.read(hapticsServiceProvider).complete(_hapticsOn);
    _audio.play(GameSound.complete, soundEnabled: _soundOn);
    if (!_recorded) {
      _recorded = true;
      _ref
          .read(profileControllerProvider.notifier)
          .markColorComplete(_index, coinReward: coins);
    }
  }

  static List<List<int>> _copy(List<List<int>> g) =>
      [for (final row in g) List<int>.of(row)];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final colorGameControllerProvider = StateNotifierProvider.autoDispose
    .family<ColorGameController, ColorGameState, int>((ref, index) {
  return ColorGameController(
      ref, index, ColorPuzzleCatalog.puzzleAt(index));
});
