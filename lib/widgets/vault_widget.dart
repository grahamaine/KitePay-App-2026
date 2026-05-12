import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart' show KiteColors;
import '../services/agent_service.dart';
import '../services/kite_chain_service.dart';

class VaultWidget extends StatefulWidget {
  const VaultWidget({super.key});
  @override
  State<VaultWidget> createState() => _VaultWidgetState();
}

class _VaultWidgetState extends State<VaultWidget> {
  double _balance = 0.0;
  List<Map<String, dynamic>> _txHistory = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final agent = context.read<KiteAgentService>();
    final kite = context.read<KiteChainService>();
    final address = _getAddress(agent);
    if (address != null) {
      final results = await Future.wait([
        kite.getBalance(address),
        kite.getTransactions(address),
      ]);
      if (mounted) {
        setState(() {
          _balance = results[0] as double;
          _txHistory = results[1] as List<Map<String, dynamic>>;
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Balance card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [KiteColors.navy800, KiteColors.navy700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: KiteColors.cyan400.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: KiteColors.cyan400, size: 20),
                    const SizedBox(width: 8),
                    Text('Vault balance',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: KiteColors.grey400)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kite.useTestnet
                            ? Colors.orange.withValues(alpha: 0.15)
                            : Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        kite.useTestnet ? 'Testnet' : 'Mainnet',
                        style: TextStyle(
                          fontSize: 11,
                          color: kite.useTestnet ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _loading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Text(
                        '${_balance.toStringAsFixed(6)} KITE',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: KiteColors.white,
                        ),
                      ),
                const SizedBox(height: 8),
                if (address != null)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: address));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Address copied!')),
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          '${address.substring(0, 10)}...${address.substring(address.length - 8)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: KiteColors.grey400,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy_outlined,
                            size: 14, color: KiteColors.grey400),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (address != null)
                  TextButton.icon(
                    onPressed: () => launchUrl(
                        Uri.parse('${kite.explorerAddressUrl}$address')),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('View on KiteScan'),
                    style: TextButton.styleFrom(
                      foregroundColor: KiteColors.cyan400,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Network toggle
          Row(
            children: [
              Text('Network',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: KiteColors.grey400)),
              const Spacer(),
              Switch(
                value: !kite.useTestnet,
                onChanged: (mainnet) => kite.switchNetwork(testnet: !mainnet),
                activeThumbColor: KiteColors.cyan400,
              ),
              Text(kite.useTestnet ? 'Testnet' : 'Mainnet',
                  style: theme.textTheme.bodySmall),
            ],
          ),

          const SizedBox(height: 24),

          // Transaction history
          Text('Recent transactions',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_txHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: KiteColors.navy800,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 40, color: KiteColors.grey400),
                  const SizedBox(height: 12),
                  Text('No transactions yet',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: KiteColors.grey400)),
                ],
              ),
            )
          else
            ...(_txHistory.take(10).map((tx) => _TxTile(
                  tx: tx,
                  explorerUrl: kite.explorerTxUrl,
                ))),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final String explorerUrl;
  const _TxTile({required this.tx, required this.explorerUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hash = tx['hash']?.toString() ?? '';
    final value = tx['value']?.toString() ?? '0';
    final kiteValue = (double.tryParse(value) ?? 0) / 1e18;
    final isIn = (tx['to']?.toString().toLowerCase() ?? '') ==
        (tx['from']?.toString().toLowerCase() ?? 'x');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isIn ? Colors.green : KiteColors.cyan400)
              .withValues(alpha: 0.15),
          child: Icon(
            isIn ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIn ? Colors.green : KiteColors.cyan400,
            size: 18,
          ),
        ),
        title: Text(
          hash.length > 16
              ? '${hash.substring(0, 8)}...${hash.substring(hash.length - 6)}'
              : hash,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
        subtitle: Text(
          '${kiteValue.toStringAsFixed(6)} KITE',
          style: theme.textTheme.bodySmall?.copyWith(color: KiteColors.grey400),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new, size: 16),
          onPressed: () => launchUrl(Uri.parse('$explorerUrl$hash')),
        ),
      ),
    );
  }
}
