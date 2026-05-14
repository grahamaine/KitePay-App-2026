import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart' show KiteColors;
import '../screens/portfolio_screen.dart';
import '../screens/swap_screen.dart';
import '../screens/wallet_screen.dart';
import '../services/agent_service.dart';
import '../services/agent_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final _tabs = [
    const _DashboardTab(),
    const WalletScreen(),
    const AgentScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiteColors.navy900,
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        backgroundColor: KiteColors.navy800,
        indicatorColor: KiteColors.cyan400.withValues(alpha: 0.15),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: KiteColors.cyan400),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded,
                color: KiteColors.cyan400),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon:
                Icon(Icons.smart_toy_rounded, color: KiteColors.cyan400),
            label: 'Agent',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Future<void> _handleLogout() async {
    await context.read<KiteAgentService>().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _handleCreateWallet() async {
    final agent = context.read<KiteAgentService>();
    final success = await agent.createEvmWallet();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(success ? 'Wallet created!' : agent.lastError ?? 'Failed.'),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
  }

  Future<void> _handleImportWallet() async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: KiteColors.navy800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Import wallet'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Private key (0x...)',
            hintText: '0xabc123...',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Import')),
        ],
      ),
    );

    if (confirmed == null || confirmed.trim().isEmpty) return;
    if (!mounted) return;

    final agent = context.read<KiteAgentService>();
    final success = await agent.importWallet(privateKeyHex: confirmed.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            success ? 'Wallet imported!' : agent.lastError ?? 'Import failed.'),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agent = context.watch<KiteAgentService>();
    final theme = Theme.of(context);
    final wallets = agent.wallets;

    return Scaffold(
      backgroundColor: KiteColors.navy900,
      appBar: AppBar(
        title: const Text('KitePay'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: agent.isLoading ? null : _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: agent.refreshWallets,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [KiteColors.navy800, KiteColors.navy700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KiteColors.navy700),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome to KitePay',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: KiteColors.white)),
                  const SizedBox(height: 8),
                  Text('Fly further with every payment',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: KiteColors.grey400)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick actions
            Row(children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.auto_graph_rounded,
                  label: 'Portfolio',
                  color: KiteColors.cyan400,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PortfolioScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Swap',
                  color: KiteColors.gold400,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SwapScreen()),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 28),

            // Wallets header
            Row(children: [
              Text('Your wallets',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: 'Import wallet',
                onPressed: agent.isLoading ? null : _handleImportWallet,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: agent.isLoading ? null : agent.refreshWallets,
              ),
            ]),
            const SizedBox(height: 12),

            if (agent.isLoading && wallets.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (wallets.isEmpty)
              _EmptyWalletsCard(onTap: _handleCreateWallet)
            else
              ...wallets.map((w) => _WalletCard(wallet: w)),

            const SizedBox(height: 20),
            if (wallets.isNotEmpty)
              OutlinedButton.icon(
                onPressed: agent.isLoading ? null : _handleCreateWallet,
                icon: const Icon(Icons.add),
                label: const Text('Add another wallet'),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 14)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 13),
          ]),
        ),
      ),
    );
  }
}

class _EmptyWalletsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyWalletsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 48, color: KiteColors.cyan400),
            const SizedBox(height: 12),
            Text('No wallets yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Tap to create your first EVM wallet',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: KiteColors.grey400),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final Map<String, dynamic> wallet;
  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String name =
        (wallet['walletName'] ?? wallet['name'] ?? 'Wallet').toString();
    final accounts = wallet['accounts'] as List?;
    final String address = accounts != null && accounts.isNotEmpty
        ? (accounts.first['address'] ?? '—').toString()
        : '—';
    final String shortAddress = address.length > 20
        ? '${address.substring(0, 10)}...${address.substring(address.length - 8)}'
        : address;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: KiteColors.cyan400.withValues(alpha: 0.15),
          child: const Icon(Icons.account_balance_wallet,
              color: KiteColors.cyan400),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(shortAddress,
            style: TextStyle(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        trailing: IconButton(
          icon: const Icon(Icons.copy_outlined),
          tooltip: 'Copy address',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: address));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Address copied!')),
            );
          },
        ),
      ),
    );
  }
}
