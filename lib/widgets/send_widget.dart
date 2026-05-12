import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart' show KiteColors;
import '../services/agent_service.dart';
import '../services/kite_chain_service.dart';

class SendWidget extends StatefulWidget {
  const SendWidget({super.key});
  @override
  State<SendWidget> createState() => _SendWidgetState();
}

class _SendWidgetState extends State<SendWidget> {
  final _formKey = GlobalKey<FormState>();
  final _toCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  bool _sending = false;
  double _estimatedGas = 0.0;

  @override
  void initState() {
    super.initState();
    _loadGasEstimate();
  }

  @override
  void dispose() {
    _toCtrl.dispose();
    _amountCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGasEstimate() async {
    final gas = await context.read<KiteChainService>().estimateTransferGas();
    if (mounted) setState(() => _estimatedGas = gas);
  }

  Future<void> _handleSend() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final kite = context.read<KiteChainService>();
    final agent = context.read<KiteAgentService>();

    final wallets = agent.wallets;
    if (wallets.isEmpty) {
      _showError('No wallet found. Create one first.');
      return;
    }

    final accounts = wallets.first['accounts'] as List?;
    final privateKey = accounts?.first['privateKey']?.toString();
    if (privateKey == null) {
      _showError('Wallet private key unavailable.');
      return;
    }

    setState(() => _sending = true);

    final txHash = await kite.sendKite(
      privateKeyHex: privateKey,
      toAddress: _toCtrl.text.trim(),
      amountKite: double.parse(_amountCtrl.text.trim()),
      memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _sending = false);

    if (txHash != null) {
      _showSuccess(txHash);
    } else {
      _showError(kite.lastError ?? 'Transaction failed.');
    }
  }

  void _showSuccess(String txHash) {
    final kite = context.read<KiteChainService>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: KiteColors.navy800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Sent!'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaction confirmed on Kite chain.'),
            const SizedBox(height: 12),
            Text(
              'Tx: ${txHash.substring(0, 18)}...',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'View on KiteScan: ${kite.explorerTxUrl}$txHash',
              style: const TextStyle(color: KiteColors.cyan400, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toCtrl.clear();
              _amountCtrl.clear();
              _memoCtrl.clear();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kite = context.watch<KiteChainService>();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KiteColors.navy800,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: KiteColors.cyan400.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_upward,
                      color: KiteColors.cyan400, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Send KITE',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Transfer to any Kite address',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: KiteColors.grey400)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // To address
            TextFormField(
              controller: _toCtrl,
              decoration: const InputDecoration(
                labelText: 'To address (0x...)',
                prefixIcon: Icon(Icons.account_circle_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter recipient address';
                }
                if (!kite.isValidAddress(v.trim())) {
                  return 'Invalid Ethereum/Kite address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (KITE)',
                prefixIcon: Icon(Icons.toll_outlined),
                suffixText: 'KITE',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter amount';
                final amount = double.tryParse(v.trim());
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Memo
            TextFormField(
              controller: _memoCtrl,
              decoration: const InputDecoration(
                labelText: 'Memo (optional)',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Gas estimate
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KiteColors.navy800.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_gas_station_outlined,
                      size: 16, color: KiteColors.grey400),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated gas: ~${_estimatedGas.toStringAsFixed(6)} KITE',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: KiteColors.grey400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Send button
            FilledButton.icon(
              onPressed: _sending ? null : _handleSend,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(KiteColors.navy900),
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_sending ? 'Sending...' : 'Send KITE'),
              style: FilledButton.styleFrom(
                backgroundColor: KiteColors.cyan400,
                foregroundColor: KiteColors.navy900,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
