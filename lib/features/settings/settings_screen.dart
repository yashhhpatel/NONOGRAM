import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';

const String _privacyPolicyUrl =
    'https://api.buildprivacypolicy.com/policy/62e76d2f-5b52-4b4f-928b-273e3098f3c1';

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
          SwitchListTile(
            title: const Text('Daily Reminder'),
            subtitle: const Text('A gentle daily nudge to keep your streak'),
            value: profile.dailyReminderOn,
            onChanged: (v) => _toggleReminder(context, ref, v),
          ),
          _section('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                    value: 0,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto)),
                ButtonSegment(
                    value: 1,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode)),
                ButtonSegment(
                    value: 2,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode)),
              ],
              selected: {profile.themeModeIndex},
              showSelectedIcon: false,
              onSelectionChanged: (s) => ctrl.setThemeMode(s.first),
            ),
          ),
          _section('Purchases'),
          ListTile(
            leading: Icon(
              profile.removeAds ? Icons.verified : Icons.block,
              color: profile.removeAds ? AppTheme.success : AppTheme.primary,
            ),
            title: const Text('Remove Ads'),
            subtitle: Text(profile.removeAds
                ? 'Lifetime Ads-Free is active'
                : 'Lifetime Ads-Free — one-time purchase'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/remove-ads'),
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
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(context, _privacyPolicyUrl),
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
          Padding(
            padding: const EdgeInsets.all(16),
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
            style: TextStyle(
                color: AppTheme.inkSoft,
                fontWeight: FontWeight.w800,
                fontSize: 13)),
      );

  Future<void> _toggleReminder(
    BuildContext context,
    WidgetRef ref,
    bool on,
  ) async {
    final notifications = ref.read(notificationServiceProvider);
    if (on) {
      final granted = await notifications.requestPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Enable notifications in system settings.')),
          );
        }
        return;
      }
      await notifications.scheduleDailyReminder();
      await notifications.showNow(
          'Reminders on', 'We\'ll nudge you daily to keep your streak.');
    } else {
      await notifications.cancelAll();
    }
    ref.read(profileControllerProvider.notifier).setDailyReminder(on);
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
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
