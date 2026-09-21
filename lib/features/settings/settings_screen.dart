import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/billing/billing_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final ctrl = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _section('Gameplay'),
          SwitchListTile(
            title: const Text('Sound'),
            value: profile.soundOn,
            onChanged: ctrl.setSound,
          ),
          SwitchListTile(
            title: const Text('Music'),
            value: profile.musicOn,
            onChanged: ctrl.setMusic,
          ),
          SwitchListTile(
            title: const Text('Haptics'),
            value: profile.hapticsOn,
            onChanged: ctrl.setHaptics,
          ),
          SwitchListTile(
            title: const Text('Auto-Cross'),
            subtitle: const Text('Automatically mark provably-empty cells'),
            value: profile.autoCrossOn,
            onChanged: ctrl.setAutoCross,
          ),
          _section('Purchases'),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Purchases'),
            onTap: () => _restore(context, ref),
          ),
          if (profile.removeAds)
            const ListTile(
              leading: Icon(Icons.verified, color: AppTheme.success),
              title: Text('Ads removed'),
            ),
          _section('About'),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Contact Us'),
            onTap: () => _info(context, 'Contact',
                'Email support@pixelcross.example for help and feedback.'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => _info(context, 'Privacy Policy',
                'This game stores your progress only on this device. See the published policy before release.'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () => _info(context, 'Terms', 'Standard app terms apply.'),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Rate Us'),
            onTap: () => _info(context, 'Rate Us',
                'Opens the store listing in the release build.'),
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share App'),
            onTap: () => _info(context, 'Share',
                'Shares the store link in the release build.'),
          ),
          _section('Danger Zone'),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppTheme.heart),
            title: const Text('Reset Progress',
                style: TextStyle(color: AppTheme.heart)),
            onTap: () => _confirmReset(context, ref),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('Pixel Cross · v1.0.0',
                  style: TextStyle(color: AppTheme.inkSoft)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(title,
            style: const TextStyle(
                color: AppTheme.inkSoft,
                fontWeight: FontWeight.w800,
                fontSize: 13)),
      );

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final outcome = await ref.read(billingServiceProvider).restorePurchases();
    if (!context.mounted) return;
    final msg = switch (outcome) {
      PurchaseOutcome.restored ||
      PurchaseOutcome.alreadyOwned =>
        'Purchases restored.',
      PurchaseOutcome.unavailable =>
        'Billing is not available in this build.',
      _ => 'Nothing to restore.',
    };
    if (outcome == PurchaseOutcome.restored ||
        outcome == PurchaseOutcome.alreadyOwned) {
      ref.read(profileControllerProvider.notifier).setRemoveAds(true);
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _info(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Progress?'),
        content: const Text(
            'This permanently deletes all levels, stars, coins and daily progress on this device. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.heart),
            onPressed: () async {
              await ref.read(profileControllerProvider.notifier).resetProgress();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
