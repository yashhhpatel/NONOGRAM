import 'package:flutter/material.dart';

/// A slow, subtle scale "breath" that draws the eye to the one thing the
/// player should tap next. Static under reduced-motion.
class Breathe extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration period;

  const Breathe({
    super.key,
    required this.child,
    this.scale = 1.08,
    this.period = const Duration(milliseconds: 1300),
  });

  @override
  State<Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<Breathe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period);
  late final Animation<double> _scale = Tween(begin: 1.0, end: widget.scale)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _c.stop();
      _c.value = 0;
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
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
