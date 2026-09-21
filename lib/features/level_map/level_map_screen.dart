import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/data/level_catalog.dart';

class LevelMapScreen extends ConsumerStatefulWidget {
  const LevelMapScreen({super.key});

  @override
  ConsumerState<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends ConsumerState<LevelMapScreen> {
  late final ScrollController _scroll;
  static const _itemExtent = 96.0;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    // Jump near the current level after first layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(profileControllerProvider).highestUnlocked;
      final target = ((current - 1) * _itemExtent - 200).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );
      _scroll.jumpTo(target);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Level Map')),
      body: ListView.builder(
        controller: _scroll,
        itemCount: LevelCatalog.totalLevels,
        itemExtent: _itemExtent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemBuilder: (context, index) {
          final id = index + 1;
          final info = LevelCatalog.infoFor(id);
          final unlocked = profile.isUnlocked(id);
          final progress = profile.levels[id];
          final isCurrent = id == profile.highestUnlocked;
          // Winding path: alternate alignment.
          final alignLeft = index.isEven;

          return Align(
            alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _LevelNode(
                id: id,
                size: info.size,
                category: info.category,
                unlocked: unlocked,
                isCurrent: isCurrent,
                stars: progress?.stars ?? 0,
                onTap: unlocked ? () => context.push('/game/$id') : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  final int id;
  final int size;
  final String category;
  final bool unlocked;
  final bool isCurrent;
  final int stars;
  final VoidCallback? onTap;

  const _LevelNode({
    required this.id,
    required this.size,
    required this.category,
    required this.unlocked,
    required this.isCurrent,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = !unlocked
        ? AppTheme.line
        : isCurrent
            ? AppTheme.primary
            : AppTheme.card;
    final fg = isCurrent ? Colors.white : AppTheme.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent ? AppTheme.primaryDark : AppTheme.line,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: unlocked
                    ? (isCurrent ? Colors.white24 : AppTheme.surface)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: unlocked
                  ? Text('$id',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: fg, fontSize: 18))
                  : Icon(Icons.lock, color: AppTheme.inkSoft, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unlocked ? category : 'Locked',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: fg, fontSize: 14),
                  ),
                  Text(
                    '$size × $size',
                    style: TextStyle(
                      color: isCurrent ? Colors.white70 : AppTheme.inkSoft,
                      fontSize: 12,
                    ),
                  ),
                  if (unlocked)
                    Row(
                      children: [
                        for (var s = 0; s < 3; s++)
                          Icon(
                            s < stars ? Icons.star : Icons.star_border,
                            size: 15,
                            color: s < stars
                                ? AppTheme.accent
                                : (isCurrent
                                    ? Colors.white54
                                    : AppTheme.line),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
