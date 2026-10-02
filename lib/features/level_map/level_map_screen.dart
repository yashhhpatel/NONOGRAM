import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/data/level_catalog.dart';
import '../../game/data/world_catalog.dart';
import '../../shared/widgets/entrance_fade.dart';
import '../../shared/widgets/floating_bob.dart';
import '../../shared/widgets/pop_in.dart';
import '../../shared/widgets/pressable_scale.dart';

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
          final delay = Duration(milliseconds: (index % 6) * 40);
          if (item is _HeaderItem) {
            return EntranceFade(
              delay: delay,
              child: _WorldHeader(world: item.world),
            );
          }
          final id = (item as _LevelItem).id;
          final info = LevelCatalog.infoFor(id);
          final unlocked = profile.isUnlocked(id);
          final progress = profile.levels[id];
          final isCurrent = id == profile.highestUnlocked;
          final isChest = WorldCatalog.isChestLevel(id);
          final alignLeft = id.isEven;
          final world = WorldCatalog.forLevel(id);
          final linksToNext =
              index + 1 < _items.length && _items[index + 1] is _LevelItem;

          return EntranceFade(
            delay: delay,
            offset: Offset(alignLeft ? -28 : 28, 0),
            child: SizedBox(
              height: _levelExtent,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (linksToNext)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TrailPainter(
                          fromLeft: alignLeft,
                          color: (progress?.completed ?? false)
                              ? world.color.withOpacity(0.55)
                              : AppTheme.line,
                        ),
                      ),
                    ),
                  Align(
                    alignment: alignLeft
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: _LevelNode(
                        id: id,
                        size: info.size,
                        category: info.category,
                        world: world,
                        unlocked: unlocked,
                        isCurrent: isCurrent,
                        isChest: isChest,
                        chestOpened: progress?.completed ?? false,
                        stars: progress?.stars ?? 0,
                        onTap:
                            unlocked ? () => context.push('/game/$id') : null,
                      ),
                    ),
                  ),
                ],
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
          FloatingBob(
            amplitude: 3,
            child: Icon(world.icon, color: Colors.white, size: 30),
          ),
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

    final node = PressableScale(
      enabled: unlocked,
      child: InkWell(
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
          boxShadow: unlocked && !isCurrent
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
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
                          s < stars
                              ? PopIn(
                                  delay: Duration(
                                      milliseconds: 180 + s * 110),
                                  child: const Icon(Icons.star,
                                      size: 15, color: AppTheme.accent),
                                )
                              : Icon(
                                  Icons.star_border,
                                  size: 15,
                                  color: isCurrent
                                      ? Colors.white54
                                      : AppTheme.line,
                                ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );

    return isCurrent ? _CurrentPulse(color: world.color, child: node) : node;
  }
}

/// A soft, breathing halo around the level the player should play next.
class _CurrentPulse extends StatefulWidget {
  final Color color;
  final Widget child;
  const _CurrentPulse({required this.color, required this.child});

  @override
  State<_CurrentPulse> createState() => _CurrentPulseState();
}

class _CurrentPulseState extends State<_CurrentPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _c.stop();
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.18 + 0.22 * t),
                blurRadius: 10 + 14 * t,
                spreadRadius: 1 + 3 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A dotted, winding trail from this level's node down to the next one,
/// linking the map into a single path.
class _TrailPainter extends CustomPainter {
  final bool fromLeft;
  final Color color;
  _TrailPainter({required this.fromLeft, required this.color});

  static const _nodeCenterInset = 28 + 230 / 2;

  @override
  void paint(Canvas canvas, Size size) {
    const leftX = _nodeCenterInset;
    final rightX = size.width - _nodeCenterInset;
    final x1 = fromLeft ? leftX : rightX;
    final x2 = fromLeft ? rightX : leftX;
    final y1 = size.height / 2;
    final y2 = size.height * 1.5;
    final path = Path()
      ..moveTo(x1, y1)
      ..cubicTo(x1, size.height, x2, size.height, x2, y2);

    final dot = Paint()..color = color;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 11) {
        final pos = metric.getTangentForOffset(d)?.position;
        if (pos != null) canvas.drawCircle(pos, 2.6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) =>
      old.fromLeft != fromLeft || old.color != color;
}
