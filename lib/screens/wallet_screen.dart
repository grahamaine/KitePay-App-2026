import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart' show KiteColors;

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: KiteColors.navy900,
      body: _WalletPlaceholder(),
    );
  }
}

class _WalletPlaceholder extends StatelessWidget {
  const _WalletPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KiteColors.navy800,
                border: Border.all(
                    color: KiteColors.cyan400.withValues(alpha: 0.3),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: KiteColors.cyan400.withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 8),
                ],
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  size: 52, color: KiteColors.cyan400),
            ),
            const SizedBox(height: 32),
            Text('Connect Your Wallet',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'WalletConnect support is coming soon. You will be able to link MetaMask, Trust Wallet, and 300+ other wallets to manage your KITE tokens.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: KiteColors.grey400, height: 1.7),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: KiteColors.navy800,
                border: Border.all(
                    color: KiteColors.gold400.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(children: [
                const Icon(Icons.token_rounded,
                    color: KiteColors.gold400, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KitePay Token (KITE)',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: KiteColors.white)),
                      SizedBox(height: 2),
                      Text('0x0105...FF8b',
                          style: TextStyle(
                              fontSize: 11,
                              color: KiteColors.grey400,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(
                        text: '0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b'));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Token address copied!')));
                  },
                  child: const Icon(Icons.copy_rounded,
                      size: 18, color: KiteColors.gold400),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NetworkChip(
                    label: 'KiteAI Testnet', color: KiteColors.cyan400),
                SizedBox(width: 8),
                _NetworkChip(
                    label: 'KiteAI Mainnet', color: KiteColors.cyan500),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkChip extends StatelessWidget {
  final String label;
  final Color color;
  const _NetworkChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
