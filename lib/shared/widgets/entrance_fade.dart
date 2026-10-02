import 'package:flutter/material.dart';

/// Fades and slides [child] into place once, after [delay]. Use increasing
/// delays on sibling items for a staggered, cascading entrance. Honors
/// reduced-motion (shows the child immediately).
class EntranceFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Where the child starts, in logical pixels, relative to its final spot.
  final Offset offset;

  const EntranceFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 18),
  });

  /// A stagger delay for the [index]th item, capped so long lists don't wait.
  static Duration stagger(int index, {int stepMs = 55, int maxSteps = 8}) =>
      Duration(milliseconds: stepMs * (index < maxSteps ? index : maxSteps));

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  // The delay is folded into the controller (via an Interval) rather than a
  // timer, so nothing is left pending if the widget goes away early.
  late final AnimationController _c = AnimationController(
      vsync: this, duration: widget.delay + widget.duration);
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay.inMicroseconds / (widget.delay + widget.duration).inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _c.value = 1;
    } else {
      _c.forward();
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
      animation: _t,
      builder: (context, child) {
        final t = _t.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: widget.offset * (1 - t),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
