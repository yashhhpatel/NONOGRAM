import 'package:flutter/material.dart';

/// Gently floats [child] up and down in a slow loop, for decorative icons.
/// A [phase] of 0..1 offsets the cycle so neighbours don't bob in lockstep.
/// Static under reduced-motion.
class FloatingBob extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration period;
  final double phase;

  const FloatingBob({
    super.key,
    required this.child,
    this.amplitude = 4,
    this.period = const Duration(milliseconds: 2600),
    this.phase = 0,
  });

  @override
  State<FloatingBob> createState() => _FloatingBobState();
}

class _FloatingBobState extends State<FloatingBob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.value = widget.phase.clamp(0.0, 1.0);
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
      builder: (context, child) => Transform.translate(
        offset: Offset(
            0, -widget.amplitude * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: widget.child,
    );
  }
}
