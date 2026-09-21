import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/data/level_catalog.dart';
import '../../game/util/date_key.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final current = profile.highestUnlocked;
    final hasProgress = profile.completedCount > 0;
    final info = LevelCatalog.infoFor(current);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 60,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _CoinPill(coins: profile.coins),
                    if (profile.dailyStreak > 0) ...[
                      const SizedBox(width: 8),
                      _StreakChip(streak: profile.dailyStreak),
                    ],
                    const Spacer(),
                    _TopIcon(
                      icon: Icons.emoji_events_outlined,
                      onTap: () => context.push('/achievements'),
                    ),
                    _GiftButton(
                      available:
                          profile.lastRewardClaimDate != DateKey.today(),
                      onTap: () => context.push('/daily-reward'),
                    ),
                    _TopIcon(
                      icon: Icons.settings_outlined,
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const _Logo(),
                const SizedBox(height: 28),
                _ContinueHero(
                  levelId: current,
                  category: info.category,
                  size: info.size,
                  hasProgress: hasProgress,
                  onTap: () => context.push('/game/$current'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/map'),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  label: const Text('Level Map'),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    _FeatureTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Daily',
                      color: const Color(0xFF00897B),
                      onTap: () => context.push('/daily'),
                    ),
                    _FeatureTile(
                      icon: Icons.celebration_outlined,
                      label: 'Events',
                      color: const Color(0xFF8E24AA),
                      onTap: () => context.push('/events'),
                    ),
                    _FeatureTile(
                      icon: Icons.leaderboard_outlined,
                      label: 'Tournament',
                      color: const Color(0xFFF4511E),
                      onTap: () => context.push('/tournament'),
                    ),
                    _FeatureTile(
                      icon: Icons.storefront_outlined,
                      label: 'Store',
                      color: AppTheme.primary,
                      onTap: () => context.push('/store'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${profile.completedCount} / ${LevelCatalog.totalLevels} levels  ·  ${profile.totalStars}★',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.inkSoft, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueHero extends StatelessWidget {
  final int levelId;
  final String category;
  final int size;
  final bool hasProgress;
  final VoidCallback onTap;

  const _ContinueHero({
    required this.levelId,
    required this.category,
    required this.size,
    required this.hasProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasProgress ? 'CONTINUE' : 'START PLAYING',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Level $levelId · $category',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '$size × $size grid',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(painter: _DecoPatternPainter(levelId)),
            ),
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
          ],
        ),
      ),
    );
  }
}

/// A purely decorative dot pattern (not the level's real solution).
class _DecoPatternPainter extends CustomPainter {
  final int seed;
  _DecoPatternPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 4;
    final cell = size.width / n;
    final paint = Paint();
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final on = ((seed * 31 + r * 7 + c * 13) % 5) < 2;
        paint.color = Colors.white.withOpacity(on ? 0.85 : 0.18);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(c * cell + 2, r * cell + 2, cell - 4, cell - 4),
            const Radius.circular(4),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DecoPatternPainter old) => old.seed != seed;
}

class _StreakChip extends StatelessWidget {
  final int streak;
  const _StreakChip({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              color: AppTheme.accent, size: 18),
          const SizedBox(width: 4),
          Text('$streak',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.accent)),
        ],
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: onTap, icon: Icon(icon));
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    // Depend on Theme so this const widget rebuilds when the app theme flips;
    // the colours below are then re-read for the new brightness.
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.grid_view_rounded,
              color: Colors.white, size: 44),
        ),
        const SizedBox(height: 14),
        Text(
          'PIXEL CROSS',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Solve the numbers. Reveal the picture.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: scheme.onSurface.withOpacity(0.65), fontSize: 14),
        ),
      ],
    );
  }
}

class _GiftButton extends StatelessWidget {
  final bool available;
  final VoidCallback onTap;
  const _GiftButton({required this.available, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.card_giftcard_outlined),
        ),
        if (available)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surface, width: 1.5),
              ),
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
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.ink)),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.color,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
