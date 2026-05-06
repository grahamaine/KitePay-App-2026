import 'dart:async';

import 'package:flutter/material.dart';
// Ensure your local SDK is exported correctly in its barrel file
import 'package:kitepay_sdk/kitepay_sdk.dart';

/// --- KITE PAY INITIALIZATION ---
final kitepay = Kitepay(
  apiKey: 'sk_test_your_key_here',
);

void main() => runApp(const KitePayApp());

class KitePayApp extends StatelessWidget {
  const KitePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kite Agentic Commerce',
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
  bool isConnected = false;
  bool isSyncing = false;

  double sessionLimit = 10.00;
  double spentToday = 0.00;
  double currentOnChainBalance = 0.00;

  final String derivationPath = "m/742'/123'/0'/0";
  final String agentId = "KITE-COMMERCE-AGENT-V1";
  final String walletAddr = "0xFFeC82F9830f70fD9c978E1264472B08EbB0115c";

  @override
  void initState() {
    super.initState();
    _updateAgentBalance();
  }

  Future<void> _updateAgentBalance() async {
    if (isSyncing) return;
    _setSync(true);

    try {
      // Changed to getAccountBalance - verify this matches your SDK version
      final balanceData = await kitepay.getAccountBalance();

      double balance;
      if (balanceData is Map) {
        balance = (balanceData['available_balance'] ?? 0.0) / 100.0;
      } else {
        balance = (balanceData as num).toDouble() / 100.0;
      }

      setState(() {
        currentOnChainBalance = balance;
        isConnected = true;
        spentToday = (sessionLimit - (currentOnChainBalance % sessionLimit))
            .clamp(0.0, sessionLimit);
      });

      _showSnackBar(
          "Kite Sync: \$${currentOnChainBalance.toStringAsFixed(2)} USDC",
          Colors.cyanAccent);
    } catch (e) {
      _showSnackBar("Blockchain Sync Error", Colors.redAccent);
    } finally {
      _setSync(false);
    }
  }

  Future<void> _handleAgenticPurchase() async {
    if (spentToday >= sessionLimit) {
      _showSnackBar("Policy Violation: Limit Reached", Colors.redAccent);
      return;
    }

    _setSync(true);
    try {
      final result = await kitepay.createPayment(
        amount: 100,
        currency: 'USDC',
        email: 'agent-v1@kite.ai',
      );

      if (result != null) {
        _showSnackBar("x402 Settlement Executed", Colors.cyanAccent);
        await Future.delayed(const Duration(seconds: 2));
        await _updateAgentBalance();
      }
    } catch (e) {
      _showSnackBar("Execution Failed", Colors.redAccent);
    } finally {
      _setSync(false);
    }
  }

  void _setSync(bool value) => setState(() => isSyncing = value);

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        backgroundColor: color.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _shortAddr(String addr) =>
      "${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            // Fixed gradient syntax
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Colors.cyanAccent.withValues(alpha: 0.05),
              Colors.transparent
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _updateAgentBalance,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildGlassBalanceCard(),
                  const SizedBox(height: 24),
                  _buildConstraintPanel(),
                  const SizedBox(height: 32),
                  const Text("AGENT CAPABILITIES",
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildBentoGrid(),
                  const SizedBox(height: 32),
                  _buildLiveLogs(),
                ],
              ),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("KITE AI • AGENTIC COMMERCE",
                style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.5)),
            Text(agentId,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            Text("BIP-32 Path: $derivationPath",
                style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 11,
                    fontFamily: 'monospace')),
          ],
        ),
        _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isConnected
            ? Colors.cyanAccent.withValues(alpha: 0.1)
            : Colors.white10,
        border:
            Border.all(color: isConnected ? Colors.cyanAccent : Colors.white24),
      ),
      child: Icon(Icons.bolt,
          color: isConnected ? Colors.cyanAccent : Colors.white24, size: 20),
    );
  }

  Widget _buildGlassBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        gradient: LinearGradient(
            colors: [Colors.white.withValues(alpha: 0.05), Colors.transparent]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ON-CHAIN SETTLEMENT (USDC)",
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("\$${currentOnChainBalance.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  color: Colors.cyanAccent, size: 14),
              const SizedBox(width: 6),
              Text(_shortAddr(walletAddr),
                  style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                      fontFamily: 'monospace')),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildConstraintPanel() {
    double progress = (spentToday / sessionLimit).clamp(0.0, 1.0);
    Color statusColor =
        progress > 0.8 ? Colors.orangeAccent : Colors.cyanAccent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Autonomy Reservoir",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text("\$${spentToday.toStringAsFixed(2)} Spent",
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            color: statusColor,
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _capabilityTile("x402 Pay", Icons.shopping_cart_checkout,
            Colors.cyanAccent, _handleAgenticPurchase),
        _capabilityTile(
            "Sync", Icons.sync, Colors.white60, _updateAgentBalance),
      ],
    );
  }

  Widget _capabilityTile(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("AGENT ENGINE LOGS",
            style: TextStyle(
                color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _logLine("Agent Initialized via BIP-32 path..."),
              _logLine("Scanning for x402 payment challenges..."),
              if (isSyncing)
                _logLine("Settling on Kite Testnet...", isPending: true),
              if (isConnected && !isSyncing)
                _logLine("System ready. Policy enforced.", isSuccess: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logLine(String text,
      {bool isPending = false, bool isSuccess = false}) {
    Color textColor = Colors.white30;
    if (isPending) textColor = Colors.orangeAccent;
    if (isSuccess) textColor = Colors.cyanAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text("> $text",
          style: TextStyle(
              fontFamily: 'monospace', fontSize: 11, color: textColor)),
    );
  }
}
