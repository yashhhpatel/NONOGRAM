import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';

/// Tournament presentation. The leaderboard here is LOCAL and SIMULATED — it is
/// generated deterministically from the player's own progress and is not a real
/// global ranking. The layout is built so a real backend can replace the data
/// source later without UI changes.
class TournamentScreen extends ConsumerWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);

    // Player's tournament score derived from real progress.
    final playerScore = profile.completedCount * 100 + profile.totalStars * 25;

    // Simulated rivals around the player's score (clearly local/offline).
    final rivals = <(_String, int)>[
      (const _String('Nova'), playerScore + 340),
      (const _String('Pixel'), playerScore + 150),
      (const _String('Echo'), playerScore + 60),
      (const _String('You'), playerScore),
      (const _String('Blip'), (playerScore - 70).clamp(0, 1 << 30)),
      (const _String('Dot'), (playerScore - 180).clamp(0, 1 << 30)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 40),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Weekly Tournament',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    Text('Your score: $playerScore',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Offline demo ranking (not a global leaderboard)',
                style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rivals.length,
              itemBuilder: (context, i) {
                final r = rivals[i];
                final isYou = r.$1.value == 'You';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isYou
                        ? AppTheme.primary.withOpacity(0.1)
                        : AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isYou ? AppTheme.primary : AppTheme.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text('#${i + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(r.$1.value,
                            style: TextStyle(
                                fontWeight: isYou
                                    ? FontWeight.w800
                                    : FontWeight.w600)),
                      ),
                      Text('${r.$2}',
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny wrapper so the rivals list uses a const-friendly value type.
class _String {
  final String value;
  const _String(this.value);
}
