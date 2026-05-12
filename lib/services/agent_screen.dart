import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart' show KiteColors;
import '../services/agent_service.dart';
import '../services/identity_service.dart';
import '../services/kite_chain_service.dart';
import '../services/usdc_service.dart';
import '../services/x402_service.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});
  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  double _usdcBalance = 0.0;
  bool _loadingBalance = false;

  // Demo task state
  bool _taskRunning = false;
  String _taskLog = '';
  String _taskUrl =
      'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBalance());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final agent = context.read<KiteAgentService>();
    final usdc = context.read<UsdcService>();
    final address = _getAddress(agent);
    if (address == null) return;
    setState(() => _loadingBalance = true);
    final bal = await usdc.getBalance(address);
    if (mounted)
      setState(() {
        _usdcBalance = bal;
        _loadingBalance = false;
      });
  }

  String? _getAddress(KiteAgentService agent) {
    final wallets = agent.wallets;
    if (wallets.isEmpty) return null;
    final accounts = wallets.first['accounts'] as List?;
    return accounts?.first['address']?.toString();
  }

  Future<void> _runDemoTask() async {
    final x402 = context.read<X402Service>();
    final agent = context.read<KiteAgentService>();
    final identity = context.read<IdentityService>();

    final wallets = agent.wallets;
    if (wallets.isEmpty) {
      _appendLog('No wallet found. Create one first.');
      return;
    }
    final accounts = wallets.first['accounts'] as List?;
    final privateKey = accounts?.first['privateKey']?.toString();
    final address = _getAddress(agent);
    if (privateKey == null || address == null) {
      _appendLog('Wallet key unavailable.');
      return;
    }

    setState(() {
      _taskRunning = true;
      _taskLog = '';
    });

    _appendLog('Agent starting task...');
    _appendLog('Identity: ${identity.identity?.agentName ?? "anonymous"}');
    _appendLog('Calling: $_taskUrl');

    final result = await x402.call(
      url: _taskUrl,
      method: 'GET',
      agentPrivateKey: privateKey,
      agentAddress: address,
    );

    if (result.success) {
      if (result.paid) {
        _appendLog('Payment sent: ${result.amountPaid} USDC');
        _appendLog('Tx: ${result.txHash}');
      } else {
        _appendLog('Free API — no payment needed');
      }
      _appendLog('Response ${result.statusCode}:');
      final body = result.body ?? '';
      _appendLog(body.length > 200 ? '${body.substring(0, 200)}...' : body);
      _appendLog('Task complete.');
    } else if (result.requiresApproval != null) {
      final req = result.requiresApproval!;
      _appendLog('Payment requires approval:');
      _appendLog('  Amount: ${req.amount} ${req.currency}');
      _appendLog('  To: ${req.recipient}');
      _appendLog('Enable auto-pay or approve manually.');
    } else {
      _appendLog('Task failed: ${result.error}');
    }

    await _loadBalance();
    setState(() => _taskRunning = false);
  }

  void _appendLog(String line) {
    setState(() {
      _taskLog +=
          '${DateTime.now().toIso8601String().substring(11, 19)} $line\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final agent = context.watch<KiteAgentService>();
    final usdc = context.watch<UsdcService>();
    final x402 = context.watch<X402Service>();
    final identity = context.watch<IdentityService>();
    final kite = context.watch<KiteChainService>();
    final address = _getAddress(agent);

    return Scaffold(
      backgroundColor: KiteColors.navy900,
      appBar: AppBar(
        title: const Text('AI Agent'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: KiteColors.cyan400,
          labelColor: KiteColors.cyan400,
          unselectedLabelColor: KiteColors.grey400,
          tabs: const [
            Tab(icon: Icon(Icons.smart_toy_outlined), text: 'Agent'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Activity'),
            Tab(icon: Icon(Icons.tune_outlined), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Tab 1: Agent runner ──────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Identity card
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.verified_user_outlined,
                            color: KiteColors.cyan400, size: 20),
                        const SizedBox(width: 8),
                        Text('Agent identity',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(color: KiteColors.grey400)),
                        const Spacer(),
                        if (identity.identity != null)
                          const _Pill('Attested', Colors.green)
                        else
                          const _Pill('Unattested', Colors.orange),
                      ]),
                      const SizedBox(height: 12),
                      if (identity.identity != null) ...[
                        Text(identity.identity!.agentName,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(identity.identity!.agentPurpose,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: KiteColors.grey400)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => launchUrl(Uri.parse(
                              '${kite.explorerTxUrl}${identity.identity!.attestationTxHash}')),
                          child: Text(
                            'Attestation: ${identity.identity!.attestationTxHash.substring(0, 18)}...',
                            style: const TextStyle(
                                color: KiteColors.cyan400, fontSize: 12),
                          ),
                        ),
                      ] else
                        TextButton.icon(
                          onPressed: () => _tabs.animateTo(2),
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text('Set up agent identity'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Balance row
                Row(children: [
                  Expanded(
                    child: _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('USDC balance',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: KiteColors.grey400)),
                          const SizedBox(height: 6),
                          _loadingBalance
                              ? const SizedBox(
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Text('${_usdcBalance.toStringAsFixed(4)} USDC',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: KiteColors.cyan400)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Spent today',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: KiteColors.grey400)),
                          const SizedBox(height: 6),
                          Text(
                              '${usdc.spentToday.toStringAsFixed(4)} / ${usdc.dailyLimit} USDC',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: usdc.dailyLimit > 0
                                ? (usdc.spentToday / usdc.dailyLimit)
                                    .clamp(0, 1)
                                : 0,
                            backgroundColor: KiteColors.navy700,
                            valueColor: const AlwaysStoppedAnimation(
                                KiteColors.cyan400),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Task config
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Task endpoint',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: KiteColors.grey400)),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (v) => setState(() => _taskUrl = v),
                        controller: TextEditingController(text: _taskUrl),
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'https://api.example.com/endpoint',
                          filled: true,
                          fillColor: KiteColors.navy700,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Text('Auto-pay', style: theme.textTheme.bodySmall),
                        const Spacer(),
                        Switch(
                          value: x402.autoPayEnabled,
                          onChanged: x402.setAutoPay,
                          activeThumbColor: KiteColors.cyan400,
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Run button
                FilledButton.icon(
                  onPressed: _taskRunning ? null : _runDemoTask,
                  icon: _taskRunning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(KiteColors.navy900)))
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(
                      _taskRunning ? 'Agent running...' : 'Run agent task'),
                  style: FilledButton.styleFrom(
                    backgroundColor: KiteColors.cyan400,
                    foregroundColor: KiteColors.navy900,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),

                // Task log
                if (_taskLog.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KiteColors.navy800,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KiteColors.navy700),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.terminal,
                              size: 14, color: KiteColors.cyan400),
                          const SizedBox(width: 6),
                          Text('Agent log',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: KiteColors.cyan400)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: _taskLog));
                            },
                            child: const Icon(Icons.copy_outlined,
                                size: 14, color: KiteColors.grey400),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          _taskLog,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: KiteColors.grey400,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Tab 2: Activity log ──────────────────────────────────────────
          x402.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 48, color: KiteColors.grey400),
                      const SizedBox(height: 12),
                      Text('No activity yet',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: KiteColors.grey400)),
                      const SizedBox(height: 4),
                      Text('Run an agent task to see payments here',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: KiteColors.grey600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: x402.history.length,
                  itemBuilder: (_, i) =>
                      _ActivityTile(tx: x402.history[i], kite: kite),
                ),

          // ── Tab 3: Settings ──────────────────────────────────────────────
          _AgentSettingsTab(
            address: address,
            onIdentityCreated: () => setState(() {}),
          ),
        ],
      ),
    );
  }
}

// ── Settings tab ─────────────────────────────────────────────────────────────
class _AgentSettingsTab extends StatefulWidget {
  final String? address;
  final VoidCallback onIdentityCreated;
  const _AgentSettingsTab(
      {required this.address, required this.onIdentityCreated});
  @override
  State<_AgentSettingsTab> createState() => _AgentSettingsTabState();
}

class _AgentSettingsTabState extends State<_AgentSettingsTab> {
  final _nameCtrl = TextEditingController(text: 'KitePay Agent');
  final _purposeCtrl =
      TextEditingController(text: 'Autonomous API payments on Kite chain');
  double _dailyLimit = 10.0;
  double _perTxLimit = 2.0;
  bool _attesting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _attestIdentity() async {
    final agent = context.read<KiteAgentService>();
    final identity = context.read<IdentityService>();
    final usdc = context.read<UsdcService>();

    final wallets = agent.wallets;
    if (wallets.isEmpty) return;
    final accounts = wallets.first['accounts'] as List?;
    final privateKey = accounts?.first['privateKey']?.toString();
    if (privateKey == null) return;

    setState(() => _attesting = true);
    usdc.setLimits(daily: _dailyLimit, perTx: _perTxLimit);

    final result = await identity.createIdentity(
      privateKeyHex: privateKey,
      agentName: _nameCtrl.text.trim(),
      agentPurpose: _purposeCtrl.text.trim(),
      maxSpendUsdcPerDay: _dailyLimit,
    );

    if (!mounted) return;
    setState(() => _attesting = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result != null
          ? 'Identity attested on Kite chain!'
          : 'Attestation failed.'),
      backgroundColor:
          result != null ? Colors.green.shade700 : Colors.red.shade700,
    ));

    if (result != null) widget.onIdentityCreated();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usdc = context.watch<UsdcService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Agent identity',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Agent name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _purposeCtrl,
            decoration: const InputDecoration(labelText: 'Agent purpose'),
          ),
          const SizedBox(height: 24),
          Text('Spending limits',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _LimitSlider(
            label: 'Daily limit',
            value: _dailyLimit,
            max: 100,
            unit: 'USDC',
            onChanged: (v) => setState(() => _dailyLimit = v),
          ),
          const SizedBox(height: 8),
          _LimitSlider(
            label: 'Per-transaction limit',
            value: _perTxLimit,
            max: 20,
            unit: 'USDC',
            onChanged: (v) => setState(() => _perTxLimit = v),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KiteColors.navy800,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  size: 16, color: KiteColors.grey400),
              const SizedBox(width: 8),
              Text(
                'Remaining today: ${usdc.remainingToday.toStringAsFixed(2)} USDC',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: KiteColors.grey400),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _attesting ? null : _attestIdentity,
            icon: _attesting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(KiteColors.navy900)))
                : const Icon(Icons.verified_user_outlined),
            label: Text(_attesting
                ? 'Attesting on Kite chain...'
                : 'Attest identity on Kite chain'),
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
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KiteColors.navy800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KiteColors.navy700),
        ),
        child: child,
      );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _LimitSlider extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;
  const _LimitSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.unit,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: KiteColors.grey400)),
          const Spacer(),
          Text('${value.toStringAsFixed(1)} $unit',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        Slider(
          value: value,
          min: 0.1,
          max: max,
          divisions: 100,
          activeColor: KiteColors.cyan400,
          inactiveColor: KiteColors.navy700,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final X402Transaction tx;
  final KiteChainService kite;
  const _ActivityTile({required this.tx, required this.kite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uri = Uri.tryParse(tx.url);
    final host = uri?.host ?? tx.url;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: (tx.succeeded
                  ? Colors.green
                  : tx.errorMessage != null
                      ? Colors.red
                      : Colors.orange)
              .withValues(alpha: 0.15),
          child: Icon(
            tx.succeeded
                ? Icons.check_rounded
                : tx.errorMessage != null
                    ? Icons.error_outline
                    : Icons.pending_outlined,
            color: tx.succeeded
                ? Colors.green
                : tx.errorMessage != null
                    ? Colors.red
                    : Colors.orange,
            size: 18,
          ),
        ),
        title: Text(host,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tx.paymentRequired != null)
              Text(
                  '${tx.paymentRequired!.amount} ${tx.paymentRequired!.currency} paid',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: KiteColors.cyan400)),
            Text(
              tx.startedAt.toIso8601String().substring(11, 19),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: KiteColors.grey600),
            ),
          ],
        ),
        trailing: tx.txHash != null
            ? IconButton(
                icon: const Icon(Icons.open_in_new, size: 16),
                onPressed: () =>
                    launchUrl(Uri.parse('${kite.explorerTxUrl}${tx.txHash}')),
              )
            : null,
      ),
    );
  }
}
