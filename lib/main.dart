import 'dart:ui';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
      home: KitePayDashboard(),
      debugShowCheckedModeBanner: false,
    ));

class KitePayDashboard extends StatefulWidget {
  const KitePayDashboard({super.key});

  @override
  State<KitePayDashboard> createState() => _KitePayDashboardState();
}

class _KitePayDashboardState extends State<KitePayDashboard> {
  // CONNECTION & IDENTITY STATE
  bool isConnected = false;
  bool isSyncing = false; // New: Tracks agent execution
  String passportStatus = "Passport: Not Linked";
  final String myAgentId = "agent_019dd9ae";
  final String myWallet = "0xFFeC82F9830f70fD9c978E1264472B08EbB0115c";

  // HELPER TO SHORTEN ADDRESS
  String shortAddr(String addr) =>
      "${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}";

  void _togglePassport() {
    setState(() {
      isConnected = !isConnected;
      passportStatus =
          isConnected ? "Passport: Agent Active" : "Passport: Not Linked";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(isConnected ? "Kite Agent Connected!" : "Agent Disconnected"),
        duration: const Duration(seconds: 1),
        backgroundColor: isConnected ? Colors.blueAccent : Colors.redAccent,
      ),
    );
  }

  // 2026 Skill Execution Logic
  Future<void> _executeTransaction() async {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please connect Passport first")),
      );
      return;
    }

    setState(() => isSyncing = true);

    // Simulation of the kpass execution command: 
    // kpass agent execute wallet-send --to 0x... --amount 0.1
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isSyncing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Agent successfully executed transfer!"),
          backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              _buildGlassCard(),
              const SizedBox(height: 15),
              _buildPolicyCard(),
              const SizedBox(height: 25),
              const Text("Quick Actions",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildBentoGrid(),
              const SizedBox(height: 25),
              _buildRecentTransactions(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAgentIdentity(),
            CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1E1E1E),
                child: isSyncing 
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent))
                  : const Icon(Icons.bolt, color: Colors.blueAccent, size: 20)),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shortAddr(myWallet),
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontFamily: 'monospace')),
                const Text("Alex Kite",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _togglePassport,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isConnected ? Colors.greenAccent : Colors.redAccent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded,
                            size: 14,
                            color: isConnected ? Colors.greenAccent : Colors.redAccent),
                        const SizedBox(width: 6),
                        Text(passportStatus,
                            style: TextStyle(
                                color: isConnected ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgentIdentity() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isConnected
                ? Colors.greenAccent.withOpacity(0.3)
                : Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt,
              color: isConnected ? Colors.greenAccent : Colors.white38,
              size: 16),
          const SizedBox(width: 8),
          Text(
            isSyncing ? "EXECUTING SKILL..." : (isConnected ? "ACTIVE SESSION" : "OFFLINE"),
            style: TextStyle(
              color: isConnected ? Colors.greenAccent : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.blueAccent.withOpacity(0.3),
                Colors.purpleAccent.withOpacity(0.1)
              ]),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("TOTAL WEALTH",
                      style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2)),
                  const Text("\$24,082.50",
                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 16),
                      Text(" +2.4% today",
                          style: TextStyle(color: Colors.greenAccent.withOpacity(0.8), fontSize: 14)),
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

  Widget _buildPolicyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.blueAccent, size: 18),
          const SizedBox(width: 8),
          const Text("1h Session", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Container(height: 20, width: 1, color: Colors.white10),
          const Spacer(),
          const Icon(Icons.account_balance_wallet_outlined, color: Colors.greenAccent, size: 18),
          const SizedBox(width: 8),
          const Text("\$1.50 Limit", style: TextStyle(color: Colors.white70, fontSize: 13)),
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
        GestureDetector(
          onTap: _executeTransaction,
          child: _bentoTile("Send", Icons.send, Colors.blueAccent)
        ),
        _bentoTile("Swap", Icons.swap_horiz, Colors.orangeAccent),
      ],
    );
  }

  Widget _bentoTile(String label, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Activity",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (isSyncing)
          _txItem("Executing: Send Skill", "Processing...", "WAITING", Colors.orangeAccent),
        _txItem("AI Agent: Gas Fee", "Kite Chain", "- \$0.04", Colors.redAccent),
        _txItem("Passport Reward", "Staking", "+ \$12.50", Colors.greenAccent),
      ],
    );
  }

  Widget _txItem(String title, String sub, String amt, Color amtColor) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
          backgroundColor: Color(0xFF1E1E1E),
          child: Icon(Icons.history, color: Colors.white54, size: 20)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: Text(amt, style: TextStyle(color: amtColor, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          Icon(Icons.grid_view_rounded, color: Colors.blueAccent),
          Icon(Icons.account_balance_wallet_outlined, color: Colors.white38),
          Icon(Icons.settings_outlined, color: Colors.white38),
        ],
      ),
    );
  }
}