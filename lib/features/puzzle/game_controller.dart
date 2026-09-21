import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/storage/storage_service.dart';
import '../../game/data/level_catalog.dart';
import '../../game/data/puzzle_repository.dart';
import '../../game/data/world_catalog.dart';
import '../../game/util/date_key.dart';
import '../../game/engine/auto_cross_engine.dart';
import '../../game/engine/completion_engine.dart';
import '../../game/engine/grid_ops.dart';
import '../../game/engine/hint_engine.dart';
import '../../game/engine/scoring_engine.dart';
import '../../game/models/cell_state.dart';
import '../../game/models/game_state.dart';
import '../../game/models/in_progress_state.dart';
import '../../game/models/puzzle.dart';

/// Drives a single level: applies moves, enforces hearts, runs auto-cross,
/// detects completion, computes rewards and persists the result.
class GameController extends StateNotifier<GameState> {
  final Ref _ref;
  final Puzzle _puzzle;
  // Captured at construction so it stays usable inside dispose(), where reading
  // providers off _ref is not allowed.
  final StorageService _storage;
  Timer? _timer;
  bool _resultRecorded = false;

  GameController(this._ref, this._puzzle)
      : _storage = _ref.read(storageServiceProvider),
        super(GameState.initial(
          _puzzle,
          autoCrossEnabled:
              _ref.read(profileControllerProvider).autoCrossOn,
        )) {
    _restoreSavedProgress();
    _startTimer();
  }

  /// Restores an auto-saved board for this level, if one exists and matches the
  /// current puzzle shape.
  void _restoreSavedProgress() {
    final saved = _storage.loadInProgress(_puzzle.id);
    if (saved == null) return;
    if (saved.grid.length != _puzzle.rows ||
        saved.grid.first.length != _puzzle.cols) {
      return;
    }
    state = state.copyWith(
      playerGrid: saved.toCellGrid(),
      hearts: saved.hearts,
      mistakes: saved.mistakes,
      hintsUsed: saved.hintsUsed,
      elapsedSeconds: saved.elapsedSeconds,
      autoCrossEnabled: saved.autoCross,
      tool: GameTool.values[saved.tool],
    );
  }

  void _persist() {
    if (state.isComplete) return;
    _storage.saveInProgress(InProgressState.fromGame(_puzzle.id, state));
  }

