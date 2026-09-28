import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/achievements/achievements_screen.dart';
import '../features/color_puzzle/color_levels_screen.dart';
import '../features/color_puzzle/color_puzzle_screen.dart';
import '../features/daily/daily_challenge_screen.dart';
import '../features/daily/daily_reward_screen.dart';
import '../features/events/events_screen.dart';
import '../features/home/home_screen.dart';
import '../features/level_map/level_map_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/puzzle/puzzle_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/store/remove_ads_screen.dart';
import '../features/store/store_screen.dart';
import 'providers.dart';

/// Shared fade + slight-slide transition for every route, so navigation
/// feels smooth and consistent without altering the route graph itself.
CustomTransitionPage<void> _fadeSlidePage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        return child;
      }
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

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
      GoRoute(
        path: '/',
        pageBuilder: (_, __) => _fadeSlidePage(const HomeScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, __) => _fadeSlidePage(const OnboardingScreen()),
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (_, __) => _fadeSlidePage(const LevelMapScreen()),
      ),
      GoRoute(
        path: '/game/:id',
        pageBuilder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
          return _fadeSlidePage(PuzzleScreen(levelId: id));
        },
      ),
      GoRoute(
        path: '/daily',
        pageBuilder: (_, __) => _fadeSlidePage(const DailyChallengeScreen()),
      ),
      GoRoute(
        path: '/daily-reward',
        pageBuilder: (_, __) => _fadeSlidePage(const DailyRewardScreen()),
      ),
      GoRoute(
        path: '/events',
        pageBuilder: (_, __) => _fadeSlidePage(const EventsScreen()),
      ),
      GoRoute(
        path: '/achievements',
        pageBuilder: (_, __) => _fadeSlidePage(const AchievementsScreen()),
      ),
      GoRoute(
        path: '/color',
        pageBuilder: (_, __) => _fadeSlidePage(const ColorLevelsScreen()),
      ),
      GoRoute(
        path: '/color/:i',
        pageBuilder: (_, state) {
          final i = int.tryParse(state.pathParameters['i'] ?? '0') ?? 0;
          return _fadeSlidePage(ColorPuzzleScreen(index: i));
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, __) => _fadeSlidePage(const SettingsScreen()),
      ),
      GoRoute(
        path: '/store',
        pageBuilder: (_, __) => _fadeSlidePage(const StoreScreen()),
      ),
      GoRoute(
        path: '/remove-ads',
        pageBuilder: (_, __) => _fadeSlidePage(const RemoveAdsScreen()),
      ),
    ],
  );
});
