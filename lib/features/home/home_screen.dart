import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/data/level_catalog.dart';
import '../../game/util/date_key.dart';
import '../../shared/widgets/animated_count.dart';
import '../../shared/widgets/entrance_fade.dart';
import '../../shared/widgets/floating_bob.dart';
import '../../shared/widgets/pressable_scale.dart';
import 'widgets/puzzle_reveal_background.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final current = profile.highestUnlocked;
    final hasProgress = profile.completedCount > 0;
    final info = LevelCatalog.infoFor(current);
    final resuming =
        ref.read(storageServiceProvider).loadInProgress(current) != null;
    final dailyDone = profile.completedDailyDates.contains(DateKey.today());

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: PuzzleRevealBackground()),
            SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 60,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EntranceFade(
                  offset: const Offset(0, -12),
                  child: Row(
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
                ),
                const SizedBox(height: 28),
                EntranceFade(
                  delay: EntranceFade.stagger(1),
                  child: const _Logo(),
                ),
                const SizedBox(height: 28),
                EntranceFade(
                  delay: EntranceFade.stagger(2),
                  child: _ContinueHero(
                    levelId: current,
                    category: info.category,
                    size: info.size,
                    hasProgress: hasProgress,
                    resuming: resuming,
                    onTap: () => context.push('/game/$current'),
                  ),
                ),
                const SizedBox(height: 12),
                EntranceFade(
                  delay: EntranceFade.stagger(3),
                  child: PressableScale(
                    child: OutlinedButton.icon(
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
                  ),
                ),
                const SizedBox(height: 12),
                EntranceFade(
                  delay: EntranceFade.stagger(4),
                  child: _DailyPuzzleCard(
                    done: dailyDone,
                    onTap: () => context.push('/daily'),
                  ),
                ),
                const SizedBox(height: 12),
                EntranceFade(
                  delay: EntranceFade.stagger(5),
                  child: _ColorPicrossBanner(
                      onTap: () => context.push('/color')),
                ),
                const SizedBox(height: 28),
                EntranceFade(
                  delay: EntranceFade.stagger(6),
                  child: Row(
                    children: [
                      _FeatureTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Daily',
                        color: const Color(0xFF00897B),
                        phase: 0.0,
                        onTap: () => context.push('/daily'),
                      ),
                      _FeatureTile(
                        icon: Icons.celebration_outlined,
                        label: 'Events',
                        color: const Color(0xFF8E24AA),
                        phase: 0.33,
                        onTap: () => context.push('/events'),
                      ),
                      _FeatureTile(
                        icon: Icons.storefront_outlined,
                        label: 'Store',
                        color: AppTheme.primary,
                        phase: 0.66,
                        onTap: () => context.push('/store'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
          ],
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
  final bool resuming;
  final VoidCallback onTap;

  const _ContinueHero({
    required this.levelId,
    required this.category,
    required this.size,
    required this.hasProgress,
    required this.resuming,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleDown: 0.97,
      child: GestureDetector(
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
                    resuming
                        ? 'RESUME'
                        : (hasProgress ? 'CONTINUE' : 'START PLAYING'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    resuming
                        ? 'Level $levelId · pick up where you left off'
                        : 'Level $levelId · $category',
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
            SizedBox(width: 64, height: 64, child: _DecoPattern(seed: levelId)),
            const FloatingBob(
              amplitude: 3,
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// A purely decorative mini-grid (not the level's real solution) with a soft
/// light sweeping diagonally across its filled cells, like a row being solved.
class _DecoPattern extends StatefulWidget {
  final int seed;
  const _DecoPattern({required this.seed});

  @override
  State<_DecoPattern> createState() => _DecoPatternState();
}

class _DecoPatternState extends State<_DecoPattern>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _DecoPatternPainter(widget.seed,
              _c.isAnimating ? _c.value : -1),
        ),
      ),
    );
  }
}

class _DecoPatternPainter extends CustomPainter {
  final int seed;

  /// 0..1 position of the sweep, or negative for no sweep.
  final double sweep;
  _DecoPatternPainter(this.seed, this.sweep);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 4;
    final cell = size.width / n;
    final paint = Paint();
    // The sweep travels diagonal index 0..6 over the first 60% of the cycle.
    final front = sweep < 0 ? -10.0 : sweep / 0.6 * (2 * n + 1) - 1;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final on = ((seed * 31 + r * 7 + c * 13) % 5) < 2;
        final d = (r + c - front).abs();
        final glow = on && d < 1.2 ? (1 - d / 1.2) : 0.0;
        final base = on ? 0.78 : 0.18;
        paint.color = Colors.white.withOpacity((base + 0.22 * glow).clamp(0, 1));
        final grow = 1.5 * glow;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(c * cell + 2 - grow, r * cell + 2 - grow,
                cell - 4 + grow * 2, cell - 4 + grow * 2),
            const Radius.circular(4),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DecoPatternPainter old) =>
      old.seed != seed || old.sweep != sweep;
}

class _DailyPuzzleCard extends StatelessWidget {
  final bool done;
  final VoidCallback onTap;
  const _DailyPuzzleCard({required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleDown: 0.97,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done ? AppTheme.success : const Color(0xFF00897B),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (done ? AppTheme.success : const Color(0xFF00897B))
                    .withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                done ? Icons.check_circle : Icons.today,
                color: done ? AppTheme.success : const Color(0xFF00897B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Puzzle',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.ink)),
                  Text(
                    done ? 'Completed today · come back tomorrow' : 'Play today’s challenge',
                    style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.inkSoft),
          ],
        ),
      ),
      ),
    );
  }
}

class _ColorPicrossBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ColorPicrossBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleDown: 0.97,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEC407A), Color(0xFF8E24AA)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8E24AA).withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            FloatingBob(
              amplitude: 3,
              period: Duration(milliseconds: 2200),
              child: Icon(Icons.palette, color: Colors.white, size: 26),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Color Picross',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  Text('Paint pictures by the numbers',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
      ),
    );
  }
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
    return PressableScale(
      scaleDown: 0.88,
      child: IconButton(onPressed: onTap, icon: Icon(icon)),
    );
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
        FloatingBob(
          amplitude: 3,
          period: const Duration(milliseconds: 3200),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: Colors.white, size: 44),
          ),
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
    const gift = Icon(Icons.card_giftcard_outlined);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PressableScale(
          scaleDown: 0.88,
          child: IconButton(
            onPressed: onTap,
            icon: available
                ? const FloatingBob(
                    amplitude: 2.5,
                    period: Duration(milliseconds: 1400),
                    child: gift,
                  )
                : gift,
          ),
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
          AnimatedCount(
              value: coins,
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
  final double phase;
  final VoidCallback onTap;
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.phase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: PressableScale(
          scaleDown: 0.94,
          child: Material(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Column(
                  children: [
                    FloatingBob(
                      amplitude: 2.5,
                      phase: phase,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(label,
                        style:
                            TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
