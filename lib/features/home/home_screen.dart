import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/data/level_catalog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final current = profile.highestUnlocked;
    final hasProgress = profile.completedCount > 0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _CoinPill(coins: profile.coins),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const Spacer(),
              const _Logo(),
              const SizedBox(height: 8),
              const Text(
                'Solve the numbers. Reveal the picture.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.inkSoft, fontSize: 15),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => context.push('/game/$current'),
                child: Text(
                  hasProgress ? 'CONTINUE  ·  Level $current' : 'START PLAYING',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/map'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Level Map'),
              ),
              const Spacer(),
              Row(
                children: [
                  _FeatureTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Daily',
                    onTap: () => context.push('/daily'),
                  ),
                  _FeatureTile(
                    icon: Icons.emoji_events_outlined,
                    label: 'Events',
                    onTap: () => context.push('/events'),
                  ),
                  _FeatureTile(
                    icon: Icons.leaderboard_outlined,
                    label: 'Tournament',
                    onTap: () => context.push('/tournament'),
                  ),
                  _FeatureTile(
                    icon: Icons.storefront_outlined,
                    label: 'Store',
                    onTap: () => context.push('/store'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${profile.completedCount} / ${LevelCatalog.totalLevels} levels  ·  ${profile.totalStars}★',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.inkSoft, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.grid_view_rounded,
              color: Colors.white, size: 48),
        ),
        const SizedBox(height: 16),
        const Text(
          'PIXEL CROSS',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppTheme.ink,
          ),
        ),
      ],
    );
  }
}

class _CoinPill extends StatelessWidget {
  final int coins;
  const _CoinPill({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: AppTheme.accent, size: 20),
          const SizedBox(width: 6),
          Text('$coins',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.ink)),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.line),
            ),
            child: Column(
              children: [
                Icon(icon, color: AppTheme.primary),
                const SizedBox(height: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.inkSoft)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
