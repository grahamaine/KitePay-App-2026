import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

import '../main.dart' show KiteColors, KiteWalletProvider, KiteAnalytics;

// ─────────────────────────────────────────────────────────────────────────────
// KitePayToken constants
// ─────────────────────────────────────────────────────────────────────────────
const _kiteTokenAddress = '0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b';
const _kiteTestnetRpc = 'https://rpc-testnet.gokite.ai/';
const _kiteMainnetRpc = 'https://rpc.gokite.ai/';

const _erc20Abi = '''[
  {"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"type":"function"},
  {"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"type":"function"},
  {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},
  {"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"type":"function"}
]''';

// ─────────────────────────────────────────────────────────────────────────────
// Balance service
// ─────────────────────────────────────────────────────────────────────────────
class KiteBalanceService {
  static Future<Map<String, String>> fetchBalances(
      String address, String chainId) async {
    if (kIsWeb) return {'native': 'Connect app', 'kite': 'Connect app'};
    try {
      final rpc = chainId == '2366' ? _kiteMainnetRpc : _kiteTestnetRpc;
      final client = Web3Client(rpc, http.Client());
      final ethAddr = EthereumAddress.fromHex(address);

      final nativeBal = await client.getBalance(ethAddr);
      final nativeKite =
          nativeBal.getValueInUnit(EtherUnit.ether).toStringAsFixed(4);

      final contract = DeployedContract(
        ContractAbi.fromJson(_erc20Abi, 'KitePayToken'),
        EthereumAddress.fromHex(_kiteTokenAddress),
      );
      final result = await client.call(
          contract: contract,
          function: contract.function('balanceOf'),
          params: [ethAddr]);
      final tokenRaw = result[0] as BigInt;
      final tokenBal = (tokenRaw / BigInt.from(10).pow(18)).toStringAsFixed(2);

      await client.dispose();
      return {'native': nativeKite, 'kite': tokenBal};
    } catch (e) {
      debugPrint('Balance fetch error: $e');
      return {'native': '--', 'kite': '--'};
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wallet Screen
// ─────────────────────────────────────────────────────────────────────────────
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        final wallet = context.read<KiteWalletProvider>();
        if (!wallet.isConnected) wallet.init(context);
      }
      KiteAnalytics.logScreenView('wallet_screen');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<KiteWalletProvider>();

    // On web, WalletConnect is not supported — show placeholder
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: KiteColors.navy900,
        appBar: AppBar(title: const Text('Wallet')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 64, color: KiteColors.cyan400),
                const SizedBox(height: 24),
                Text('WalletConnect',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Text(
                  'WalletConnect is available on the mobile app. Use the KitePay mobile app to connect your wallet.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: KiteColors.grey400, height: 1.7),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KiteColors.navy900,
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          if (wallet.isConnected)
            IconButton(
              icon: const Icon(Icons.logout_rounded, size: 20),
              tooltip: 'Disconnect',
              onPressed: () => _confirmDisconnect(context, wallet),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: wallet.isConnected
            ? _ConnectedView(wallet: wallet)
            : _DisconnectedView(wallet: wallet),
      ),
    );
  }

  Future<void> _confirmDisconnect(
      BuildContext context, KiteWalletProvider wallet) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: KiteColors.navy800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disconnect Wallet',
            style: TextStyle(color: KiteColors.white)),
        content: const Text('Disconnect your connected wallet?',
            style: TextStyle(color: KiteColors.grey400)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: KiteColors.error,
                foregroundColor: KiteColors.white),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (ok == true) await wallet.disconnect();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Disconnected
// ─────────────────────────────────────────────────────────────────────────────
class _DisconnectedView extends StatelessWidget {
  final KiteWalletProvider wallet;
  const _DisconnectedView({required this.wallet});

