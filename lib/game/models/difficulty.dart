/// Difficulty tiers. Difficulty is analysed from clue structure and deduction
/// depth, not from grid size alone (see `DifficultyEngine`).
enum Difficulty {
  veryEasy,
  easy,
  medium,
  hard,
  expert;

  String get label => switch (this) {
        Difficulty.veryEasy => 'Very Easy',
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
        Difficulty.expert => 'Expert',
      };

  int toJson() => index;
  static Difficulty fromJson(int v) => Difficulty.values[v];
}
