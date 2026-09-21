import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A purchasable board skin: it recolors the filled cells. The default
/// "Classic" theme follows the app's light/dark palette.
class BoardTheme {
  final String id;
  final String name;
  final int cost; // coins; 0 = free/default
  final Color? fill; // null => adaptive AppTheme.filled

  const BoardTheme(this.id, this.name, this.cost, this.fill);

  /// The colour to paint filled cells with, resolving the adaptive default.
  Color get fillColor => fill ?? AppTheme.filled;

  /// A representative swatch colour for the store (never null).
  Color get swatch => fill ?? const Color(0xFF2B2F3A);
}

class BoardThemes {
  const BoardThemes._();

  static const classic = BoardTheme('classic', 'Classic', 0, null);

  static const all = [
    classic,
    BoardTheme('ocean', 'Ocean', 200, Color(0xFF1E88E5)),
    BoardTheme('sunset', 'Sunset', 250, Color(0xFFF4511E)),
    BoardTheme('forest', 'Forest', 250, Color(0xFF2E7D32)),
    BoardTheme('berry', 'Berry', 350, Color(0xFF8E24AA)),
    BoardTheme('rose', 'Rose', 350, Color(0xFFEC407A)),
    BoardTheme('gold', 'Gold', 500, Color(0xFFF9A825)),
    BoardTheme('teal', 'Teal', 400, Color(0xFF00897B)),
  ];

  static BoardTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => classic);
}