  @override
  Widget build(BuildContext context) {
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
                      spreadRadius: 8)
                ],
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  size: 52, color: KiteColors.cyan400),
            ),
            const SizedBox(height: 32),
            Text('Connect Your Wallet',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Link MetaMask, Trust Wallet, or any WalletConnect wallet to manage your KITE tokens.',
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => wallet.openModal(context),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Connect Wallet'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Supports 300+ wallets',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WalletChip(label: 'MetaMask', color: Color(0xFFE2761B)),
                SizedBox(width: 8),
                _WalletChip(label: 'Trust', color: Color(0xFF3375BB)),
                SizedBox(width: 8),
                _WalletChip(label: 'Coinbase', color: Color(0xFF0052FF)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  final String label;
  final Color color;
  const _WalletChip({required this.label, required this.color});

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

// ─────────────────────────────────────────────────────────────────────────────
// Connected
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectedView extends StatefulWidget {
  final KiteWalletProvider wallet;
  const _ConnectedView({required this.wallet});

  @override
  State<_ConnectedView> createState() => _ConnectedViewState();
}

class _ConnectedViewState extends State<_ConnectedView> {
  Map<String, String> _bal = {'native': '...', 'kite': '...'};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.wallet.address == null) return;
    setState(() => _loading = true);
    final b = await KiteBalanceService.fetchBalances(
        widget.wallet.address!, widget.wallet.chainId ?? '2368');
    if (mounted) {
      setState(() {
        _bal = b;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: KiteColors.cyan400,
      backgroundColor: KiteColors.navy800,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _BalanceCard(
              wallet: widget.wallet,
              bal: _bal,
              loading: _loading,
              onRefresh: _load),
          const SizedBox(height: 20),
          _QuickActions(wallet: widget.wallet),
          const SizedBox(height: 28),
          _NetworkBadge(chainId: widget.wallet.chainId),
          const SizedBox(height: 28),
          _KiteTokenCard(kiteBalance: _bal['kite'] ?? '--'),
          const SizedBox(height: 28),
          Text('Recent Activity',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const _ActivityList(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance card
// ─────────────────────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final KiteWalletProvider wallet;
  final Map<String, String> bal;
  final bool loading;
  final VoidCallback onRefresh;
  const _BalanceCard(
      {required this.wallet,
      required this.bal,
      required this.loading,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [KiteColors.navy700, KiteColors.navy600]),
        border: Border.all(
            color: KiteColors.cyan400.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
              color: KiteColors.cyan400.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 8))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KiteColors.success,
                    boxShadow: [
                      BoxShadow(
                          color: KiteColors.success.withValues(alpha: 0.5),
                          blurRadius: 6)
                    ])),
            const SizedBox(width: 8),
            Text(wallet.displayAddress,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: KiteColors.grey400,
                    letterSpacing: 0.5)),
            const Spacer(),
            GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: wallet.address ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied!')));
                },
                child: const Icon(Icons.copy_rounded,
                    size: 16, color: KiteColors.grey400)),
            const SizedBox(width: 8),
            GestureDetector(
                onTap: onRefresh,
                child: const Icon(Icons.refresh_rounded,
                    size: 16, color: KiteColors.grey400)),
          ]),
          const SizedBox(height: 20),
          const Text('Native Balance',
              style: TextStyle(fontSize: 13, color: KiteColors.grey400)),
          const SizedBox(height: 4),
          loading
              ? const SizedBox(
                  height: 42,
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(KiteColors.cyan400)))))
              : ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                      colors: [KiteColors.white, KiteColors.cyan300],
                      stops: [0.6, 1.0]).createShader(b),
                  child: Text('${bal['native'] ?? '--'} KITE',
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          height: 1))),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.token_rounded,
                size: 14, color: KiteColors.gold400),
            const SizedBox(width: 4),
            Text('${bal['kite'] ?? '--'} KITE Tokens',
                style: const TextStyle(
                    fontSize: 13,
                    color: KiteColors.gold400,
                    fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KITE Token card
// ─────────────────────────────────────────────────────────────────────────────
class _KiteTokenCard extends StatelessWidget {
  final String kiteBalance;
  const _KiteTokenCard({required this.kiteBalance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: KiteColors.navy800,
        border: Border.all(
            color: KiteColors.gold400.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(children: [
        Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KiteColors.gold400.withValues(alpha: 0.15)),
            child: const Icon(Icons.token_rounded,
                color: KiteColors.gold400, size: 22)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('KitePay Token (KITE)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KiteColors.white)),
            const SizedBox(height: 2),
            Text(
                '${_kiteTokenAddress.substring(0, 6)}...${_kiteTokenAddress.substring(_kiteTokenAddress.length - 4)}',
                style: const TextStyle(
                    fontSize: 11,
                    color: KiteColors.grey400,
                    fontFamily: 'monospace')),
          ],
        )),
        Text(kiteBalance,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: KiteColors.gold400)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final KiteWalletProvider wallet;
  const _QuickActions({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: _ActionBtn(
              icon: Icons.arrow_upward_rounded,
              label: 'Send',
              color: KiteColors.cyan400,
              onTap: () => _showSendSheet(context, wallet))),
      const SizedBox(width: 12),
      Expanded(
          child: _ActionBtn(
              icon: Icons.arrow_downward_rounded,
              label: 'Receive',
              color: KiteColors.gold400,
              onTap: () => _showReceiveSheet(context, wallet))),
      const SizedBox(width: 12),
      Expanded(
          child: _ActionBtn(
              icon: Icons.swap_horiz_rounded,
              label: 'Swap',
              color: KiteColors.success,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Swap coming soon!'))))),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Network badge
// ─────────────────────────────────────────────────────────────────────────────
class _NetworkBadge extends StatelessWidget {
  final String? chainId;
  const _NetworkBadge({this.chainId});

  String get _name => switch (chainId) {
        '2368' => 'KiteAI Testnet',
        '2366' => 'KiteAI Mainnet',
        '1' => 'Ethereum Mainnet',
        '137' => 'Polygon',
        '8453' => 'Base',
        '10' => 'Optimism',
        '42161' => 'Arbitrum One',
        _ => 'Unknown Network',
      };

  Color get _color => switch (chainId) {
        '2368' => const Color(0xFF00E5FF),
        '2366' => const Color(0xFF00B8D4),
        '1' => const Color(0xFF627EEA),
        '137' => const Color(0xFF8247E5),
        '8453' => const Color(0xFF0052FF),
        '10' => const Color(0xFFFF0420),
        '42161' => const Color(0xFF28A0F0),
        _ => KiteColors.grey400,
      };

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color,
              boxShadow: [
                BoxShadow(color: _color.withValues(alpha: 0.5), blurRadius: 6)
              ])),
      const SizedBox(width: 8),
      Text(_name,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: _color)),
      const SizedBox(width: 4),
      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _color),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity list
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityList extends StatelessWidget {
  const _ActivityList();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: KiteColors.navy800,
        border: Border.all(color: KiteColors.navy700, width: 1),
      ),
      child: Column(children: [
        const _ActivityItem(
            icon: Icons.arrow_downward_rounded,
            iconColor: KiteColors.success,
            title: 'Received KITE',
            subtitle: 'From 0xAbC...1234',
            amount: '+0.05 KITE',
            amountColor: KiteColors.success,
            date: 'Today, 09:14'),
        const Divider(color: KiteColors.navy700, height: 1),
        const _ActivityItem(
            icon: Icons.token_rounded,
            iconColor: KiteColors.gold400,
            title: 'KITE Token Transfer',
            subtitle: 'To 0xDeF...5678',
            amount: '-100 KITE',
            amountColor: KiteColors.error,
            date: 'Yesterday, 17:30'),
        const Divider(color: KiteColors.navy700, height: 1),
        Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
                'Pull down to refresh. Live activity via KiteScan coming soon.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center)),
      ]),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle, amount, date;
  final Color amountColor;
  const _ActivityItem(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.subtitle,
      required this.amount,
      required this.amountColor,
      required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.12)),
            child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KiteColors.white)),
            const SizedBox(height: 2),
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 12, color: KiteColors.grey400)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(amount,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: amountColor)),
          const SizedBox(height: 2),
          Text(date,
              style: const TextStyle(fontSize: 11, color: KiteColors.grey600)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Send sheet
// ─────────────────────────────────────────────────────────────────────────────
void _showSendSheet(BuildContext ctx, KiteWalletProvider wallet) =>
    showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SendSheet(wallet: wallet));

