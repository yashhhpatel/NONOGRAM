import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/data/level_catalog.dart';
import '../../shared/widgets/animated_progress_bar.dart';
import '../../shared/widgets/entrance_fade.dart';
import '../../shared/widgets/floating_bob.dart';
import '../../shared/widgets/pop_in.dart';

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
          for (final (i, e) in _events.indexed)
            EntranceFade(
              delay: EntranceFade.stagger(i, stepMs: 60),
              child: _EventCard(
                def: e,
                phase: i / _events.length,
                progress: (perCategory[e.category] ?? 0).clamp(0, e.target),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final _EventDef def;
  final int progress;
  final double phase;
  const _EventCard(
      {required this.def, required this.progress, required this.phase});

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FloatingBob(
                amplitude: 2.5,
                phase: phase,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: def.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(def.icon, color: def.color),
                ),
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
                        style: TextStyle(
                            color: AppTheme.inkSoft, fontSize: 12)),
                  ],
                ),
              ),
              if (done)
                const PopIn(
                  delay: Duration(milliseconds: 600),
                  child: Icon(Icons.emoji_events, color: AppTheme.accent),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedProgressBar(
            value: ratio,
            height: 8,
            backgroundColor: AppTheme.surface,
            color: def.color,
          ),
          const SizedBox(height: 6),
          Text('$progress / ${def.target} puzzles',
              style: TextStyle(color: AppTheme.inkSoft, fontSize: 12)),
        ],
      ),
    );
  }
}
