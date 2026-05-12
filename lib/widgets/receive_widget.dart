import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../main.dart' show KiteColors;
import '../services/agent_service.dart';
import '../services/kite_chain_service.dart';

class ReceiveWidget extends StatelessWidget {
  const ReceiveWidget({super.key});

  String? _getAddress(KiteAgentService agent) {
    final wallets = agent.wallets;
    if (wallets.isEmpty) return null;
    final accounts = wallets.first['accounts'] as List?;
    if (accounts == null || accounts.isEmpty) return null;
    return accounts.first['address']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final agent = context.watch<KiteAgentService>();
    final kite = context.watch<KiteChainService>();
    final theme = Theme.of(context);
    final address = _getAddress(agent);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: KiteColors.navy800,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: KiteColors.cyan400.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_downward, color: Colors.green, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receive KITE',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Share your address or QR code',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: KiteColors.grey400)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          if (address == null)
            Center(
              child: Text('Create a wallet first to receive KITE.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: KiteColors.grey400)),
            )
          else ...[
            // QR Code
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: KiteColors.cyan400.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: address,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Network badge
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: kite.useTestnet
                      ? Colors.orange.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: kite.useTestnet
                        ? Colors.orange.withValues(alpha: 0.4)
                        : Colors.green.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${kite.useTestnet ? "Testnet" : "Mainnet"} · Chain ID ${kite.chainId}',
                  style: TextStyle(
                    color: kite.useTestnet ? Colors.orange : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Address display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KiteColors.navy800,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KiteColors.navy700),
              ),
              child: Column(
                children: [
                  Text('Your Kite address',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: KiteColors.grey400)),
                  const SizedBox(height: 8),
                  Text(
                    address,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: KiteColors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: address));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Address copied to clipboard!')),
                          );
                        },
                        icon: const Icon(Icons.copy_outlined, size: 16),
                        label: const Text('Copy'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Share via platform share sheet
                          Clipboard.setData(ClipboardData(text: address));
                        },
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: const Text('Share'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Warning
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Only send KITE tokens on the ${kite.useTestnet ? "Kite Testnet" : "Kite Mainnet"} network to this address.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