class _SendSheet extends StatefulWidget {
  final KiteWalletProvider wallet;
  const _SendSheet({required this.wallet});
  @override
  State<_SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<_SendSheet> {
  final _toCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _sending = false;
  bool _sendToken = false;

  @override
  void dispose() {
    _toCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final to = _toCtrl.text.trim();
    final amount = _amountCtrl.text.trim();
    if (to.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fill in all fields')));
      return;
    }
    if (!to.startsWith('0x') || to.length != 42) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid wallet address')));
      return;
    }
    setState(() => _sending = true);
    try {
      await Future.delayed(const Duration(seconds: 2));
      KiteAnalytics.logEvent('wallet_send', {
        'to': to,
        'amount': amount,
        'type': _sendToken ? 'kite_token' : 'native'
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction submitted!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
            color: KiteColors.navy800,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: KiteColors.navy600,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Send Crypto',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Row(children: [
              _Toggle(
                  label: 'Native KITE',
                  selected: !_sendToken,
                  onTap: () => setState(() => _sendToken = false)),
              const SizedBox(width: 8),
              _Toggle(
                  label: 'KITE Token',
                  selected: _sendToken,
                  onTap: () => setState(() => _sendToken = true)),
            ]),
            const SizedBox(height: 16),
            TextField(
                controller: _toCtrl,
                decoration: const InputDecoration(
                    labelText: 'To address (0x...)',
                    prefixIcon: Icon(Icons.person_outline_rounded)),
                style: const TextStyle(color: KiteColors.white)),
            const SizedBox(height: 12),
            TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: 'Amount (${_sendToken ? "KITE Token" : "KITE"})',
                    prefixIcon: const Icon(Icons.toll_rounded)),
                style: const TextStyle(color: KiteColors.white)),
            const SizedBox(height: 8),
            Text('From: ${widget.wallet.displayAddress}',
                style:
                    const TextStyle(fontSize: 12, color: KiteColors.grey400)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _sending ? null : _send,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: KiteColors.cyan400,
                  foregroundColor: KiteColors.navy900,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(KiteColors.navy900)))
                  : const Text('Send',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Toggle(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? KiteColors.cyan400.withValues(alpha: 0.15)
                : KiteColors.navy700,
            border: Border.all(
                color: selected ? KiteColors.cyan400 : KiteColors.navy600,
                width: 1.5)),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? KiteColors.cyan400 : KiteColors.grey400)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Receive sheet
