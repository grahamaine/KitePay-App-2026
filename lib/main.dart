import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/agent_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("System Notice: .env file failed to load: $e");
  }
  runApp(const ProviderScope(child: KitePayApp()));
}

class KitePayApp extends StatelessWidget {
  const KitePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kite x Turnkey Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF030305),
      ),
      home: const KitePayDashboard(),
    );
  }
}

class KitePayDashboard extends ConsumerWidget {
  const KitePayDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agent = ref.watch(agentProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [
              Colors.cyanAccent.withValues(alpha: 0.15),
              const Color(0xFF030305),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(agent),
                const SizedBox(height: 24),
                _buildSecurityBadge(agent),
                const SizedBox(height: 24),
                _buildBalanceVault(agent),
                const SizedBox(height: 36),
                const Text(
                  "KITE AI INTELLIGENCE STREAM",
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildTerminalConsole(agent)),
                const SizedBox(height: 24),
                _buildActionPanel(ref, agent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AgentState agent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("AUTONOMOUS INFRASTRUCTURE",
                style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
            SizedBox(height: 4),
            Text("Kite x Turnkey",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900)),
          ],
        ),
        if (agent.isRunning) ...[
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.cyanAccent, strokeWidth: 2)),
        ],
      ],
    );
  }

  Widget _buildSecurityBadge(AgentState agent) {
    final color = agent.isRunning ? Colors.cyanAccent : Colors.greenAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            agent.isRunning ? "AGENT: ACTIVE" : "IDENTITY: TEE-VERIFIED",
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceVault(AgentState agent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AGENT VAULT BALANCE",
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 12),
          Text(
            "\$${agent.balance.toStringAsFixed(2)} USDC",
            style: const TextStyle(
                fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalConsole(AgentState agent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListView.builder(
        itemCount: agent.logs.length,
        itemBuilder: (context, index) {
          final log = agent.logs[index];
          Color logColor = Colors.white70;

          if (log.contains("Success") || log.contains("Settled")) {
            logColor = Colors.greenAccent;
          } else if (log.contains("Error")) {
            logColor = Colors.redAccent;
          } else if (log.contains("Scanning")) {
            logColor = Colors.cyanAccent;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              "> $log",
              style: TextStyle(
                  color: logColor, fontSize: 12, fontFamily: 'monospace'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionPanel(WidgetRef ref, AgentState agent) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: agent.isRunning
              ? Colors.redAccent.withValues(alpha: 0.1)
              : Colors.cyanAccent,
          foregroundColor: agent.isRunning ? Colors.redAccent : Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () {
          ref.read(agentProvider.notifier).toggleAgent(!agent.isRunning);
        },
        child: Text(
          agent.isRunning
              ? "HALT AUTONOMOUS WORKFLOW"
              : "INITIALIZE AGENTIC WORKFLOW",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
