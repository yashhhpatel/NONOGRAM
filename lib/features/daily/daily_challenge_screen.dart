import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/data/puzzle_repository.dart';
import '../../game/util/date_key.dart';

class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday % 7; // Sunday-first grid

    var completedThisMonth = 0;
    for (var d = 1; d <= daysInMonth; d++) {
      if (profile.completedDailyDates
          .contains(DateKey.of(DateTime(now.year, now.month, d)))) {
        completedThisMonth++;
      }
    }

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Challenge')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${monthNames[now.month - 1]} ${now.year}',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('$completedThisMonth / $daysInMonth completed this month',
              style: const TextStyle(color: AppTheme.inkSoft)),
          const SizedBox(height: 16),
          _weekdayHeader(),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (var i = 0; i < leadingBlanks; i++) const SizedBox(),
              for (var d = 1; d <= daysInMonth; d++)
                _DayCell(
                  day: d,
                  date: DateTime(now.year, now.month, d),
                  now: now,
                  completed: profile.completedDailyDates
                      .contains(DateKey.of(DateTime(now.year, now.month, d))),
                  onPlayToday: () => context
                      .push('/game/${PuzzleRepository.dailyIdFor(now)}'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (!profile.completedDailyDates.contains(DateKey.today()))
            FilledButton.icon(
              onPressed: () =>
                  context.push('/game/${PuzzleRepository.dailyIdFor(now)}'),
              icon: const Icon(Icons.play_arrow),
              label: const Text("Play Today's Puzzle"),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success),
                  SizedBox(width: 10),
                  Text("Today's challenge complete! Come back tomorrow."),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _weekdayHeader() {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: [
        for (final l in labels)
          Expanded(
            child: Center(
              child: Text(l,
                  style: const TextStyle(
                      color: AppTheme.inkSoft, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final DateTime date;
  final DateTime now;
  final bool completed;
  final VoidCallback onPlayToday;

  const _DayCell({
    required this.day,
    required this.date,
    required this.now,
    required this.completed,
    required this.onPlayToday,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateKey.isSameDay(date, now);
    final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

    Color bg;
    Widget child;
    if (completed) {
      bg = AppTheme.success;
      child = const Icon(Icons.check, color: Colors.white, size: 18);
    } else if (isToday) {
      bg = AppTheme.primary;
      child = Text('$day',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800));
    } else if (isFuture) {
      bg = AppTheme.card;
      child = const Icon(Icons.lock, size: 14, color: AppTheme.line);
    } else {
      bg = AppTheme.card;
      child = Text('$day',
          style: const TextStyle(color: AppTheme.inkSoft));
    }

    return GestureDetector(
      onTap: isToday && !completed ? onPlayToday : null,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.line),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
