import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/data/color_puzzle_catalog.dart';
import '../../game/models/color_puzzle.dart';

class ColorLevelsScreen extends ConsumerWidget {
  const ColorLevelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(profileControllerProvider).completedColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Color Picross')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC407A), Color(0xFF8E24AA)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.palette, color: Colors.white, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Color Picross',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      Text(
                        'Pick a colour, then fill by the numbers. '
                        '${completed.length}/${ColorPuzzleCatalog.count} solved.',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
            children: [
              for (var i = 0; i < ColorPuzzleCatalog.count; i++)
                _ColorCard(
                  puzzle: ColorPuzzleCatalog.puzzleAt(i),
                  done: completed.contains(i),
                  onTap: () => context.push('/color/$i'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorCard extends StatelessWidget {
  final ColorPuzzle puzzle;
  final bool done;
  final VoidCallback onTap;
  const _ColorCard(
      {required this.puzzle, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done ? AppTheme.success : AppTheme.line,
            width: done ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: done
                  ? CustomPaint(
                      painter: _MiniColorPainter(puzzle),
                      size: Size.infinite,
                    )
                  : Center(
                      child: Icon(Icons.help_outline,
                          color: AppTheme.inkSoft, size: 28),
                    ),
            ),
            const SizedBox(height: 6),
            Text(done ? puzzle.title : '???',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink)),
            if (done)
              const Icon(Icons.check_circle, color: AppTheme.success, size: 15),
          ],
        ),
      ),
    );
  }
}

class _MiniColorPainter extends CustomPainter {
  final ColorPuzzle puzzle;
  _MiniColorPainter(this.puzzle);

  @override
  void paint(Canvas canvas, Size size) {
    final s = (size.width / puzzle.cols) < (size.height / puzzle.rows)
        ? size.width / puzzle.cols
        : size.height / puzzle.rows;
    final offX = (size.width - s * puzzle.cols) / 2;
    final offY = (size.height - s * puzzle.rows) / 2;
    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        final v = puzzle.colorAt(r, c);
        if (v > 0) {
          canvas.drawRect(
            Rect.fromLTWH(offX + c * s, offY + r * s, s + 0.5, s + 0.5),
            Paint()..color = puzzle.palette[v],
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniColorPainter old) => false;
}
