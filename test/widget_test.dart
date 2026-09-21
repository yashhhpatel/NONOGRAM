import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/app/providers.dart';
import 'package:nonogram/app/router.dart';
import 'package:nonogram/core/storage/storage_service.dart';
import 'package:nonogram/features/puzzle/game_controller.dart';
import 'package:nonogram/game/models/cell_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.create();
  return ProviderContainer(
    overrides: [storageServiceProvider.overrideWithValue(storage)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('game controller: correct tap fills, wrong tap costs a heart', () async {
    final container = await _container();
    addTearDown(container.dispose);

    // Level 1 is the hand-authored Heart (deterministic).
    final controller = container.read(gameControllerProvider(1).notifier);
    final puzzle = container.read(gameControllerProvider(1)).puzzle;

    // Find a correct filled cell and an empty cell from the solution.
    late int fr, fc, er, ec;
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
    outer2:
    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        if (!puzzle.solutionAt(r, c)) {
          er = r;
          ec = c;
          break outer2;
        }
      }
    }

    // Correct fill.
    controller.act(fr, fc);
    expect(container.read(gameControllerProvider(1)).playerGrid[fr][fc].isFilled,
        isTrue);
    expect(container.read(gameControllerProvider(1)).hearts, 3);

    // Wrong fill costs a heart and does not fill.
    controller.act(er, ec);
    final s = container.read(gameControllerProvider(1));
    expect(s.hearts, 2);
    expect(s.mistakes, 1);
    expect(s.playerGrid[er][ec].isFilled, isFalse);

    // Undo restores the correct-fill action (last grid change).
    controller.undo();
    // After undo, hearts unchanged (wrong taps are not on the history stack).
    expect(container.read(gameControllerProvider(1)).hearts, 2);
  });

  test('completing the puzzle marks complete, awards stars and coins',
      () async {
    final container = await _container();
    addTearDown(container.dispose);

    final controller = container.read(gameControllerProvider(1).notifier);
    final puzzle = container.read(gameControllerProvider(1)).puzzle;

    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        if (puzzle.solutionAt(r, c)) {
          controller.paintFill(r, c);
        }
      }
    }

    final s = container.read(gameControllerProvider(1));
    expect(s.isComplete, isTrue);
    expect(s.stars, 3); // no mistakes, no hints
    expect(s.earnedCoins, greaterThan(0));

    // Progress persisted: level 1 recorded, level 2 unlocked.
    final profile = container.read(profileControllerProvider);
    expect(profile.levels[1]?.completed, isTrue);
    expect(profile.highestUnlocked, greaterThanOrEqualTo(2));
  });

  testWidgets('onboarding shows and can be skipped to home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const _TestApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    // Home screen CTA.
    expect(find.text('START PLAYING'), findsOneWidget);
  });
}

class _TestApp extends ConsumerWidget {
  const _TestApp();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reuse the real router via a MaterialApp.router equivalent.
    final router = ref.watch(_routerForTest);
    return MaterialApp.router(routerConfig: router);
  }
}

// Import the real router provider indirectly to avoid a separate build path.
final _routerForTest = routerProvider;
