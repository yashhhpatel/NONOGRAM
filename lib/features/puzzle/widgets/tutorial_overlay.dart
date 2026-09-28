import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// A small stepped coach-mark shown once on Level 1. It dims the screen and
/// explains the mechanic step by step via a centered instruction card.
class PuzzleTutorialOverlay extends StatefulWidget {
  final VoidCallback onFinish;
  const PuzzleTutorialOverlay({super.key, required this.onFinish});

  @override
  State<PuzzleTutorialOverlay> createState() => _PuzzleTutorialOverlayState();
}

class _Step {
  final String title;
  final String body;
  const _Step(this.title, this.body);
}

class _PuzzleTutorialOverlayState extends State<PuzzleTutorialOverlay> {
  int _i = 0;

  static const _steps = [
    _Step('Read the clues',
        'The numbers above each column and beside each row tell you the groups of filled cells, in order.'),
    _Step('Fill the cells',
        'Tap a cell to fill it. A wrong tap costs a heart, so use the clues to be sure.'),
    _Step('Mark the blanks',
        'Switch to the X tool to mark cells you know are empty. It keeps the board clear.'),
    _Step('Reveal the picture',
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

    return Stack(
      children: [
        // Scrim that also blocks play during the tutorial.
        Positioned.fill(
          child: GestureDetector(
            onTap: _next,
            child: Container(color: Colors.black.withOpacity(0.62)),
          ),
        ),
        // Message card, always centered on screen for every step.
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _Card(
              step: step,
              index: _i,
              total: _steps.length,
              last: last,
              onNext: _next,
              onSkip: widget.onFinish,
            ),
          ),
        ),
      ],
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
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.ink)),
          const SizedBox(height: 8),
          Text(step.body,
              style: TextStyle(
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
