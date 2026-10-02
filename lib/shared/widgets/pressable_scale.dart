import 'package:flutter/material.dart';

/// Wraps [child] with a subtle press-down scale for a more premium, tactile
/// feel on taps. Purely visual: it observes raw pointer events via [Listener]
/// rather than competing for the tap gesture, so it never intercepts or
/// double-fires whatever tap handling [child] already has (InkWell, a
/// Material button, a GestureDetector, etc). Honors reduced-motion (skips
/// the scale entirely).
class PressableScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double scaleDown;

  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scaleDown = 0.96,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 160),
  );
  late final Animation<double> _scale = Tween(begin: 1.0, end: widget.scaleDown)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  bool get _motion =>
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent _) {
    if (!widget.enabled || !_motion) return;
    _c.forward();
  }

  void _up([PointerEvent? _]) {
    if (_c.isAnimating || _c.value > 0) _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
