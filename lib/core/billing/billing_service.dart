/// Result of a purchase or restore attempt.
enum PurchaseOutcome {
  purchased,
  restored,
  alreadyOwned,
  pending,
  cancelled,
  unavailable,
  error,
}

/// Google Play Billing abstraction for the lifetime "Remove Ads" product.
///
/// This is the seam for `in_app_purchase`. It never fakes a successful
/// purchase: the stub reports [PurchaseOutcome.unavailable] because no billing
/// client is connected yet. Ownership is only ever granted from a real,
/// verified purchase or restore. When billing is wired in (Phase 4), only this
/// class changes.
///
/// Product id: `remove_ads` (non-consumable / lifetime).
class BillingService {
  static const String removeAdsProductId = 'remove_ads';

  Future<void> init() async {}

  Future<bool> isAvailable() async => false;

  /// Launches the purchase flow for Remove Ads. Returns the real outcome; the
  /// caller only grants entitlement on [PurchaseOutcome.purchased] /
  /// [PurchaseOutcome.restored] / [PurchaseOutcome.alreadyOwned].
  Future<PurchaseOutcome> buyRemoveAds() async => PurchaseOutcome.unavailable;

  Future<PurchaseOutcome> restorePurchases() async =>
      PurchaseOutcome.unavailable;

  void dispose() {}
}
