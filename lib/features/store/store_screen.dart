import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';

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
          _sectionTitle('Coin Packs'),
          const _CoinPackTile(title: 'Handful of Coins', coins: 500),
          const _CoinPackTile(title: 'Bag of Coins', coins: 1500),
          const _CoinPackTile(title: 'Chest of Coins', coins: 5000),
          const Padding(
            padding: EdgeInsets.only(top: 8),
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
