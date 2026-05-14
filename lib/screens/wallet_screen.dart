import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart' show KiteColors;
import '../services/kite_chain_service.dart';
import '../services/wallet_connect_service.dart';
import '../widgets/pay_widget.dart';
import '../widgets/receive_widget.dart';
import '../widgets/send_widget.dart';
import '../widgets/vault_widget.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    context.read<KiteChainService>().initialize();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiteColors.navy900,
      appBar: AppBar(
        title: const Text('Wallet'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: KiteColors.cyan400,
          labelColor: KiteColors.cyan400,
          unselectedLabelColor: KiteColors.grey400,
          tabs: const [
            Tab(icon: Icon(Icons.lock_outline), text: 'Vault'),
            Tab(icon: Icon(Icons.arrow_upward), text: 'Send'),
            Tab(icon: Icon(Icons.arrow_downward), text: 'Receive'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Pay'),
            Tab(
                icon: Icon(Icons.account_balance_wallet_outlined),
                text: 'Connect'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          VaultWidget(),
          SendWidget(),
          ReceiveWidget(),
          PayWidget(),
          _WalletConnectTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connect tab
// ─────────────────────────────────────────────────────────────────────────────
class _WalletConnectTab extends StatefulWidget {
  const _WalletConnectTab();

  @override
  State<_WalletConnectTab> createState() => _WalletConnectTabState();
}

class _WalletConnectTabState extends State<_WalletConnectTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WalletConnectService>().init(context);
      }
    });
  }

  String _shortenAddress(String address) {
    if (address.length <= 14) return address;
    return '${address.substring(0, 8)}…${address.substring(address.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletConnectService>(
      builder: (context, service, _) {
        if (service.isConnected) {
          return _buildConnectedState(context, service);
        }
        return _buildDisconnectedState(context, service);
      },
    );
  }

  Widget _buildDisconnectedState(
      BuildContext context, WalletConnectService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KiteColors.navy800,
                border: Border.all(
                    color: KiteColors.cyan400.withValues(alpha: 0.3),
                    width: 1.5),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 44,
                color: KiteColors.cyan400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connect External Wallet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: KiteColors.white,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Link MetaMask, Trust Wallet, Rainbow, or any WalletConnect-compatible wallet to interact with KitePay.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: KiteColors.grey400,
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: KiteColors.cyan400,
                foregroundColor: KiteColors.navy900,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3),
              ),
              onPressed: () => service.openModal(context),
              child: const Text('Connect Wallet'),
            ),
            const SizedBox(height: 16),
            Text(
              'Supported: MetaMask · Trust · Rainbow',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: KiteColors.grey600,
                    fontSize: 12,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedState(
      BuildContext context, WalletConnectService service) {
    final address = service.connectedAddress ?? '';
    final networkName =
        service.modal?.selectedChain?.name ?? 'Kite Network';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KiteColors.success.withValues(alpha: 0.1),
                border: Border.all(
                    color: KiteColors.success.withValues(alpha: 0.4),
                    width: 1.5),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: KiteColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Wallet Connected',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: KiteColors.white,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: KiteColors.navy800,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: KiteColors.navy700, width: 1),
              ),
              child: Text(
                _shortenAddress(address),
                style: const TextStyle(
                  color: KiteColors.cyan400,
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              networkName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: KiteColors.grey400,
                  ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: KiteColors.error,
                side: const BorderSide(color: KiteColors.error, width: 1.5),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              onPressed: () => service.disconnect(),
              child: const Text('Disconnect'),
            ),
          ],
        ),
      ),
    );
  }
}
