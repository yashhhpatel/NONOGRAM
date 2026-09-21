import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/app/providers.dart';
import 'package:nonogram/core/storage/storage_service.dart';
import 'package:nonogram/features/puzzle/game_controller.dart';
import 'package:nonogram/game/models/cell_state.dart';
import 'package:nonogram/game/models/in_progress_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('StorageService round-trips an in-progress board', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    const ips = InProgressState(
      levelId: 5,
      grid: [
        [0, 1],
        [2, 0]
      ],
      hearts: 2,
      mistakes: 1,
      hintsUsed: 0,
      elapsedSeconds: 12,
      autoCross: true,
      tool: 1,
    );
    await storage.saveInProgress(ips);

    final loaded = storage.loadInProgress(5);
    expect(loaded, isNotNull);
    expect(loaded!.grid, [
      [0, 1],
      [2, 0]
    ]);
    expect(loaded.hearts, 2);
    expect(loaded.mistakes, 1);
    expect(loaded.elapsedSeconds, 12);
    expect(loaded.tool, 1);

    await storage.clearInProgress(5);
    expect(storage.loadInProgress(5), isNull);
  });

  test('a filled cell survives leaving and reopening the level', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();

    final c1 = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    final ctrl = c1.read(gameControllerProvider(1).notifier);
    final puzzle = c1.read(gameControllerProvider(1)).puzzle;

    // Fill the first correct cell of the picture.
    late int fr, fc;
    outer:
    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        if (puzzle.solutionAt(r, c)) {
          fr = r;
          fc = c;
          break outer;
        }
      }
    }
    ctrl.paintFill(fr, fc);
    // Let the async save complete.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    c1.dispose();

    // Reopen with the same storage.
    final c2 = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    final restored = c2.read(gameControllerProvider(1));
    expect(restored.playerGrid[fr][fc], CellState.filled);
    c2.dispose();
  });
}
