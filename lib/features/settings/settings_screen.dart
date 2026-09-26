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
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _section('Gameplay'),
          _ToggleCard(
            iconOn: Icons.volume_up,
            iconOff: Icons.volume_off,
            title: 'Sound',
            subtitle: 'Tap and completion sounds',
            value: profile.soundOn,
            pulseWhenOn: true,
            onChanged: ctrl.setSound,
          ),
          _ToggleCard(
            iconOn: Icons.music_note,
            iconOff: Icons.music_off,
            title: 'Music',
            value: profile.musicOn,
            onChanged: ctrl.setMusic,
          ),
          _ToggleCard(
            iconOn: Icons.vibration,
            iconOff: Icons.smartphone,
            title: 'Vibration',
            subtitle: 'Haptic feedback',
            value: profile.hapticsOn,
            pulseWhenOn: true,
            onChanged: ctrl.setHaptics,
          ),
          _ToggleCard(
            iconOn: Icons.grid_on,
            iconOff: Icons.grid_off,
            title: 'Auto-Cross',
            subtitle: 'Automatically mark provably-empty cells',
            value: profile.autoCrossOn,
            onChanged: ctrl.setAutoCross,
          ),
          _ToggleCard(
            iconOn: Icons.notifications_active,
            iconOff: Icons.notifications_off,
            title: 'Daily Reminder',
            subtitle: 'A gentle daily nudge to keep your streak',
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
          _ActionCard(
            icon: profile.removeAds ? Icons.verified : Icons.block,
            iconColor: profile.removeAds ? AppTheme.success : AppTheme.primary,
            title: 'Remove Ads',
            subtitle: profile.removeAds
                ? 'Lifetime Ads-Free is active'
                : 'Lifetime Ads-Free — one-time purchase',
            onTap: () => context.push('/remove-ads'),
          ),
          _section('About'),
          _ActionCard(
            icon: Icons.star_outline,
            title: 'Rate Us',
            onTap: () => _info(context, 'Rate Us',
                'Opens the store listing in the release build.'),
          ),
          _ActionCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(context, _privacyPolicyUrl),
          ),
          _ActionCard(
            icon: Icons.mail_outline,
            title: 'Contact Us',
            onTap: () => _info(context, 'Contact',
                'Email support@pixelcross.example for help and feedback.'),
          ),
          _ActionCard(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _info(context, 'Terms', 'Standard app terms apply.'),
          ),
          _ActionCard(
            icon: Icons.share_outlined,
            title: 'Share App',
            onTap: () => _info(context, 'Share',
                'Shares the store link in the release build.'),
          ),
          _section('Danger Zone'),
          _ActionCard(
            icon: Icons.delete_outline,
            iconColor: AppTheme.heart,
            title: 'Reset Progress',
            titleColor: AppTheme.heart,
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
        padding: const EdgeInsets.fromLTRB(20, 22, 16, 8),
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

/// A rounded settings card whose whole appearance animates between ON and OFF.
/// Optional [pulseWhenOn] gives the icon a subtle looping pulse while active.
class _ToggleCard extends StatefulWidget {
  final IconData iconOn;
  final IconData iconOff;
  final String title;
  final String? subtitle;
  final bool value;
  final bool pulseWhenOn;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.iconOn,
    required this.iconOff,
    required this.title,
    this.subtitle,
    required this.value,
    this.pulseWhenOn = false,
    required this.onChanged,
  });

  @override
  State<_ToggleCard> createState() => _ToggleCardState();
}

class _ToggleCardState extends State<_ToggleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool get _shouldPulse =>
      widget.pulseWhenOn &&
      widget.value &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _ToggleCard old) {
    super.didUpdateWidget(old);
    _syncPulse();
  }

  void _syncPulse() {
    if (_shouldPulse) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      if (_pulse.isAnimating) _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        onTap: () => widget.onChanged(!on),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: on ? AppTheme.primary.withOpacity(0.10) : AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: on ? AppTheme.primary : AppTheme.line,
              width: on ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: on
                      ? AppTheme.primary.withOpacity(0.16)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.18).animate(
                      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                  child: Icon(
                    on ? widget.iconOn : widget.iconOff,
                    color: on ? AppTheme.primary : AppTheme.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.ink)),
                    if (widget.subtitle != null)
                      Text(widget.subtitle!,
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.inkSoft)),
                  ],
                ),
              ),
              Switch(value: on, onChanged: widget.onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// A rounded, tappable settings card for actions (links, purchase, reset).
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.line),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.primary).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor ?? AppTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: titleColor ?? AppTheme.ink)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.inkSoft)),
                  ],
                ),
              ),
              trailing ??
                  Icon(Icons.chevron_right, color: AppTheme.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}
