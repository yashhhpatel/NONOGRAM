import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// A small stepped coach-mark shown once on Level 1. It dims the screen, points
/// at the clues, the grid and the tools in turn, and explains the mechanic.
class PuzzleTutorialOverlay extends StatefulWidget {
  final VoidCallback onFinish;
  const PuzzleTutorialOverlay({super.key, required this.onFinish});

  @override
  State<PuzzleTutorialOverlay> createState() => _PuzzleTutorialOverlayState();
}

enum _Zone { top, grid, tools }

class _Step {
  final _Zone zone;
  final String title;
  final String body;
  const _Step(this.zone, this.title, this.body);
}

class _PuzzleTutorialOverlayState extends State<PuzzleTutorialOverlay> {
  int _i = 0;

  static const _steps = [
    _Step(_Zone.top, 'Read the clues',
        'The numbers above each column and beside each row tell you the groups of filled cells, in order.'),
    _Step(_Zone.grid, 'Fill the cells',
        'Tap a cell to fill it. A wrong tap costs a heart, so use the clues to be sure.'),
    _Step(_Zone.tools, 'Mark the blanks',
        'Switch to the X tool to mark cells you know are empty. It keeps the board clear.'),
    _Step(_Zone.grid, 'Reveal the picture',
        'Fill every correct cell to complete the hidden picture. That\'s it — good luck!'),
  ];

  void _next() {
    if (_i < _steps.length - 1) {
      setState(() => _i++);
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_i];
    final last = _i == _steps.length - 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        // Approximate zones as fractions of the screen height.
        final (double top, double height) = switch (step.zone) {
          _Zone.top => (h * 0.14, h * 0.24),
          _Zone.grid => (h * 0.34, h * 0.34),
          _Zone.tools => (h * 0.86, h * 0.10),
        };
        // Put the card away from the highlighted zone.
        final cardAtBottom = step.zone != _Zone.tools;

        return Stack(
          children: [
            // Scrim that also blocks play during the tutorial.
            Positioned.fill(
              child: GestureDetector(
                onTap: _next,
                child: Container(color: Colors.black.withOpacity(0.62)),
              ),
            ),
            // Highlight ring around the zone.
            Positioned(
              top: top,
              left: 12,
              width: w - 24,
              height: height,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.accent, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            // Message card.
            Positioned(
              left: 20,
              right: 20,
              top: cardAtBottom ? null : h * 0.30,
              bottom: cardAtBottom ? h * 0.16 : null,
              child: _Card(
                step: step,
                index: _i,
                total: _steps.length,
                last: last,
                onNext: _next,
                onSkip: widget.onFinish,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final _Step step;
  final int index;
  final int total;
  final bool last;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _Card({
    required this.step,
    required this.index,
    required this.total,
    required this.last,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.ink)),
          const SizedBox(height: 8),
          Text(step.body,
              style: const TextStyle(
                  fontSize: 15, color: AppTheme.inkSoft, height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              Row(
                children: [
                  for (var d = 0; d < total; d++)
                    Container(
                      margin: const EdgeInsets.only(right: 5),
                      width: d == index ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: d == index ? AppTheme.primary : AppTheme.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              if (!last)
                TextButton(onPressed: onSkip, child: const Text('Skip')),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: onNext,
                child: Text(last ? 'Got it' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
