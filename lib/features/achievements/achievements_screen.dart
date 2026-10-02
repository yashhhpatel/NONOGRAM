import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/models/achievement.dart';
import '../../shared/widgets/animated_progress_bar.dart';
import '../../shared/widgets/entrance_fade.dart';
import '../../shared/widgets/floating_bob.dart';
import '../../shared/widgets/pop_in.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final unlocked = Achievements.unlockedCount(profile);
    final total = Achievements.all.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EntranceFade(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const FloatingBob(
                    child: Icon(Icons.emoji_events,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$unlocked / $total unlocked',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                        const SizedBox(height: 8),
                        AnimatedProgressBar(
                          value: total == 0 ? 0 : unlocked / total,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final (i, a) in Achievements.all.indexed)
            EntranceFade(
              delay: EntranceFade.stagger(i + 1, stepMs: 45),
              child: _AchievementTile(
                achievement: a,
                value: a.progress(profile),
              ),
            ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final int value;
  const _AchievementTile({required this.achievement, required this.value});

  @override
  Widget build(BuildContext context) {
    final done = value >= achievement.goal;
    final ratio = (value / achievement.goal).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? AppTheme.success : AppTheme.line,
          width: done ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done
                  ? AppTheme.success.withOpacity(0.15)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(achievement.icon,
                color: done ? AppTheme.success : AppTheme.inkSoft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppTheme.ink)),
                Text(achievement.description,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.inkSoft)),
                const SizedBox(height: 6),
                AnimatedProgressBar(
                  value: ratio,
                  backgroundColor: AppTheme.surface,
                  color: done ? AppTheme.success : AppTheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          done
              ? const PopIn(
                  delay: Duration(milliseconds: 500),
                  child: Icon(Icons.check_circle, color: AppTheme.success),
                )
              : Text(
                  '$value/${achievement.goal}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.inkSoft,
                      fontWeight: FontWeight.w600),
                ),
        ],
      ),
    );
  }
}
