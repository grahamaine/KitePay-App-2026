import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../main.dart' show KiteColors;
import '../services/agent_service.dart';
import '../services/kite_chain_service.dart';

class PayWidget extends StatefulWidget {
  const PayWidget({super.key});
  @override
  State<PayWidget> createState() => _PayWidgetState();
}

class _PayWidgetState extends State<PayWidget> {
  final MobileScannerController _scannerCtrl = MobileScannerController();
  bool _scanning = false;
  bool _paying = false;
  String? _scannedAddress;
  String? _txHash;
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    final raw = barcode!.rawValue!.trim();

    // Parse ethereum: URI or plain address
    String address = raw;
    double? amount;
    if (raw.startsWith('ethereum:')) {
      final uri = raw.replaceFirst('ethereum:', '');
      final parts = uri.split('?');
      address = parts[0];
      if (parts.length > 1) {
        final params = Uri.splitQueryString(parts[1]);
        amount = double.tryParse(params['value'] ?? '');
      }
    }

    final kite = context.read<KiteChainService>();
    if (!kite.isValidAddress(address)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR — not a Kite/EVM address.')),
      );
      return;
    }

    setState(() {
      _scanning = false;
      _scannedAddress = address;
      if (amount != null) _amountCtrl.text = amount.toString();
    });
    _scannerCtrl.stop();
  }

  Future<void> _handlePay() async {
    if (_scannedAddress == null) return;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount.')),
      );
      return;
    }

    final agent = context.read<KiteAgentService>();
    final kite = context.read<KiteChainService>();

    final wallets = agent.wallets;
    if (wallets.isEmpty) return;
    final accounts = wallets.first['accounts'] as List?;
    final privateKey = accounts?.first['privateKey']?.toString();
    if (privateKey == null) return;

    setState(() => _paying = true);

    final txHash = await kite.sendKite(
      privateKeyHex: privateKey,
      toAddress: _scannedAddress!,
      amountKite: amount,
      memo: 'QR Pay',
    );

    if (!mounted) return;
    setState(() => _paying = false);

    if (txHash != null) {
      setState(() => _txHash = txHash);
      _showSuccessSheet(txHash, amount);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kite.lastError ?? 'Payment failed.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showSuccessSheet(String txHash, double amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KiteColors.navy800,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('Payment sent!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$amount KITE sent on Kite chain',
                style: const TextStyle(color: KiteColors.grey400)),
            const SizedBox(height: 12),
            Text(
              'Tx: ${txHash.substring(0, 12)}...${txHash.substring(txHash.length - 8)}',
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: KiteColors.cyan400),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _scannedAddress = null;
                  _txHash = null;
                  _amountCtrl.clear();
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: KiteColors.cyan400,
                foregroundColor: KiteColors.navy900,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                const Icon(Icons.qr_code_scanner,
                    color: KiteColors.cyan400, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pay',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Scan QR to pay on Kite chain',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: KiteColors.grey400)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Scanner
          if (_scanning)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 280,
                child: MobileScanner(
                  controller: _scannerCtrl,
                  onDetect: _onDetect,
                ),
              ),
            )
          else if (_scannedAddress == null)
            GestureDetector(
              onTap: () => setState(() => _scanning = true),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: KiteColors.navy800,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: KiteColors.cyan400.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner,
                        size: 56, color: KiteColors.cyan400),
                    const SizedBox(height: 12),
                    Text('Tap to scan QR code',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: KiteColors.grey400)),
                    const SizedBox(height: 4),
                    Text('Supports ethereum: URIs',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: KiteColors.grey600)),
                  ],
                ),
              ),
            )
          else ...[
            // Scanned address confirmation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text('Address scanned',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.green)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          _scannedAddress = null;
                          _scanning = false;
                        }),
                        child: const Text('Rescan'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _scannedAddress!,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: KiteColors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (KITE)',
                prefixIcon: Icon(Icons.toll_outlined),
                suffixText: 'KITE',
              ),
            ),
            const SizedBox(height: 24),

            // Pay button
            FilledButton.icon(
              onPressed: _paying ? null : _handlePay,
              icon: _paying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(KiteColors.navy900),
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_paying ? 'Processing...' : 'Pay Now'),
              style: FilledButton.styleFrom(
                backgroundColor: KiteColors.cyan400,
                foregroundColor: KiteColors.navy900,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
