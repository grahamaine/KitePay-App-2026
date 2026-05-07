import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- STATE MANAGEMENT ---
// Using Riverpod for 2026-standard reactive state
final authProvider = StateProvider<bool>((ref) => false);
final balanceProvider = StateProvider<double>((ref) => 1240.50);

// Tracks the agent's live autonomous actions/discovery
final agentLogsProvider = StateProvider<List<String>>((ref) => [
      "Agent initialized on Kite AI Layer",
      "Identity verified via Turnkey TEE Enclave",
    ]);

void main() {
  runApp(
    const ProviderScope(
      child: KitePayAgentApp(),
    ),
  );
}

class KitePayAgentApp extends StatelessWidget {
  const KitePayAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KitePay Agent 2026',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.cyanAccent,
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const MainRouter(),
    );
  }
}

/// Switches between Passkey Login and Agent Dashboard
class MainRouter extends ConsumerWidget {
  const MainRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);
    return isLoggedIn ? const AgentDashboard() : const LoginScreen();
  }
}

// --- FEATURE: TURNKEY TEE LOGIN ---
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, size: 80, color: Colors.cyanAccent),
            const SizedBox(height: 24),
            const Text(
              "KITE AI AGENT",
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
            const Text(
              "x402 Enabled • Stablecoin Settlement",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 60),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => ref.read(authProvider.notifier).state = true,
              icon: const Icon(Icons.fingerprint),
              label: const Text("Verify Agent Identity",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- FEATURE: AUTONOMOUS AGENT DASHBOARD ---
class AgentDashboard extends ConsumerStatefulWidget {
  const AgentDashboard({super.key});

  @override
  ConsumerState<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends ConsumerState<AgentDashboard> {
  bool isAgentActive = false;
  Timer? _executionTimer;

  /// Simulates autonomous AI behavior: Discovery -> x402 Payment -> Settlement
  void _toggleAgent(bool active) {
    setState(() => isAgentActive = active);
    if (active) {
      _executionTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        final logs = ref.read(agentLogsProvider);
        final actions = [
          "Discovered Service: Llama-3-Agent (x402 protocol found)",
          "Requesting programmable constraint verification...",
          "TEE Signing execution for 0.005 USDC settlement",
          "Kite AI Payment Successful: tx_0x82...f2a",
          "Usage-based billing updated in Vault enclave",
        ];
        final nextAction = actions[timer.tick % actions.length];

        // Update logs and simulate micro-deductions from the USDC vault
        ref.read(agentLogsProvider.notifier).state = [
          nextAction,
          ...logs.take(15)
        ];
        ref.read(balanceProvider.notifier).update((s) => s - 0.005);
      });
    } else {
      _executionTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _executionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(agentLogsProvider);
    final balance = ref.watch(balanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Agent Dashboard"),
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).state = false,
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(balance),
            const SizedBox(height: 24),
            _buildAgentControl(),
            const SizedBox(height: 24),
            const Text("Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 32),
            _buildLiveExecutionFeed(logs),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.cyan.withValues(alpha: 0.2),
          Colors.blueGrey.withValues(alpha: 0.1)
        ]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text("TEE-SECURED USDC VAULT",
              style: TextStyle(
                  fontSize: 12, letterSpacing: 1.5, color: Colors.cyanAccent)),
          const SizedBox(height: 12),
          Text("\$${balance.toStringAsFixed(4)}",
              style:
                  const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
          const Text("Real-time settlement active",
              style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAgentControl() {
    return ListTile(
      tileColor: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Icon(
        isAgentActive ? Icons.auto_awesome : Icons.pause_circle,
        color: isAgentActive ? Colors.cyanAccent : Colors.grey,
      ),
      title: const Text("Autonomous Discovery"),
      subtitle:
          Text(isAgentActive ? "Searching for x402 APIs..." : "Agent Idle"),
      trailing: Switch(
        value: isAgentActive,
        onChanged: _toggleAgent,
        activeThumbColor: Colors.cyanAccent, // 2026 Correct Property
        activeTrackColor: Colors.cyanAccent.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionItem(Icons.north_east, "Send", Colors.orangeAccent),
        const SizedBox(width: 12),
        _actionItem(Icons.south_west, "Receive", Colors.greenAccent),
        const SizedBox(width: 12),
        _actionItem(Icons.lock_outline, "Vault", Colors.blueAccent),
      ],
    );
  }

  Widget _actionItem(IconData icon, String label, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveExecutionFeed(List<String> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("AGENT EXECUTION LOG (KITE AI)",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        Container(
          height: 200,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text("> ${logs[i]}",
                  style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      color: Colors.greenAccent)),
            ),
          ),
        ),
      ],
    );
  }
}
