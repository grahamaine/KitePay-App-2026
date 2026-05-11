import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart' show KiteColors, KiteWalletProvider, KiteAnalytics;

// ─────────────────────────────────────────────────────────────────────────────
// Wallet Screen — top-level page
// ─────────────────────────────────────────────────────────────────────────────
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    // Init wallet modal as soon as screen mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wallet = context.read<KiteWalletProvider>();
      if (wallet.modal == null) wallet.init(context);
      KiteAnalytics.logScreenView('wallet_screen');
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<KiteWalletProvider>();

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: KiteColors.navy800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disconnect Wallet',
            style: TextStyle(color: KiteColors.white)),
        content: const Text(
          'Are you sure you want to disconnect your wallet?',
          style: TextStyle(color: KiteColors.grey400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: KiteColors.error,
              foregroundColor: KiteColors.white,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed == true) await wallet.disconnect();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Disconnected state
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
            // Icon halo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KiteColors.navy800,
                border: Border.all(
                  color: KiteColors.cyan400.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: KiteColors.cyan400.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 52,
                color: KiteColors.cyan400,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Connect Your Wallet',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Link MetaMask, Trust Wallet, Coinbase Wallet or any WalletConnect-compatible wallet to send and receive crypto.',
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Connect button
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

            // Supported wallets row
            Text(
              'Supports 300+ wallets',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connected state — balance card + actions + activity
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectedView extends StatelessWidget {
  final KiteWalletProvider wallet;
  const _ConnectedView({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        // ── Balance card ────────────────────────────────────────────────────
        _BalanceCard(wallet: wallet),
        const SizedBox(height: 20),

        // ── Quick actions ───────────────────────────────────────────────────
        _QuickActions(wallet: wallet),
        const SizedBox(height: 28),

        // ── Network badge ───────────────────────────────────────────────────
        _NetworkBadge(chainId: wallet.chainId),
        const SizedBox(height: 28),

        // ── Activity (placeholder) ──────────────────────────────────────────
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const _ActivityList(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance card
// ─────────────────────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final KiteWalletProvider wallet;
  const _BalanceCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KiteColors.navy700, KiteColors.navy600],
        ),
        border: Border.all(
          color: KiteColors.cyan400.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: KiteColors.cyan400.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KiteColors.success,
                  boxShadow: [
                    BoxShadow(
                      color: KiteColors.success.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                wallet.displayAddress,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: KiteColors.grey400,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: wallet.address ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address copied!')),
                  );
                },
                child: const Icon(Icons.copy_rounded,
                    size: 16, color: KiteColors.grey400),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Balance (placeholder — integrate web3dart for live balance)
          const Text(
            'Portfolio Value',
            style: TextStyle(fontSize: 13, color: KiteColors.grey400),
          ),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [KiteColors.white, KiteColors.cyan300],
              stops: [0.6, 1.0],
            ).createShader(bounds),
            child: const Text(
              '\$0.00',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.5,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '0.00 ETH',
            style: TextStyle(
              fontSize: 14,
              color: KiteColors.grey400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick action buttons — Send / Receive / Swap
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final KiteWalletProvider wallet;
  const _QuickActions({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.arrow_upward_rounded,
            label: 'Send',
            color: KiteColors.cyan400,
            onTap: () => _showSendSheet(context, wallet),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.arrow_downward_rounded,
            label: 'Receive',
            color: KiteColors.gold400,
            onTap: () => _showReceiveSheet(context, wallet),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.swap_horiz_rounded,
            label: 'Swap',
            color: KiteColors.success,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Swap coming soon!')),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
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

  String get _networkName => switch (chainId) {
        '1' => 'Ethereum Mainnet',
        '137' => 'Polygon',
        '8453' => 'Base',
        '10' => 'Optimism',
        '42161' => 'Arbitrum One',
        _ => 'Unknown Network',
      };

  Color get _networkColor => switch (chainId) {
        '1' => const Color(0xFF627EEA),
        '137' => const Color(0xFF8247E5),
        '8453' => const Color(0xFF0052FF),
        '10' => const Color(0xFFFF0420),
        '42161' => const Color(0xFF28A0F0),
        _ => KiteColors.grey400,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _networkColor,
            boxShadow: [
              BoxShadow(
                  color: _networkColor.withValues(alpha: 0.5), blurRadius: 6)
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _networkName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _networkColor,
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _networkColor),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity list (placeholder — replace with on-chain data via web3dart)
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
      child: Column(
        children: [
          const _ActivityItem(
            icon: Icons.arrow_downward_rounded,
            iconColor: KiteColors.success,
            title: 'Received ETH',
            subtitle: 'From 0xAbC…1234',
            amount: '+0.05 ETH',
            amountColor: KiteColors.success,
            date: 'Today, 09:14',
          ),
          const Divider(color: KiteColors.navy700, height: 1),
          const _ActivityItem(
            icon: Icons.arrow_upward_rounded,
            iconColor: KiteColors.error,
            title: 'Sent MATIC',
            subtitle: 'To 0xDeF…5678',
            amount: '-12.00 MATIC',
            amountColor: KiteColors.error,
            date: 'Yesterday, 17:30',
          ),
          const Divider(color: KiteColors.navy700, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Connect wallet to see live activity',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final String date;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
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
                    style: const TextStyle(
                        fontSize: 12, color: KiteColors.grey400)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: amountColor)),
              const SizedBox(height: 2),
              Text(date,
                  style:
                      const TextStyle(fontSize: 11, color: KiteColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Send bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
void _showSendSheet(BuildContext context, KiteWalletProvider wallet) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SendSheet(wallet: wallet),
  );
}

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
      // ── Use web3dart + wallet modal to send a transaction ─────────────
      // The reown_appkit modal handles signing via the connected wallet app.
      // Replace with actual web3dart sendTransaction call:
      //
      // final client = Web3Client(rpcUrl, http.Client());
      // final credentials = ... (from reown session)
      // await client.sendTransaction(credentials, Transaction(
      //   to: EthereumAddress.fromHex(to),
      //   value: EtherAmount.fromUnitAndValue(EtherUnit.szabo, ...),
      // ));

      await Future.delayed(const Duration(seconds: 2)); // simulate tx
      KiteAnalytics.logEvent('wallet_send', {'to': to, 'amount': amount});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction submitted!')),
        );
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: KiteColors.navy800,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KiteColors.navy600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Send Crypto',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),

            // To address
            TextField(
              controller: _toCtrl,
              decoration: const InputDecoration(
                labelText: 'To address (0x…)',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              style: const TextStyle(color: KiteColors.white),
            ),
            const SizedBox(height: 12),

            // Amount
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (ETH)',
                prefixIcon: Icon(Icons.toll_rounded),
              ),
              style: const TextStyle(color: KiteColors.white),
            ),
            const SizedBox(height: 8),

            // From address
            Text(
              'From: ${widget.wallet.displayAddress}',
              style: const TextStyle(fontSize: 12, color: KiteColors.grey400),
            ),
            const SizedBox(height: 24),

            // Send button
            FilledButton(
              onPressed: _sending ? null : _send,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: KiteColors.cyan400,
                foregroundColor: KiteColors.navy900,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(KiteColors.navy900),
                      ),
                    )
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

// ─────────────────────────────────────────────────────────────────────────────
// Receive bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
void _showReceiveSheet(BuildContext context, KiteWalletProvider wallet) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReceiveSheet(wallet: wallet),
  );
}

class _ReceiveSheet extends StatelessWidget {
  final KiteWalletProvider wallet;
  const _ReceiveSheet({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: KiteColors.navy800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KiteColors.navy600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('Receive Crypto',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Share your address or QR code to receive funds',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // QR code placeholder (use qr_flutter package for real QR)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: KiteColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_2_rounded,
                      size: 120, color: KiteColors.navy900),
                  Text(
                    'QR Code',
                    style: TextStyle(
                        fontSize: 11,
                        color: KiteColors.navy900.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Address box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: KiteColors.navy700,
              border: Border.all(color: KiteColors.navy600, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    wallet.address ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: KiteColors.grey100,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: wallet.address ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied!')),
                    );
                    KiteAnalytics.logEvent('wallet_address_copied', null);
                  },
                  child: const Icon(Icons.copy_rounded,
                      size: 20, color: KiteColors.cyan400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Share button
          OutlinedButton.icon(
            onPressed: () {
              // Use share_plus package for native share sheet:
              // Share.share(wallet.address ?? '');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Add share_plus to pubspec.yaml for native sharing')),
              );
            },
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share Address'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
