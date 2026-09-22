import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/billing/billing_service.dart';

/// Dedicated Lifetime Ads-Free purchase page, opened from Settings → Remove Ads.
///
/// Shows a single non-consumable product. Ownership is only ever granted from a
/// real, verified Google Play purchase or restore delivered on the billing
/// stream (see [BillingService]); nothing is faked. When already owned, the buy
/// button is replaced by a clear "active" state.
class RemoveAdsScreen extends ConsumerStatefulWidget {
  const RemoveAdsScreen({super.key});

  @override
  ConsumerState<RemoveAdsScreen> createState() => _RemoveAdsScreenState();
}

class _RemoveAdsScreenState extends ConsumerState<RemoveAdsScreen> {
  StreamSubscription<PurchaseOutcome>? _sub;
  bool _busy = false;

  static const _benefits = [
    'No banner ads',
    'No interstitial ads',
    'Enjoy the game without interruptions',
    'One-time payment — no subscription',
    'No recurring charges, ever',
    'Stays active permanently after purchase',
  ];

  @override
  void initState() {
    super.initState();
    // React to asynchronous purchase/restore results from Google Play.
    _sub = ref.read(billingServiceProvider).outcomes.listen(_onOutcome);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onOutcome(PurchaseOutcome outcome) {
    if (!mounted) return;
    setState(() => _busy = outcome == PurchaseOutcome.pending);
    final messenger = ScaffoldMessenger.of(context);
    switch (outcome) {
      case PurchaseOutcome.purchased:
        _showActivated();
        break;
      case PurchaseOutcome.restored:
      case PurchaseOutcome.alreadyOwned:
        messenger.showSnackBar(const SnackBar(
            content: Text('Purchase restored — Lifetime Ads-Free is active.')));
        break;
      case PurchaseOutcome.pending:
        messenger.showSnackBar(const SnackBar(
            content: Text('Purchase pending — complete it in Google Play.')));
        break;
      case PurchaseOutcome.cancelled:
        messenger.showSnackBar(
            const SnackBar(content: Text('Purchase cancelled.')));
        break;
      case PurchaseOutcome.error:
        messenger.showSnackBar(const SnackBar(
            content: Text('Purchase failed. Please try again.')));
        break;
      case PurchaseOutcome.unavailable:
        break;
    }
  }

  void _showActivated() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: AppTheme.success, size: 56),
            const SizedBox(height: 12),
            const Text('Lifetime Ads-Free active!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('Thank you — all ads are now removed forever.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.inkSoft)),
          ],
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Great')),
        ],
      ),
    );
  }

  Future<void> _buy() async {
    setState(() => _busy = true);
    final outcome = await ref.read(billingServiceProvider).buyRemoveAds();
    if (!mounted) return;
    if (outcome == PurchaseOutcome.unavailable) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Google Play Billing is unavailable on this device.')));
    }
    // purchased / cancelled / error arrive asynchronously via _onOutcome.
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final outcome = await ref.read(billingServiceProvider).restorePurchases();
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome == PurchaseOutcome.unavailable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Google Play Billing is unavailable on this device.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Checking Google Play for previous purchases…')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final owned = ref.watch(profileControllerProvider.select((p) => p.removeAds));
    final price = ref.watch(billingServiceProvider).displayPrice;

    return Scaffold(
      appBar: AppBar(title: const Text('Remove Ads')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Hero(owned: owned, price: price),
          const SizedBox(height: 20),
          Text('Lifetime Ads-Free',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink)),
          const SizedBox(height: 12),
          for (final b in _benefits) _BenefitRow(text: b),
          const SizedBox(height: 24),
          if (owned)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.success),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppTheme.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lifetime Ads-Free is active on this account. '
                      'Thank you for your support!',
                      style: TextStyle(color: AppTheme.ink),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _buy,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Purchase for $price'),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _restore,
                child: const Text('Restore Purchases'),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Secure payment through Google Play. One-time purchase, '
              'no subscription. Rewarded (optional) ads remain available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final bool owned;
  final String price;
  const _Hero({required this.owned, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(owned ? Icons.verified : Icons.block,
              color: Colors.white, size: 44),
          const SizedBox(height: 12),
          const Text('Lifetime Ads-Free',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            owned ? 'Active' : price,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (!owned) ...[
            const SizedBox(height: 2),
            const Text('One-time payment · no subscription',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;
  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 15, color: AppTheme.ink)),
          ),
        ],
      ),
    );
  }
}
