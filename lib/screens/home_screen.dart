import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/agent_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KiteAgentService>().refreshWallets();
    });
  }

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
        content: Text(
          success ? '✅ Wallet created!' : agent.lastError ?? 'Failed.',
        ),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agent = context.watch<KiteAgentService>();
    final theme = Theme.of(context);

    // user and wallets are dynamic (no TurnkeyUser / TurnkeyWallet classes)
    final dynamic user = agent.user;
    final List<dynamic> wallets = agent.wallets ?? [];

    final String userName =
        (user is Map ? user['userName'] ?? user['username'] ?? '' : '')
            .toString();
    final String userEmail =
        (user is Map ? user['userEmail'] ?? user['email'] ?? '' : '')
            .toString();

    return Scaffold(
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
            // Greeting
            if (userName.isNotEmpty) ...[
              Text(
                'Hi, $userName 👋',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
            ],
            if (userEmail.isNotEmpty) ...[
              Text(
                userEmail,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Wallets section header
            Row(
              children: [
                Text(
                  'Your Wallets',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: agent.isLoading ? null : agent.refreshWallets,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (agent.isLoading && wallets.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (wallets.isEmpty)
              _EmptyWalletsCard(onTap: _handleCreateWallet)
            else
              ...wallets.map(
                (w) => _WalletCard(wallet: w as Map<String, dynamic>),
              ),

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

class _EmptyWalletsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyWalletsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text('No wallets yet',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Tap to create your first EVM wallet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
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

    // accounts is a list of account maps; grab the first address
    final accounts = wallet['accounts'] as List?;
    final String address = accounts != null && accounts.isNotEmpty
        ? (accounts.first['address'] ?? '—').toString()
        : '—';

    final String shortAddress = address.length > 20
        ? '${address.substring(0, 10)}…${address.substring(address.length - 8)}'
        : address;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.account_balance_wallet,
              color: theme.colorScheme.primary),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          shortAddress,
          style: TextStyle(
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
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
