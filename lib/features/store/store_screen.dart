import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../game/models/board_theme.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final ctrl = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  Text('${profile.coins}',
                      style:
                          const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Spend Coins'),
          _CoinSpendTile(
            icon: Icons.lightbulb,
            title: '5 Hints',
            cost: 60,
            onBuy: () {
              if (ctrl.spendCoins(60)) {
                ctrl.addHints(5);
                _toast(context, '5 hints added!');
              } else {
                _toast(context, 'Not enough coins.');
              }
            },
          ),
          _CoinSpendTile(
            icon: Icons.lightbulb,
            title: '15 Hints',
            cost: 150,
            onBuy: () {
              if (ctrl.spendCoins(150)) {
                ctrl.addHints(15);
                _toast(context, '15 hints added!');
              } else {
                _toast(context, 'Not enough coins.');
              }
            },
          ),
          const SizedBox(height: 20),
          _sectionTitle('Board Themes'),
          _ThemeGrid(
            owned: profile.ownedThemes,
            selected: profile.selectedTheme,
            onTap: (theme) {
              if (profile.ownedThemes.contains(theme.id)) {
                ctrl.selectTheme(theme.id);
                _toast(context, '${theme.name} applied!');
              } else if (ctrl.buyTheme(theme.id, theme.cost)) {
                _toast(context, '${theme.name} unlocked & applied!');
              } else {
                _toast(context, 'Not enough coins.');
              }
            },
          ),
          const SizedBox(height: 20),
          _sectionTitle('Coin Packs'),
          const _CoinPackTile(title: 'Handful of Coins', coins: 500),
          const _CoinPackTile(title: 'Bag of Coins', coins: 1500),
          const _CoinPackTile(title: 'Chest of Coins', coins: 5000),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Coin packs require Google Play Billing, wired up in the release build.',
              style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      );

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _ThemeGrid extends StatelessWidget {
  final Set<String> owned;
  final String selected;
  final ValueChanged<BoardTheme> onTap;
  const _ThemeGrid({
    required this.owned,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.82,
      children: [
        for (final t in BoardThemes.all)
          _ThemeSwatch(
            theme: t,
            owned: owned.contains(t.id),
            selected: selected == t.id,
            onTap: () => onTap(t),
          ),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final BoardTheme theme;
  final bool owned;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeSwatch({
    required this.theme,
    required this.owned,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.line,
            width: selected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.swatch,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            const SizedBox(height: 6),
            Text(theme.name,
                style: TextStyle(fontSize: 11, color: AppTheme.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            if (selected)
              const Icon(Icons.check_circle, size: 15, color: AppTheme.primary)
            else if (owned)
              Text('Owned',
                  style: TextStyle(fontSize: 10, color: AppTheme.inkSoft))
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on,
                      size: 12, color: AppTheme.accent),
                  const SizedBox(width: 2),
                  Text('${theme.cost}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CoinSpendTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int cost;
  final VoidCallback onBuy;
  const _CoinSpendTile({
    required this.icon,
    required this.title,
    required this.cost,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title),
        trailing: FilledButton(
          onPressed: onBuy,
          child: Text('$cost'),
        ),
      ),
    );
  }
}

class _CoinPackTile extends StatelessWidget {
  final String title;
  final int coins;
  const _CoinPackTile({required this.title, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: ListTile(
        leading: const Icon(Icons.monetization_on, color: AppTheme.accent),
        title: Text(title),
        subtitle: Text('$coins coins'),
        trailing: const Chip(label: Text('Store')),
      ),
    );
  }
}
