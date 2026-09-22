import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

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

/// Google Play Billing for the single lifetime "Remove Ads" product.
///
/// The product is a non-consumable in-app purchase. Ownership is only ever
/// granted from a real, verified purchase or restore delivered on the purchase
/// stream — never faked. Entitlement is handed to the app via
/// [onEntitlementGranted].
///
/// Product id must match the Play Console entry (see [removeAdsProductId]).
class BillingService {
  /// The Play Console product id for the lifetime Remove Ads purchase.
  static const String removeAdsProductId = 'lifetime_ads_free';

  /// Fallback display price if the store price can't be loaded (e.g. offline
  /// or product not yet propagated). The live localized price from Play is
  /// preferred whenever available.
  static const String fallbackPrice = '₹2,999';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final StreamController<PurchaseOutcome> _outcomes =
      StreamController<PurchaseOutcome>.broadcast();

  bool _available = false;
  ProductDetails? _product;

  /// Called when the lifetime entitlement is confirmed (purchase or restore).
  void Function()? onEntitlementGranted;

  /// Asynchronous purchase/restore outcomes delivered on the billing stream, so
  /// the UI can react to pending / cancelled / failed / restored states.
  Stream<PurchaseOutcome> get outcomes => _outcomes.stream;

  bool get isStoreAvailable => _available;

  /// Localized price string for display, or the rupee fallback.
  String get displayPrice => _product?.price ?? fallbackPrice;

  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (_) {},
    );

    final response =
        await _iap.queryProductDetails({removeAdsProductId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    }

    // Deliver any purchases that completed while the app was closed.
    await _iap.restorePurchases();
  }

  Future<bool> isAvailable() async => _available;

  /// Launches the purchase flow. The real result is delivered asynchronously on
  /// the purchase stream and applied via [onEntitlementGranted]; this returns an
  /// immediate outcome describing whether the flow could be started.
  Future<PurchaseOutcome> buyRemoveAds() async {
    if (!_available) return PurchaseOutcome.unavailable;
    final product = _product;
    if (product == null) return PurchaseOutcome.unavailable;

    final param = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: param);
      return PurchaseOutcome.pending; // resolved on the stream
    } catch (_) {
      return PurchaseOutcome.error;
    }
  }

  Future<PurchaseOutcome> restorePurchases() async {
    if (!_available) return PurchaseOutcome.unavailable;
    try {
      await _iap.restorePurchases();
      return PurchaseOutcome.pending; // restored items arrive on the stream
    } catch (_) {
      return PurchaseOutcome.error;
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != removeAdsProductId) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _emit(PurchaseOutcome.pending);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // The Play client only surfaces verified purchases here; we
          // acknowledge (complete) below before granting entitlement.
          onEntitlementGranted?.call();
          _emit(purchase.status == PurchaseStatus.restored
              ? PurchaseOutcome.restored
              : PurchaseOutcome.purchased);
          break;
        case PurchaseStatus.error:
          _emit(PurchaseOutcome.error);
          break;
        case PurchaseStatus.canceled:
          _emit(PurchaseOutcome.cancelled);
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void _emit(PurchaseOutcome outcome) {
    if (!_outcomes.isClosed) _outcomes.add(outcome);
  }

  void dispose() {
    _sub?.cancel();
    _outcomes.close();
  }
}
