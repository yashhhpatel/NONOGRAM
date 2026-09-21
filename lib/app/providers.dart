import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ads/ad_manager.dart';
import '../core/audio/audio_service.dart';
import '../core/billing/billing_service.dart';
import '../core/haptics/haptics_service.dart';
import '../core/storage/storage_service.dart';
import '../game/data/puzzle_repository.dart';
import '../game/models/level_progress.dart';
import '../game/models/player_profile.dart';

/// Overridden in `main` with the initialised instance.
final storageServiceProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError('storageServiceProvider not overridden'),
);

final audioServiceProvider = Provider<AudioService>((ref) => const AudioService());
final hapticsServiceProvider =
    Provider<HapticsService>((ref) => const HapticsService());
final puzzleRepositoryProvider =
    Provider<PuzzleRepository>((ref) => PuzzleRepository());

final adManagerProvider = Provider<AdManager>((ref) {
  final profile = ref.watch(profileControllerProvider);
  final manager = AdManager(adsRemoved: profile.removeAds);
  return manager;
});

final billingServiceProvider = Provider<BillingService>((ref) {
  final service = BillingService();
  // A verified purchase or restore grants the lifetime entitlement.
  service.onEntitlementGranted = () {
    ref.read(profileControllerProvider.notifier).setRemoveAds(true);
  };
  ref.onDispose(service.dispose);
  // Fire-and-forget init: connects the store and delivers any owned purchase.
  service.init();
  return service;
});

final profileControllerProvider =
    StateNotifierProvider<ProfileController, PlayerProfile>((ref) {
  return ProfileController(ref.watch(storageServiceProvider));
});

/// Owns the persisted [PlayerProfile] and writes through to storage on change.
class ProfileController extends StateNotifier<PlayerProfile> {
  final StorageService _storage;
  ProfileController(this._storage) : super(_storage.load());

  void _commit(PlayerProfile next) {
    state = next;
    _storage.save(next);
  }

  void completeOnboarding() =>
      _commit(state.copyWith(onboardingDone: true));

  void addCoins(int amount) =>
      _commit(state.copyWith(coins: state.coins + amount));

  bool spendCoins(int amount) {
    if (state.coins < amount) return false;
    _commit(state.copyWith(coins: state.coins - amount));
    return true;
  }

  void addHints(int amount) =>
      _commit(state.copyWith(hints: state.hints + amount));

  bool consumeHint() {
    if (state.hints <= 0) return false;
    _commit(state.copyWith(hints: state.hints - 1));
    return true;
  }

  void setSound(bool v) => _commit(state.copyWith(soundOn: v));
  void setMusic(bool v) => _commit(state.copyWith(musicOn: v));
  void setHaptics(bool v) => _commit(state.copyWith(hapticsOn: v));
  void setAutoCross(bool v) => _commit(state.copyWith(autoCrossOn: v));
  void setRemoveAds(bool v) => _commit(state.copyWith(removeAds: v));

  /// Records a completed level result, awarding coins and unlocking the next
  /// level. Returns the coins awarded.
  void recordLevelResult({
    required int levelId,
    required int stars,
    required int timeSeconds,
    required int mistakes,
    required int hintsUsed,
    required int coinsAwarded,
    required int totalLevels,
  }) {
    final existing = state.levels[levelId] ??
        LevelProgress(levelId: levelId);
    final merged = existing.mergeBest(
      stars: stars,
      timeSeconds: timeSeconds,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
    );
    final levels = Map<int, LevelProgress>.of(state.levels)
      ..[levelId] = merged;

    final nextUnlock = (levelId + 1) <= totalLevels
        ? (levelId + 1)
        : state.highestUnlocked;
    final highestUnlocked = nextUnlock > state.highestUnlocked
        ? nextUnlock
        : state.highestUnlocked;

    _commit(state.copyWith(
      levels: levels,
      highestUnlocked: highestUnlocked,
      coins: state.coins + coinsAwarded,
    ));
  }

  void markDailyComplete(String date, {int coinReward = 30}) {
    if (state.completedDailyDates.contains(date)) return;
    final dates = Set<String>.of(state.completedDailyDates)..add(date);
    _commit(state.copyWith(
      completedDailyDates: dates,
      coins: state.coins + coinReward,
    ));
  }

  /// Claims a daily reward for [today]. Handles same-day (no-op), consecutive
  /// day (streak++), and missed day (streak reset). Returns the coins granted,
  /// or null if already claimed today.
  int? claimDailyReward(String today, String? yesterday) {
    if (state.lastRewardClaimDate == today) return null;

    final continued = state.lastRewardClaimDate == yesterday;
    final newStreak = continued ? state.dailyStreak + 1 : 1;

    // 7-day cycle rewards.
    const cycle = [20, 25, 30, 40, 50, 60, 120];
    final reward = cycle[(newStreak - 1) % cycle.length];

    final claimed = Set<String>.of(state.claimedRewardDates)..add(today);
    _commit(state.copyWith(
      dailyStreak: newStreak,
      lastRewardClaimDate: today,
      claimedRewardDates: claimed,
      coins: state.coins + reward,
    ));
    return reward;
  }

  Future<void> resetProgress() async {
    await _storage.clear();
    state = PlayerProfile.fresh().copyWith(onboardingDone: true);
    await _storage.save(state);
  }
}