// ─────────────────────────────────────────────────────────────────────────────
void _showReceiveSheet(BuildContext ctx, KiteWalletProvider wallet) =>
    showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ReceiveSheet(wallet: wallet));

class _ReceiveSheet extends StatelessWidget {
  final KiteWalletProvider wallet;
  const _ReceiveSheet({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: KiteColors.navy800,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: KiteColors.navy600,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Receive Crypto',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Share your address to receive KITE tokens',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                  color: KiteColors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.qr_code_2_rounded,
                    size: 120, color: KiteColors.navy900),
                Text('QR Code',
                    style: TextStyle(
                        fontSize: 11,
                        color: KiteColors.navy900.withValues(alpha: 0.5))),
              ]))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: KiteColors.navy700,
                border: Border.all(color: KiteColors.navy600, width: 1)),
            child: Row(children: [
              Expanded(
                  child: Text(wallet.address ?? '',
                      style: const TextStyle(
                          fontSize: 13,
                          color: KiteColors.grey100,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5))),
              const SizedBox(width: 8),
              GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: wallet.address ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Address copied!')));
                    KiteAnalytics.logEvent('wallet_address_copied', null);
                  },
                  child: const Icon(Icons.copy_rounded,
                      size: 20, color: KiteColors.cyan400)),
            ]),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!'))),
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share Address'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
          ),
        ],
      ),
    );
  }
}
