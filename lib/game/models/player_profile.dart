import 'level_progress.dart';

/// The complete persisted player state. Serialised to a single JSON blob.
class PlayerProfile {
  final int highestUnlocked; // highest unlocked level id (>=1)
  final int coins;
  final int hints;

  // Settings.
  final bool soundOn;
  final bool musicOn;
  final bool hapticsOn;
  final bool autoCrossOn;

  // Monetization.
  final bool removeAds;

  // Onboarding.
  final bool onboardingDone;

  // Whether the in-game Level 1 tutorial has been shown.
  final bool tutorialDone;

  // Per-level results.
  final Map<int, LevelProgress> levels;

  // Daily challenge (set of yyyy-MM-dd completed).
  final Set<String> completedDailyDates;

  // Daily reward.
  final int dailyStreak;
  final String? lastRewardClaimDate; // yyyy-MM-dd
  final Set<String> claimedRewardDates;

  const PlayerProfile({
    required this.highestUnlocked,
    required this.coins,
    required this.hints,
    required this.soundOn,
    required this.musicOn,
    required this.hapticsOn,
    required this.autoCrossOn,
    required this.removeAds,
    required this.onboardingDone,
    required this.tutorialDone,
    required this.levels,
    required this.completedDailyDates,
    required this.dailyStreak,
    required this.lastRewardClaimDate,
    required this.claimedRewardDates,
  });

  factory PlayerProfile.fresh() => const PlayerProfile(
        highestUnlocked: 1,
        coins: 50,
        hints: 3,
        soundOn: true,
        musicOn: true,
        hapticsOn: true,
        autoCrossOn: true,
        removeAds: false,
        onboardingDone: false,
        tutorialDone: false,
        levels: {},
        completedDailyDates: {},
        dailyStreak: 0,
        lastRewardClaimDate: null,
        claimedRewardDates: {},
      );

  int get totalStars =>
      levels.values.fold(0, (sum, lp) => sum + lp.stars);

  int get completedCount =>
      levels.values.where((lp) => lp.completed).length;

  bool isUnlocked(int levelId) => levelId <= highestUnlocked;

  PlayerProfile copyWith({
    int? highestUnlocked,
    int? coins,
    int? hints,
    bool? soundOn,
    bool? musicOn,
    bool? hapticsOn,
    bool? autoCrossOn,
    bool? removeAds,
    bool? onboardingDone,
    bool? tutorialDone,
    Map<int, LevelProgress>? levels,
    Set<String>? completedDailyDates,
    int? dailyStreak,
    String? lastRewardClaimDate,
    Set<String>? claimedRewardDates,
  }) {
    return PlayerProfile(
      highestUnlocked: highestUnlocked ?? this.highestUnlocked,
      coins: coins ?? this.coins,
      hints: hints ?? this.hints,
      soundOn: soundOn ?? this.soundOn,
      musicOn: musicOn ?? this.musicOn,
      hapticsOn: hapticsOn ?? this.hapticsOn,
      autoCrossOn: autoCrossOn ?? this.autoCrossOn,
      removeAds: removeAds ?? this.removeAds,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      tutorialDone: tutorialDone ?? this.tutorialDone,
      levels: levels ?? this.levels,
      completedDailyDates: completedDailyDates ?? this.completedDailyDates,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastRewardClaimDate: lastRewardClaimDate ?? this.lastRewardClaimDate,
      claimedRewardDates: claimedRewardDates ?? this.claimedRewardDates,
    );
  }

  Map<String, dynamic> toJson() => {
        'highestUnlocked': highestUnlocked,
        'coins': coins,
        'hints': hints,
        'soundOn': soundOn,
        'musicOn': musicOn,
        'hapticsOn': hapticsOn,
        'autoCrossOn': autoCrossOn,
        'removeAds': removeAds,
        'onboardingDone': onboardingDone,
        'tutorialDone': tutorialDone,
        'levels': levels.values.map((lp) => lp.toJson()).toList(),
        'completedDailyDates': completedDailyDates.toList(),
        'dailyStreak': dailyStreak,
        'lastRewardClaimDate': lastRewardClaimDate,
        'claimedRewardDates': claimedRewardDates.toList(),
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> j) {
    final levelList = (j['levels'] as List<dynamic>? ?? [])
        .map((e) => LevelProgress.fromJson(e as Map<String, dynamic>));
    return PlayerProfile(
      highestUnlocked: j['highestUnlocked'] as int? ?? 1,
      coins: j['coins'] as int? ?? 50,
      hints: j['hints'] as int? ?? 3,
      soundOn: j['soundOn'] as bool? ?? true,
      musicOn: j['musicOn'] as bool? ?? true,
      hapticsOn: j['hapticsOn'] as bool? ?? true,
      autoCrossOn: j['autoCrossOn'] as bool? ?? true,
      removeAds: j['removeAds'] as bool? ?? false,
      onboardingDone: j['onboardingDone'] as bool? ?? false,
      tutorialDone: j['tutorialDone'] as bool? ?? false,
      levels: {for (final lp in levelList) lp.levelId: lp},
      completedDailyDates:
          (j['completedDailyDates'] as List<dynamic>? ?? []).cast<String>().toSet(),
      dailyStreak: j['dailyStreak'] as int? ?? 0,
      lastRewardClaimDate: j['lastRewardClaimDate'] as String?,
      claimedRewardDates:
          (j['claimedRewardDates'] as List<dynamic>? ?? []).cast<String>().toSet(),
    );
  }
}
