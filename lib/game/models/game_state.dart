import '../engine/grid_ops.dart';
import 'cell_state.dart';
import 'puzzle.dart';

enum GameTool { fill, cross }

/// A snapshot used for undo. It only restores what a *board* action changes —
/// the grid and the per-level hint counter. Hearts and mistakes are never
/// reverted by undo, so a wrong tap's penalty cannot be refunded by undoing an
/// earlier move.
class GameSnapshot {
  final List<List<CellState>> grid;
  final int hintsUsed;
  const GameSnapshot({
    required this.grid,
    required this.hintsUsed,
  });
}

/// Immutable, predictable game state. All logic that mutates it lives in the
/// game controller; the model itself only holds data and derived getters.
class GameState {
  final Puzzle puzzle;
  final List<List<CellState>> playerGrid;
  final int maxHearts;
  final int hearts;
  final int mistakes;
  final int hintsUsed;
  final int elapsedSeconds;
  final bool autoCrossEnabled;
  final GameTool tool;
  final bool isComplete;
  final int stars;
  final int earnedCoins;
  final int earnedChestBonus;
  final List<GameSnapshot> history;

  /// Cell most recently revealed by a hint, for a brief highlight in the UI.
  final ({int r, int c})? highlight;

  const GameState({
    required this.puzzle,
    required this.playerGrid,
    required this.maxHearts,
    required this.hearts,
    required this.mistakes,
    required this.hintsUsed,
    required this.elapsedSeconds,
    required this.autoCrossEnabled,
    required this.tool,
    required this.isComplete,
    required this.stars,
    required this.earnedCoins,
    required this.earnedChestBonus,
    required this.history,
    required this.highlight,
  });

  factory GameState.initial(
    Puzzle puzzle, {
    int maxHearts = 3,
    bool autoCrossEnabled = true,
  }) {
    return GameState(
      puzzle: puzzle,
      playerGrid: GridOps.blank(puzzle.rows, puzzle.cols),
      maxHearts: maxHearts,
      hearts: maxHearts,
      mistakes: 0,
      hintsUsed: 0,
      elapsedSeconds: 0,
      autoCrossEnabled: autoCrossEnabled,
      tool: GameTool.fill,
      isComplete: false,
      stars: 0,
      earnedCoins: 0,
      earnedChestBonus: 0,
      history: const [],
      highlight: null,
    );
  }

  bool get isGameOver => hearts <= 0 && !isComplete;
  bool get canUndo => history.isNotEmpty;

  GameState copyWith({
    List<List<CellState>>? playerGrid,
    int? hearts,
    int? mistakes,
    int? hintsUsed,
    int? elapsedSeconds,
    bool? autoCrossEnabled,
    GameTool? tool,
    bool? isComplete,
    int? stars,
    int? earnedCoins,
    int? earnedChestBonus,
    List<GameSnapshot>? history,
    ({int r, int c})? highlight,
    bool clearHighlight = false,
  }) {
    return GameState(
      puzzle: puzzle,
      playerGrid: playerGrid ?? this.playerGrid,
      maxHearts: maxHearts,
      hearts: hearts ?? this.hearts,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      autoCrossEnabled: autoCrossEnabled ?? this.autoCrossEnabled,
      tool: tool ?? this.tool,
      isComplete: isComplete ?? this.isComplete,
      stars: stars ?? this.stars,
      earnedCoins: earnedCoins ?? this.earnedCoins,
      earnedChestBonus: earnedChestBonus ?? this.earnedChestBonus,
      history: history ?? this.history,
      highlight: clearHighlight ? null : (highlight ?? this.highlight),
    );
  }
}
