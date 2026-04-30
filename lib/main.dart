import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kitepay_sdk/kitepay_sdk.dart';

// --- KITE PAY INITIALIZATION ---
final kitepay = Kitepay(
  publicKey: 'your_public_key_here',
  environment: KitepayEnvironment.sandbox,
);

void main() => runApp(const KitePayApp());

class KitePayApp extends StatelessWidget {
  const KitePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
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
  // --- STATE MANAGEMENT ---
  bool isConnected = false;
  bool isSyncing = false;
  String sessionLimit = "0.00 USDC";

  final String agentId = "agent_019dd9ae";
  final String walletAddr = "0xFFeC82F9830f70fD9c978E1264472B08EbB0115c";

  String shortAddr(String addr) =>
      "${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}";

  // --- ACTIONS ---
  void _refreshAgentStatus() async {
    setState(() => isSyncing = true);

    // Logic for Kitepay gateway authentication would trigger here
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isSyncing = false;
      isConnected = true;
      sessionLimit = "1.50 USDC";
    });
    _showSnackBar("Passport Synced: Agent Active", Colors.blueAccent);
  }

  Future<void> _executeTransaction() async {
    if (!isConnected) {
      _showSnackBar("Please sync Passport first", Colors.orangeAccent);
      return;
    }
    setState(() => isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => isSyncing = false);
    _showSnackBar("Agent successfully executed transfer!", Colors.green);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildBentoGrid(),
              const SizedBox(height: 32),
              _buildActivityFeed(),
              const SizedBox(height: 24),
              _buildSyncButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "KitePay 2026",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const Text(
              "Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              shortAddr(walletAddr),
              style: const TextStyle(
                color: Colors.white38,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ),
        _buildAgentBadge(),
      ],
    );
  }

  Widget _buildAgentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt,
            color: isConnected ? Colors.greenAccent : Colors.white24,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isSyncing ? "SYNCING..." : (isConnected ? "ACTIVE" : "OFFLINE"),
            style: TextStyle(
              color: isConnected ? Colors.greenAccent : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBalanceCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blueAccent.withValues(alpha: 0.2),
                  Colors.purpleAccent.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "TOTAL WEALTH",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "\$24,082.50",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _tokenBadge("USDC", Colors.blue),
                      const SizedBox(width: 8),
                      _tokenBadge("KITE", Colors.orange),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_upward,
                        color: Colors.greenAccent,
                        size: 14,
                      ),
                      const Text(
                        " 2.4%",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tokenBadge(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAgentStatusTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? Colors.greenAccent.withValues(alpha: 0.2)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: isConnected ? Colors.greenAccent : Colors.white24,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isConnected ? "Agent Authorized" : "Agent Restricted",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "Session Limit: $sessionLimit",
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          if (isSyncing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
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
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _bentoTile(
          "Send",
          Icons.send,
          Colors.blueAccent,
          onTap: _executeTransaction,
        ),
        _bentoTile("Swap", Icons.swap_horiz, Colors.orangeAccent, onTap: () {}),
      ],
    );
  }

  Widget _bentoTile(
    String label,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "RECENT ACTIVITY",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        if (isSyncing)
          _activityRow(
            "Agent Executing...",
            "Skill: wallet-send",
            "Processing",
            Colors.orangeAccent,
          ),
        _activityRow("Agent Registered", agentId, "Success", Colors.blueAccent),
        _activityRow(
          "Wallet Linked",
          "Kite Chain",
          "Verified",
          Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _activityRow(String title, String sub, String status, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: dotColor, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          Text(
            status,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSyncing ? null : _refreshAgentStatus,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Text(
          isConnected ? "Refresh Session" : "Sync with Kite Passport",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(Icons.grid_view_rounded, color: Colors.blueAccent),
          Icon(Icons.account_balance_wallet_outlined, color: Colors.white38),
          Icon(Icons.settings_outlined, color: Colors.white38),
        ],
      ),
    );
  }
}
