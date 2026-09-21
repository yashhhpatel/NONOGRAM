import 'package:flutter/material.dart';

/// A themed "world" grouping a run of campaign levels. Purely presentational —
/// it adds chapter structure and colour to the level map.
class GameWorld {
  final int index;
  final String name;
  final Color color;
  final int start;
  final int end;
  final IconData icon;

  const GameWorld({
    required this.index,
    required this.name,
    required this.color,
    required this.start,
    required this.end,
    required this.icon,
  });

  bool contains(int levelId) => levelId >= start && levelId <= end;
}

class WorldCatalog {
  const WorldCatalog._();

  /// Ten worlds of 100 levels each, spanning the 1,000-level campaign.
  static const worlds = <GameWorld>[
    GameWorld(index: 1, name: 'Sprouting Meadow', color: Color(0xFF43A047), start: 1, end: 100, icon: Icons.local_florist),
    GameWorld(index: 2, name: 'Coral Bay', color: Color(0xFF039BE5), start: 101, end: 200, icon: Icons.waves),
    GameWorld(index: 3, name: 'Golden Dunes', color: Color(0xFFF9A825), start: 201, end: 300, icon: Icons.wb_sunny),
    GameWorld(index: 4, name: 'Whispering Forest', color: Color(0xFF2E7D32), start: 301, end: 400, icon: Icons.park),
    GameWorld(index: 5, name: 'Frostpeak Mountains', color: Color(0xFF00838F), start: 401, end: 500, icon: Icons.terrain),
    GameWorld(index: 6, name: 'Neon City', color: Color(0xFF8E24AA), start: 501, end: 600, icon: Icons.location_city),
    GameWorld(index: 7, name: 'Ember Volcano', color: Color(0xFFE53935), start: 601, end: 700, icon: Icons.local_fire_department),
    GameWorld(index: 8, name: 'Aurora Tundra', color: Color(0xFF5E35B1), start: 701, end: 800, icon: Icons.ac_unit),
    GameWorld(index: 9, name: 'Starlit Expanse', color: Color(0xFF3949AB), start: 801, end: 900, icon: Icons.rocket_launch),
    GameWorld(index: 10, name: 'Cosmic Frontier', color: Color(0xFF00897B), start: 901, end: 1000, icon: Icons.auto_awesome),
  ];

  static GameWorld forLevel(int levelId) =>
      worlds.firstWhere((w) => w.contains(levelId), orElse: () => worlds.last);

  static bool isWorldStart(int levelId) =>
      worlds.any((w) => w.start == levelId);

  /// Milestone chests appear every 25 levels.
  static const int chestInterval = 25;
  static bool isChestLevel(int levelId) => levelId % chestInterval == 0;

  /// Coins granted the first time a milestone chest level is completed.
  static int chestReward(int levelId) => 50 + (levelId ~/ 100) * 10;
}
