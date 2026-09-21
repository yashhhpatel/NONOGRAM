import 'package:flutter/material.dart';

import 'player_profile.dart';

/// An achievement derived from the player's saved stats. Unlock state is
/// computed from the profile, so nothing extra needs to be persisted.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  /// Current progress value and the target needed to unlock.
  final int Function(PlayerProfile) progress;
  final int goal;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.goal,
  });

  bool unlocked(PlayerProfile p) => progress(p) >= goal;
}

class Achievements {
  const Achievements._();

  static int _threeStarCount(PlayerProfile p) =>
      p.levels.values.where((l) => l.stars >= 3).length;

  static final List<Achievement> all = [
    Achievement(
      id: 'first_win',
      title: 'First Steps',
      description: 'Complete your first puzzle',
      icon: Icons.flag,
      progress: (p) => p.completedCount,
      goal: 1,
    ),
    Achievement(
      id: 'ten_levels',
      title: 'Getting Warmed Up',
      description: 'Complete 10 levels',
      icon: Icons.grid_view,
      progress: (p) => p.completedCount,
      goal: 10,
    ),
    Achievement(
      id: 'fifty_levels',
      title: 'Puzzle Enthusiast',
      description: 'Complete 50 levels',
      icon: Icons.extension,
      progress: (p) => p.completedCount,
      goal: 50,
    ),
    Achievement(
      id: 'hundred_levels',
      title: 'Century',
      description: 'Complete 100 levels',
      icon: Icons.workspace_premium,
      progress: (p) => p.completedCount,
      goal: 100,
    ),
    const Achievement(
      id: 'perfectionist',
      title: 'Perfectionist',
      description: 'Earn 3 stars on 10 levels',
      icon: Icons.auto_awesome,
      progress: _threeStarCount,
      goal: 10,
    ),
    Achievement(
      id: 'star_collector',
      title: 'Star Collector',
      description: 'Earn 100 stars',
      icon: Icons.star,
      progress: (p) => p.totalStars,
      goal: 100,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Reach a 7-day reward streak',
      icon: Icons.local_fire_department,
      progress: (p) => p.dailyStreak,
      goal: 7,
    ),
    Achievement(
      id: 'daily_devotee',
      title: 'Daily Devotee',
      description: 'Complete 10 daily challenges',
      icon: Icons.calendar_month,
      progress: (p) => p.completedDailyDates.length,
      goal: 10,
    ),
    Achievement(
      id: 'coin_hoarder',
      title: 'Coin Hoarder',
      description: 'Hold 1,000 coins at once',
      icon: Icons.savings,
      progress: (p) => p.coins,
      goal: 1000,
    ),
    Achievement(
      id: 'stylist',
      title: 'Stylist',
      description: 'Own 3 board themes',
      icon: Icons.palette,
      progress: (p) => p.ownedThemes.length,
      goal: 3,
    ),
  ];

  static int unlockedCount(PlayerProfile p) =>
      all.where((a) => a.unlocked(p)).length;
}
