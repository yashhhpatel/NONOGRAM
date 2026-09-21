import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/data/level_catalog.dart';

/// Modular events. Each event tracks real progress: completed campaign levels
/// belonging to its themed category. Events are decoupled from the campaign's
/// unlock logic — they are a read-only view over existing progress plus their
/// own reward state.
class _EventDef {
  final String name;
  final String category;
  final IconData icon;
  final Color color;
  final int target;
  const _EventDef(this.name, this.category, this.icon, this.color, this.target);
}

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  static const _events = [
    _EventDef('Wild Kingdom', 'Animals', Icons.pets, Color(0xFF6D4C41), 20),
    _EventDef('Deep Space', 'Space', Icons.rocket_launch, Color(0xFF5E35B1), 15),
    _EventDef('Ocean Depths', 'Ocean', Icons.water, Color(0xFF0277BD), 15),
    _EventDef('Garden Bloom', 'Plants', Icons.local_florist, Color(0xFF2E7D32), 15),
    _EventDef('Tasty Treats', 'Food', Icons.restaurant, Color(0xFFEF6C00), 15),
    _EventDef('Grand Tour', 'Travel', Icons.flight, Color(0xFF00838F), 15),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);

    // Count completed levels per category (real progress).
    final perCategory = <String, int>{};
    for (final entry in profile.levels.values) {
      if (!entry.completed) continue;
      final cat = LevelCatalog.infoFor(entry.levelId).category;
      perCategory[cat] = (perCategory[cat] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final e in _events)
            _EventCard(
              def: e,
              progress: (perCategory[e.category] ?? 0).clamp(0, e.target),
            ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final _EventDef def;
  final int progress;
  const _EventCard({required this.def, required this.progress});

  @override
  Widget build(BuildContext context) {
    final ratio = progress / def.target;
    final done = progress >= def.target;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: def.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(def.icon, color: def.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(def.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('${def.category} theme',
                        style: const TextStyle(
                            color: AppTheme.inkSoft, fontSize: 12)),
                  ],
                ),
              ),
              if (done)
                const Icon(Icons.emoji_events, color: AppTheme.accent),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppTheme.surface,
              color: def.color,
            ),
          ),
          const SizedBox(height: 6),
          Text('$progress / ${def.target} puzzles',
              style: const TextStyle(color: AppTheme.inkSoft, fontSize: 12)),
        ],
      ),
    );
  }
}
