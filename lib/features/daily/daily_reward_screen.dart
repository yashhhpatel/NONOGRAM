import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/util/date_key.dart';

/// The 7-day daily reward cycle. Mirrors the reward table in
/// [ProfileController.claimDailyReward].
const List<int> kDailyRewardCycle = [20, 25, 30, 40, 50, 60, 120];

/// Whether a reward can be claimed today (used by Home to show a badge).
bool dailyRewardAvailable(WidgetRef ref) {
  final profile = ref.watch(profileControllerProvider);
  return profile.lastRewardClaimDate != DateKey.today();
}

class DailyRewardScreen extends ConsumerWidget {
  const DailyRewardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final today = DateKey.today();
    final yesterday = DateKey.yesterday();
    final claimedToday = profile.lastRewardClaimDate == today;

    final int claimableIndex;
    final int collectedUpTo; // last collected index in this cycle (inclusive)
    if (claimedToday) {
      final day = (profile.dailyStreak - 1) % 7;
      claimableIndex = -1;
      collectedUpTo = day;
    } else {
      final nextStreak =
          profile.lastRewardClaimDate == yesterday ? profile.dailyStreak + 1 : 1;
      claimableIndex = (nextStreak - 1) % 7;
      collectedUpTo = claimableIndex - 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Reward')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Colors.white, size: 40),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${profile.dailyStreak}-day streak',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      Text(
                        claimedToday
                            ? 'Come back tomorrow to keep it going!'
                            : 'Claim today to grow your streak.',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  for (var i = 0; i < 7; i++)
                    _DayTile(
                      day: i + 1,
                      coins: kDailyRewardCycle[i],
                      collected: i <= collectedUpTo,
                      claimable: i == claimableIndex,
                      big: i == 6,
                    ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: claimedToday
                    ? null
                    : () => _claim(context, ref, today, yesterday),
                child: Text(claimedToday ? 'Claimed Today' : 'Claim Reward'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _claim(
    BuildContext context,
    WidgetRef ref,
    String today,
    String yesterday,
  ) {
    final reward = ref
        .read(profileControllerProvider.notifier)
        .claimDailyReward(today, yesterday);
    if (reward == null) return;
    ref.read(hapticsServiceProvider).reward(
        ref.read(profileControllerProvider).hapticsOn);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard, color: AppTheme.accent, size: 56),
            const SizedBox(height: 12),
            Text('+$reward coins!',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('See you tomorrow for more.',
                style: TextStyle(color: AppTheme.inkSoft)),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome'),
          ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final int day;
  final int coins;
  final bool collected;
  final bool claimable;
  final bool big;

  const _DayTile({
    required this.day,
    required this.coins,
    required this.collected,
    required this.claimable,
    required this.big,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    if (collected) {
      bg = AppTheme.success.withOpacity(0.12);
    } else if (claimable) {
      bg = AppTheme.primary.withOpacity(0.12);
    } else {
      bg = AppTheme.card;
    }
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: claimable ? AppTheme.primary : AppTheme.line,
          width: claimable ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(big ? 'Day 7' : 'Day $day',
              style: TextStyle(
                  fontSize: 11, color: AppTheme.inkSoft)),
          const SizedBox(height: 6),
          if (collected)
            const Icon(Icons.check_circle, color: AppTheme.success, size: 26)
          else
            Icon(Icons.monetization_on,
                color: big ? AppTheme.accent : AppTheme.primary,
                size: big ? 30 : 24),
          const SizedBox(height: 4),
          Text('$coins',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.ink)),
        ],
      ),
    );
  }
}
