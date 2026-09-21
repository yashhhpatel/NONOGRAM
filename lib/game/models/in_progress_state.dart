import 'cell_state.dart';
import 'game_state.dart';

/// A serializable snapshot of an unfinished puzzle, so a player can leave
/// mid-solve and resume exactly where they were.
class InProgressState {
  final int levelId;
  final List<List<int>> grid; // CellState indices
  final int hearts;
  final int mistakes;
  final int hintsUsed;
  final int elapsedSeconds;
  final bool autoCross;
  final int tool; // GameTool index

  const InProgressState({
    required this.levelId,
    required this.grid,
    required this.hearts,
    required this.mistakes,
    required this.hintsUsed,
    required this.elapsedSeconds,
    required this.autoCross,
    required this.tool,
  });

  factory InProgressState.fromGame(int levelId, GameState s) => InProgressState(
        levelId: levelId,
        grid: [
          for (final row in s.playerGrid) [for (final c in row) c.index],
        ],
        hearts: s.hearts,
        mistakes: s.mistakes,
        hintsUsed: s.hintsUsed,
        elapsedSeconds: s.elapsedSeconds,
        autoCross: s.autoCrossEnabled,
        tool: s.tool.index,
      );

  List<List<CellState>> toCellGrid() =>
      [for (final row in grid) [for (final v in row) CellState.values[v]]];

  /// Whether the player has actually done anything worth restoring.
  bool get hasProgress =>
      mistakes > 0 ||
      grid.any((row) => row.any((v) => v != CellState.unknown.index));

  Map<String, dynamic> toJson() => {
        'id': levelId,
        'g': grid,
        'h': hearts,
        'm': mistakes,
        'hu': hintsUsed,
        'e': elapsedSeconds,
        'ac': autoCross,
        't': tool,
      };

  factory InProgressState.fromJson(Map<String, dynamic> j) => InProgressState(
        levelId: j['id'] as int,
        grid: [
          for (final row in (j['g'] as List<dynamic>))
            [for (final v in (row as List<dynamic>)) v as int],
        ],
        hearts: j['h'] as int,
        mistakes: j['m'] as int,
        hintsUsed: j['hu'] as int,
        elapsedSeconds: j['e'] as int,
        autoCross: j['ac'] as bool? ?? true,
        tool: j['t'] as int? ?? 0,
      );
}
