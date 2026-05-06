import 'dart:ui';

import 'package:flutter/material.dart';
// Ensure your local SDK is exported correctly in its barrel file
import 'package:kitepay_sdk/kitepay_sdk.dart';

/// --- KITE PAY INITIALIZATION ---
final kitepay = Kitepay(
  apiKey: 'sk_test_your_key_here',
  // environment: KitepayEnvironment.sandbox,
);

void main() => runApp(const KitePayApp());

class KitePayApp extends StatelessWidget {
  const KitePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KitePay 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
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
  String sessionLimit = "0.00 USDC";

  final String agentId = "agent_019dd9ae";
  final String walletAddr = "0xFFeC82F9830f70fD9c978E1264472B08EbB0115c";

  String _shortAddr(String addr) =>
      "${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}";

  Future<void> _handlePay() async {
    _setSync(true);
    try {
      final result = await kitepay.createPayment(
        amount: 1000,
        currency: 'USD',
        email: 'trader@example.com',
      );
      if (result != null) {
        _showSnackBar("Payment Created: ${result['id']}", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Payment Failed: $e", Colors.redAccent);
    } finally {
      _setSync(false);
    }
  }

  Future<void> _handleWithdraw() async {
    _setSync(true);
    try {
      await kitepay.createPayout(
        amount: 5000,
        currency: 'USD',
        cardNumber: '4111111111111111',
        recipientName: 'Jane Trader',
      );
      _showSnackBar("Payout Initiated", Colors.blueAccent);
    } catch (e) {
      _showSnackBar("Payout Error: $e", Colors.redAccent);
    } finally {
      _setSync(false);
    }
  }

  void _refreshAgentStatus() async {
    _setSync(true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      isSyncing = false;
      isConnected = true;
      sessionLimit = "1.50 USDC";
    });
    _showSnackBar("Passport Synced: Agent Active", Colors.blueAccent);
  }

  void _setSync(bool value) => setState(() => isSyncing = value);

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refreshAgentStatus(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildGlassBalanceCard(),
                const SizedBox(height: 24),
                _buildAgentStatusTile(),
                const SizedBox(height: 32),
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildBentoGrid(),
                const SizedBox(height: 32),
                _buildActivityFeed(),
                const SizedBox(height: 32),
                _buildSyncButton(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("KitePay 2026".toUpperCase(),
                style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 11)),
            const Text("Dashboard",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
            Text(_shortAddr(walletAddr),
                style: const TextStyle(
                    color: Colors.white38,
                    fontFamily: 'monospace',
                    fontSize: 13)),
          ],
        ),
        _buildAgentBadge(),
      ],
    );
  }

  Widget _buildAgentBadge() {
    final statusColor = isConnected ? Colors.greenAccent : Colors.white24;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isConnected
                ? Colors.greenAccent.withValues(alpha: 0.2)
                : Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Text(
            isSyncing ? "SYNCING" : (isConnected ? "ACTIVE" : "OFFLINE"),
            style: TextStyle(
                color: statusColor, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBalanceCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueAccent.withValues(alpha: 0.15),
            Colors.purpleAccent.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TOTAL WEALTH",
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.8)),
                const SizedBox(height: 12),
                const Text("\$24,082.50",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _tokenBadge("USDC", Colors.blue),
                    const SizedBox(width: 10),
                    _tokenBadge("KITE", Colors.orangeAccent),
                    const Spacer(),
                    const Icon(Icons.trending_up,
                        color: Colors.greenAccent, size: 18),
                    const Text(" 2.4%",
                        style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tokenBadge(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12)),
      child: Text(name,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildAgentStatusTile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isConnected
                ? Colors.greenAccent.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isConnected
                ? Colors.greenAccent.withValues(alpha: 0.1)
                : Colors.white10,
            child: Icon(Icons.shield_outlined,
                color: isConnected ? Colors.greenAccent : Colors.white24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isConnected ? "Agent Authorized" : "Agent Restricted",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text("Limit: $sessionLimit",
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ),
          if (isSyncing)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.blueAccent)),
        ],
      ),
    );
  }

  Widget _buildBentoGrid() {
    return Row(
      children: [
        Expanded(
            child: _bentoTile(
                "Pay", Icons.north_east_rounded, Colors.blueAccent,
                onTap: _handlePay)),
        const SizedBox(width: 16),
        Expanded(
            child: _bentoTile(
                "Payout", Icons.south_west_rounded, Colors.orangeAccent,
                onTap: _handleWithdraw)),
      ],
    );
  }

  Widget _bentoTile(String label, IconData icon, Color color,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("RECENT ACTIVITY",
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            TextButton(
                onPressed: () {},
                child: const Text("View All", style: TextStyle(fontSize: 12))),
          ],
        ),
        const SizedBox(height: 12),
        if (isSyncing)
          _activityRow("Processing...", "Skill: kite-api", "Pending",
              Colors.orangeAccent),
        _activityRow("Agent Registered", agentId, "Success", Colors.blueAccent),
      ],
    );
  }

  Widget _activityRow(String title, String sub, String status, Color dotColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.radio_button_checked, color: dotColor, size: 14),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              Text(sub,
                  style: const TextStyle(color: Colors.white24, fontSize: 11)),
            ],
          ),
          const Spacer(),
          Text(status,
              style: TextStyle(
                  color: dotColor.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isSyncing)
            BoxShadow(
              color: Colors.blueAccent.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
        ],
      ),
      child: ElevatedButton(
        onPressed: isSyncing ? null : _refreshAgentStatus,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 70),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        child: isSyncing
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(isConnected ? "REFRESH SESSION" : "SYNC KITE PASSPORT",
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.1)),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navIcon(Icons.grid_view_rounded, true),
          _navIcon(Icons.account_balance_wallet_outlined, false),
          _navIcon(Icons.auto_graph_rounded, false),
          _navIcon(Icons.settings_outlined, false),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, bool isActive) {
    return Icon(icon,
        color: isActive ? Colors.blueAccent : Colors.white24, size: 26);
  }
}
