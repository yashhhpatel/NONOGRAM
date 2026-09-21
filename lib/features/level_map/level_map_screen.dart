import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/data/level_catalog.dart';
import '../../game/data/world_catalog.dart';

/// One row in the map: either a world header or a level node.
sealed class _MapItem {
  const _MapItem();
}

class _HeaderItem extends _MapItem {
  final GameWorld world;
  const _HeaderItem(this.world);
}

class _LevelItem extends _MapItem {
  final int id;
  const _LevelItem(this.id);
}

class LevelMapScreen extends ConsumerStatefulWidget {
  const LevelMapScreen({super.key});

  @override
  ConsumerState<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends ConsumerState<LevelMapScreen> {
  late final ScrollController _scroll;
  late final List<_MapItem> _items;
  static const _levelExtent = 96.0;
  static const _headerExtent = 84.0;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    _items = _buildItems();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrent());
  }

  List<_MapItem> _buildItems() {
    final items = <_MapItem>[];
    for (var id = 1; id <= LevelCatalog.totalLevels; id++) {
      if (WorldCatalog.isWorldStart(id)) {
        items.add(_HeaderItem(WorldCatalog.forLevel(id)));
      }
      items.add(_LevelItem(id));
    }
    return items;
  }

  void _jumpToCurrent() {
    final current = ref.read(profileControllerProvider).highestUnlocked;
    var offset = 0.0;
    for (final item in _items) {
      if (item is _LevelItem && item.id == current) break;
      offset += item is _HeaderItem ? _headerExtent : _levelExtent;
    }
    final target = (offset - 240).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.jumpTo(target);
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
        itemCount: _items.length,
        padding: const EdgeInsets.only(bottom: 24),
        itemBuilder: (context, index) {
          final item = _items[index];
          if (item is _HeaderItem) {
            return _WorldHeader(world: item.world);
          }
          final id = (item as _LevelItem).id;
          final info = LevelCatalog.infoFor(id);
          final unlocked = profile.isUnlocked(id);
          final progress = profile.levels[id];
          final isCurrent = id == profile.highestUnlocked;
          final isChest = WorldCatalog.isChestLevel(id);
          final alignLeft = id.isEven;

          return SizedBox(
            height: _levelExtent,
            child: Align(
              alignment:
                  alignLeft ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _LevelNode(
                  id: id,
                  size: info.size,
                  category: info.category,
                  world: WorldCatalog.forLevel(id),
                  unlocked: unlocked,
                  isCurrent: isCurrent,
                  isChest: isChest,
                  chestOpened: progress?.completed ?? false,
                  stars: progress?.stars ?? 0,
                  onTap: unlocked ? () => context.push('/game/$id') : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WorldHeader extends StatelessWidget {
  final GameWorld world;
  const _WorldHeader({required this.world});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [world.color, world.color.withOpacity(0.65)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(world.icon, color: Colors.white, size: 30),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WORLD ${world.index}',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              Text(world.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const Spacer(),
          Text('${world.start}–${world.end}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  final int id;
  final int size;
  final String category;
  final GameWorld world;
  final bool unlocked;
  final bool isCurrent;
  final bool isChest;
  final bool chestOpened;
  final int stars;
  final VoidCallback? onTap;

  const _LevelNode({
    required this.id,
    required this.size,
    required this.category,
    required this.world,
    required this.unlocked,
    required this.isCurrent,
    required this.isChest,
    required this.chestOpened,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = !unlocked
        ? AppTheme.line
        : isCurrent
            ? world.color
            : AppTheme.card;
    final fg = isCurrent ? Colors.white : AppTheme.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 230,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent ? world.color : AppTheme.line,
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          unlocked ? category : 'Locked',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: fg,
                              fontSize: 14),
                        ),
                      ),
                      if (isChest) ...[
                        const SizedBox(width: 6),
                        Icon(
                          chestOpened ? Icons.inventory_2 : Icons.inventory_2_outlined,
                          size: 16,
                          color: chestOpened
                              ? AppTheme.accent
                              : (isCurrent ? Colors.white : AppTheme.accent),
                        ),
                      ],
                    ],
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
