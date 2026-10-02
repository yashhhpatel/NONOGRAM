import 'package:flutter/material.dart';

/// Displays an integer that rolls smoothly from its previous value to the new
/// one whenever [value] changes (e.g. a coin balance), with a brief scale
/// bump when it goes up. Instant under reduced-motion.
class AnimatedCount extends StatefulWidget {
  final int value;
  final TextStyle? style;

  const AnimatedCount({super.key, required this.value, this.style});

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650))
    ..value = 1;
  late Animation<int> _count =
      IntTween(begin: widget.value, end: widget.value).animate(_c);
  bool _rising = false;

  @override
  void didUpdateWidget(covariant AnimatedCount old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    final from = _count.value;
    _rising = widget.value > from;
    _count = IntTween(begin: from, end: widget.value)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
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
      builder: (context, _) {
        final bump = _rising && _c.isAnimating
            ? 1 + 0.18 * (1 - (2 * _c.value - 1).abs())
            : 1.0;
        return Transform.scale(
          scale: bump,
          child: Text('${_count.value}', style: widget.style),
        );
      },
    );
  }
}
