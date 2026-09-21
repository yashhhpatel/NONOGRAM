/// Ad surface abstraction.
///
/// This is the seam for Google AdMob (`google_mobile_ads`). It is intentionally
/// a no-op today: no plugin, no network, and gameplay never depends on an ad
/// loading. Rewarded ads always report "unavailable" so nothing forces the
/// player to watch one. When AdMob is wired in (Phase 4) only this class
/// changes; call sites stay the same.
///
/// Integration checklist (Phase 4):
///  - add `google_mobile_ads` dependency
///  - set the AdMob App ID in AndroidManifest meta-data
///  - use test ad unit IDs during development
///  - respect [adsRemoved] for banner + interstitial (rewarded stays available)
class AdManager {
  bool adsRemoved;
  AdManager({this.adsRemoved = false});

  bool get bannerAvailable => false;

  Future<void> init() async {}

  /// Shows an interstitial between levels. No-op until AdMob is wired in.
  /// Never shown during active solving. Suppressed when ads are removed.
  Future<void> maybeShowInterstitial() async {
    if (adsRemoved) return;
    // Real implementation loads/shows an interstitial with frequency capping.
  }

  /// Attempts to show a rewarded ad. Returns true only if the reward was
  /// genuinely granted. Today it always returns false (unavailable), which the
  /// UI presents gracefully — rewarded ads are always optional.
  Future<bool> showRewarded() async => false;
}