  void _clearSaved() {
    _storage.clearInProgress(_puzzle.id);
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

  void pauseTimer() {
    _timer?.cancel();
    _persist();
  }

  void resumeTimer() {
    if (state.isComplete || state.isGameOver) return;
    _startTimer();
  }

  void setTool(GameTool tool) {
    state = state.copyWith(tool: tool);
    _persist();
  }

  void setAutoCross(bool enabled) {
    state = state.copyWith(autoCrossEnabled: enabled);
    if (enabled) {
      final crossed = AutoCrossEngine.applyAutoCross(_puzzle, state.playerGrid);
      state = state.copyWith(playerGrid: crossed);
      _checkCompletion();
    }
    _persist();
  }

  /// Handles a tap/drag on a cell using the current tool.
  void act(int r, int c) {
    if (state.isComplete || state.isGameOver) return;
    if (state.tool == GameTool.fill) {
      _fill(r, c);
    } else {
      _cross(r, c);
    }
  }

  /// Explicit fill (used by drag-fill), never toggles off.
  void paintFill(int r, int c) {
    if (state.isComplete || state.isGameOver) return;
    if (state.playerGrid[r][c] == CellState.filled) return;
    _fill(r, c, allowErase: false);
  }

  /// Explicit cross (used by drag-cross).
  void paintCross(int r, int c) {
    if (state.isComplete || state.isGameOver) return;
    if (state.playerGrid[r][c] != CellState.unknown) return;
    _cross(r, c, allowToggle: false);
  }

  void _fill(int r, int c, {bool allowErase = true}) {
    final current = state.playerGrid[r][c];

    // Erase a previously filled cell.
    if (current == CellState.filled) {
      if (!allowErase) return;
      _pushHistory();
      final grid = GridOps.copy(state.playerGrid);
      grid[r][c] = CellState.unknown;
      state = state.copyWith(playerGrid: grid, clearHighlight: true);
      _audio.play(GameSound.buttonTap, soundEnabled: _soundOn);
      _persist();
      return;
    }

    if (_puzzle.solutionAt(r, c)) {
      // Correct fill.
      _pushHistory();
      var grid = GridOps.copy(state.playerGrid);
      grid[r][c] = CellState.filled;
      if (state.autoCrossEnabled) {
        grid = AutoCrossEngine.applyAutoCross(_puzzle, grid);
      }
      state = state.copyWith(playerGrid: grid, clearHighlight: true);
      _ref.read(hapticsServiceProvider).cellSelect(_hapticsOn);
      _audio.play(GameSound.correct, soundEnabled: _soundOn);
      _checkCompletion();
      _persist();
    } else {
      // Wrong fill: cost a heart, leave the cell untouched. Not undoable.
      final hearts = state.hearts - 1;
      state = state.copyWith(
        hearts: hearts,
        mistakes: state.mistakes + 1,
        clearHighlight: true,
      );
      _ref.read(hapticsServiceProvider).wrong(_hapticsOn);
      _audio.play(GameSound.wrong, soundEnabled: _soundOn);
      _persist();
    }
  }

  void _cross(int r, int c, {bool allowToggle = true}) {
    final current = state.playerGrid[r][c];
    if (current == CellState.filled) return; // don't cross a filled cell
    _pushHistory();
    final grid = GridOps.copy(state.playerGrid);
    if (current == CellState.empty) {
      if (!allowToggle) return;
      grid[r][c] = CellState.unknown;
    } else {
      grid[r][c] = CellState.empty;
    }
    state = state.copyWith(playerGrid: grid, clearHighlight: true);
    _ref.read(hapticsServiceProvider).lightTap(_hapticsOn);
    _audio.play(GameSound.cross, soundEnabled: _soundOn);
    _persist();
  }

  /// Reveals one correct cell. Consumes an inventory hint (from the profile).
  /// Returns false if the player has no hints left.
  bool useHint() {
    if (state.isComplete || state.isGameOver) return true;
    final profile = _ref.read(profileControllerProvider.notifier);
    if (!profile.consumeHint()) return false;

    final hint = HintEngine.nextHint(_puzzle, state.playerGrid);
    if (hint == null) {
      // Nothing to reveal; refund.
      profile.addHints(1);
      return true;
    }

    _pushHistory();
    var grid = GridOps.copy(state.playerGrid);
    grid[hint.row][hint.col] = hint.state;
    if (state.autoCrossEnabled && hint.state == CellState.filled) {
      grid = AutoCrossEngine.applyAutoCross(_puzzle, grid);
    }
    state = state.copyWith(
      playerGrid: grid,
      hintsUsed: state.hintsUsed + 1,
      highlight: (r: hint.row, c: hint.col),
    );
    _ref.read(hapticsServiceProvider).lightTap(_hapticsOn);
    _audio.play(GameSound.hint, soundEnabled: _soundOn);
    _checkCompletion();
    _persist();
    return true;
  }

  void undo() {
    if (state.history.isEmpty) return;
    final history = List<GameSnapshot>.of(state.history);
    final snap = history.removeLast();
    state = state.copyWith(
      playerGrid: GridOps.copy(snap.grid),
      hintsUsed: snap.hintsUsed,
      history: history,
      clearHighlight: true,
    );
    _persist();
  }

  /// Restores hearts to full (e.g. after a rewarded ad or coin spend).
  void restoreHearts() {
    state = state.copyWith(hearts: state.maxHearts);
    resumeTimer();
  }

  void restart() {
    _resultRecorded = false;
    _clearSaved();
    state = GameState.initial(
      _puzzle,
      autoCrossEnabled: _ref.read(profileControllerProvider).autoCrossOn,
    );
    _startTimer();
  }

  void _pushHistory() {
    final history = List<GameSnapshot>.of(state.history)
      ..add(GameSnapshot(
        grid: GridOps.copy(state.playerGrid),
        hintsUsed: state.hintsUsed,
      ));
    // Cap history to avoid unbounded growth on large boards.
    if (history.length > 200) history.removeAt(0);
    state = state.copyWith(history: history);
  }

  void _checkCompletion() {
    if (!CompletionEngine.isComplete(_puzzle, state.playerGrid)) return;

    _timer?.cancel();

    // Finish any remaining auto-cross so the board reads cleanly.
    final grid = AutoCrossEngine.applyAutoCross(_puzzle, state.playerGrid);

    final stars = ScoringEngine.stars(
      puzzle: _puzzle,
      mistakes: state.mistakes,
      hintsUsed: state.hintsUsed,
      elapsedSeconds: state.elapsedSeconds,
    );
    final baseCoins = ScoringEngine.coins(
      difficulty: _puzzle.difficulty,
      stars: stars,
    );

    // Milestone chest: a one-time bonus the first time a chest level is solved.
    final isCampaign = !PuzzleRepository.isDailyId(_puzzle.id);
    final alreadyDone =
        _ref.read(profileControllerProvider).levels[_puzzle.id]?.completed ??
            false;
    final chestBonus = (isCampaign &&
            WorldCatalog.isChestLevel(_puzzle.id) &&
            !alreadyDone)
        ? WorldCatalog.chestReward(_puzzle.id)
        : 0;
    final coins = baseCoins + chestBonus;

    state = state.copyWith(
      playerGrid: grid,
      isComplete: true,
      stars: stars,
      earnedCoins: baseCoins,
      earnedChestBonus: chestBonus,
    );

    _ref.read(hapticsServiceProvider).complete(_hapticsOn);
    _audio.play(GameSound.complete, soundEnabled: _soundOn);

    // A finished puzzle no longer needs an auto-saved board.
    _clearSaved();

    if (!_resultRecorded) {
      _resultRecorded = true;
      final profile = _ref.read(profileControllerProvider.notifier);
      if (PuzzleRepository.isDailyId(_puzzle.id)) {
        profile.markDailyComplete(DateKey.today(), coinReward: coins);
      } else {
        profile.recordLevelResult(
          levelId: _puzzle.id,
          stars: stars,
          timeSeconds: state.elapsedSeconds,
          mistakes: state.mistakes,
          hintsUsed: state.hintsUsed,
          coinsAwarded: coins,
          totalLevels: LevelCatalog.totalLevels,
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _persist();
    super.dispose();
  }
}

/// One controller per level id.
final gameControllerProvider = StateNotifierProvider.autoDispose
    .family<GameController, GameState, int>((ref, levelId) {
  final puzzle = ref.watch(puzzleRepositoryProvider).puzzleForLevel(levelId);
  return GameController(ref, puzzle);
});
