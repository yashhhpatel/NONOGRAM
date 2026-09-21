import 'package:flutter/material.dart';

import '../models/color_puzzle.dart';

/// A hand-authored colored picture. `legend` maps each character to a colour
/// index (0 = empty); `palette` lists the colours for indices 1..N.
class ColorArt {
  final String title;
  final String category;
  final List<Color> palette; // index 0 placeholder, 1..N colours
  final Map<String, int> legend; // char -> colour index (0 = empty)
  final List<String> rows;

  const ColorArt({
    required this.title,
    required this.category,
    required this.palette,
    required this.legend,
    required this.rows,
  });

  ColorPuzzle toPuzzle(int id) {
    final solution = [
      for (final row in rows)
        [for (final ch in row.split('')) legend[ch] ?? 0],
    ];
    return ColorPuzzle.build(
      id: id,
      solution: solution,
      palette: palette,
      title: title,
      category: category,
    );
  }
}

// Shared colours.
const _placeholder = Color(0x00000000);
const _red = Color(0xFFE53935);
const _orange = Color(0xFFFB8C00);
const _yellow = Color(0xFFFDD835);
const _green = Color(0xFF43A047);
const _brown = Color(0xFF8D6E63);
const _purple = Color(0xFF8E24AA);
const _pink = Color(0xFFEC407A);
const _dark = Color(0xFF37474F);

class ColorPuzzleCatalog {
  const ColorPuzzleCatalog._();

  static const List<ColorArt> all = [
    ColorArt(
      title: 'Heart',
      category: 'Symbols',
      palette: [_placeholder, _red],
      legend: {'.': 0, 'r': 1},
      rows: ['.r.r.', 'rrrrr', 'rrrrr', '.rrr.', '..r..'],
    ),
    ColorArt(
      title: 'Strawberry',
      category: 'Food',
      palette: [_placeholder, _red, _green],
      legend: {'.': 0, 'r': 1, 'g': 2},
      rows: ['.g.g.', 'ggggg', '.rrr.', '.rrr.', '..r..'],
    ),
    ColorArt(
      title: 'Flower',
      category: 'Plants',
      palette: [_placeholder, _pink, _yellow, _green],
      legend: {'.': 0, 'p': 1, 'y': 2, 'g': 3},
      rows: ['.p.p.', 'ppppp', '.pyp.', '..g..', '..g..'],
    ),
    ColorArt(
      title: 'Ladybug',
      category: 'Animals',
      palette: [_placeholder, _red, _dark],
      legend: {'.': 0, 'r': 1, 'k': 2},
      rows: ['.rrr.', 'rkrkr', 'rrrrr', 'rkrkr', '.rrr.'],
    ),
    ColorArt(
      title: 'Tree',
      category: 'Nature',
      palette: [_placeholder, _green, _brown],
      legend: {'.': 0, 'g': 1, 'b': 2},
      rows: ['.ggg.', 'ggggg', 'ggggg', '..b..', '..b..'],
    ),
    ColorArt(
      title: 'Sun',
      category: 'Nature',
      palette: [_placeholder, _yellow, _orange],
      legend: {'.': 0, 'y': 1, 'o': 2},
      rows: ['o.y.o', '.yyy.', 'yyyyy', '.yyy.', 'o.y.o'],
    ),
    ColorArt(
      title: 'Fish',
      category: 'Ocean',
      palette: [_placeholder, _orange, _dark],
      legend: {'.': 0, 'o': 1, 'k': 2},
      rows: ['o..ooo', 'o.oooo', 'ookooo', 'oooooo', 'o.oooo', 'o..ooo'],
    ),
    ColorArt(
      title: 'Butterfly',
      category: 'Animals',
      palette: [_placeholder, _purple, _dark],
      legend: {'.': 0, 'p': 1, 'k': 2},
      rows: [
        'pp.k.pp',
        'pppkppp',
        '.ppkpp.',
        '..pkp..',
        '.ppkpp.',
        'pppkppp',
        'pp.k.pp',
      ],
    ),
    ColorArt(
      title: 'Rainbow',
      category: 'Symbols',
      palette: [_placeholder, _red, _orange, _yellow, _green],
      legend: {'.': 0, 'r': 1, 'o': 2, 'y': 3, 'g': 4},
      rows: ['rrrrrr', 'oooooo', 'yyyyyy', 'gggggg'],
    ),
    ColorArt(
      title: 'Balloon',
      category: 'Symbols',
      palette: [_placeholder, _red, _dark],
      legend: {'.': 0, 'r': 1, 'k': 2},
      rows: ['.rrr.', 'rrrrr', 'rrrrr', '.rrr.', '..k..', '..k..'],
    ),
  ];

  static int get count => all.length;

  static ColorPuzzle puzzleAt(int index) => all[index].toPuzzle(index);
}
