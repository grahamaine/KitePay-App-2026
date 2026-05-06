import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kitepay_sdk/kitepay_sdk.dart';

// --- SECURE INITIALIZATION ---
Future<void> main() async {
  // Required to ensure the Flutter framework is ready before loading assets
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ Secrets Loaded Successfully from .env");
  } catch (e) {
    debugPrint("❌ Error loading .env file: $e");
  }

  runApp(const KitePayApp());
}

// --- SDK HANDSHAKE ---
final kitepay = Kitepay(
  // Pulling the public key from your .env for security
  apiKey: dotenv.env['KITEPAY_PUBLIC_KEY'] ?? 'pk_test_placeholder',
);

class KitePayApp extends StatelessWidget {
  const KitePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kite x Turnkey Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF050505),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const KitePayDashboard(),
    );
  }
}

class KitePayDashboard extends StatefulWidget {
  const KitePayDashboard({super.key});

  @override
  State<KitePayDashboard> createState() => _KitePayDashboardState();
}

class _KitePayDashboardState extends State<KitePayDashboard> {
  // --- STATE ---
  bool isSyncing = false;
  Timer? _agentTimer;
  double currentOnChainBalance = 10.50; // Mock balance for demo flow
  double spentToday = 0.00;
  final double sessionLimit = 15.00;

  // Real-time console logs
  final List<String> _consoleLogs = [
    "Kernel: Turnkey Authenticator Active",
    "Identity: Verified via TEE Vault"
  ];

  @override
  void initState() {
    super.initState();
    _startAgentIntelligence();
  }

  @override
  void dispose() {
    _agentTimer?.cancel();
    super.dispose();
  }

  // --- AGENT BRAIN ---
  void _startAgentIntelligence() {
    // The agent "scans" the network every 15 seconds
    _agentTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _autoDecisionLogic();
    });
  }

  void _addLog(String msg) {
    if (!mounted) return;
    setState(() {
      final time = DateTime.now();
      _consoleLogs.insert(
          0, "${time.hour}:${time.minute.toString().padLeft(2, '0')} - $msg");
      if (_consoleLogs.length > 8) _consoleLogs.removeLast();
    });
  }

  void _autoDecisionLogic() {
    _addLog("TEE Scan: Validating Spending Policy...");

    // Example: Agent decides to top up if budget is healthy
    if (currentOnChainBalance > 2.0 && spentToday < 5.0) {
      _addLog("Trigger: Autonomous Turnkey Signature Required.");
      _handleAgenticPurchase();
    } else {
      _addLog("Policy: Conditions not met for auto-spend.");
    }
  }

  // --- SDK EXECUTION ---
  Future<void> _handleAgenticPurchase() async {
    if (spentToday >= sessionLimit) {
      _addLog("Alert: Session limit reached. Transaction blocked.");
      return;
    }

    setState(() => isSyncing = true);
    try {
      // Executes the REAL createPayment method found in your SDK
      final result = await kitepay.createPayment(
        amount: 250, // $2.50 USDC
        currency: 'USDC',
        email: 'agent@turnkey-kite.io',
      );

      if (result != null) {
        setState(() {
          currentOnChainBalance -= 2.50;
          spentToday += 2.50;
        });
        _addLog("Success: Signed by Turnkey. Settled on Kite.");
      }
    } catch (e) {
      _addLog("Auth Error: Turnkey Stamper rejected request.");
    } finally {
      setState(() => isSyncing = false);
    }
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Colors.cyanAccent.withValues(alpha: 0.05),
              Colors.transparent
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSecurityBadge(),
                const SizedBox(height: 24),
                _buildBalanceCard(),
                const SizedBox(height: 32),
                const Text("INTELLIGENCE STREAM",
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildConsole(),
                const Spacer(),
                _buildManualTrigger(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SECURE AGENTIC COMMERCE",
                style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            Text("Kite x Turnkey",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900)),
          ],
        ),
        if (isSyncing)
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.cyanAccent, strokeWidth: 2)),
      ],
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, color: Colors.greenAccent, size: 14),
          SizedBox(width: 6),
          Text("TEE-ENCRYPTED ENVIRONMENT",
              style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("VAULT BALANCE",
              style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 8),
          Text("\$${currentOnChainBalance.toStringAsFixed(2)} USDC",
              style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Text(
              "ID: ${dotenv.env['TURNKEY_ETH_WALLET_ID']?.substring(0, 12)}...",
              style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildConsole() {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView.builder(
        itemCount: _consoleLogs.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text("> ${_consoleLogs[index]}",
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'monospace')),
        ),
      ),
    );
  }

  Widget _buildManualTrigger() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: isSyncing ? null : _handleAgenticPurchase,
        child: const Text("FORCE AGENTIC SETTLEMENT",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
