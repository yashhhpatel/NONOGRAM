import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/daily/daily_challenge_screen.dart';
import '../features/events/events_screen.dart';
import '../features/home/home_screen.dart';
import '../features/level_map/level_map_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/puzzle/puzzle_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/store/store_screen.dart';
import '../features/tournament/tournament_screen.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final done = ref.read(profileControllerProvider).onboardingDone;
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!done && !atOnboarding) return '/onboarding';
      if (done && atOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/map', builder: (_, __) => const LevelMapScreen()),
      GoRoute(
        path: '/game/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
          return PuzzleScreen(levelId: id);
        },
      ),
      GoRoute(path: '/daily', builder: (_, __) => const DailyChallengeScreen()),
      GoRoute(path: '/events', builder: (_, __) => const EventsScreen()),
      GoRoute(
        path: '/tournament',
        builder: (_, __) => const TournamentScreen(),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/store', builder: (_, __) => const StoreScreen()),
    ],
  );
});
