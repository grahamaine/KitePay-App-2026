import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kitepay_sdk/kitepay_sdk.dart'; // Ensure this is in pubspec.yaml

// 1. Fixed the initialization
final kitepay = Kitepay(
  publicKey: 'your_public_key_here',
  environment: KitepayEnvironment.sandbox,
);

class KitePayHomeScreen extends StatefulWidget {
  const KitePayHomeScreen({super.key});

  @override
  State<KitePayHomeScreen> createState() => _KitePayHomeScreenState();
}

// 2. Fixed the class naming to match the createState call
class _KitePayHomeScreenState extends State<KitePayHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  final String agentId = "agent_019dd9ae";
  final String walletAddr = "0xFFeC82F9830f70fD9c978E1264472B08EbB0115c";

  bool isConnected = false;
  bool isSyncing = false;
  double balance = 120.50;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _handleSync() async {
    if (isSyncing) return;
    setState(() => isSyncing = true);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        isSyncing = false;
        isConnected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // 3. Fixed deprecated .withOpacity with .withValues
                color: Colors.blueAccent.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildMainCard(),
                  const SizedBox(height: 30),
                  _buildQuickActions(),
                  const SizedBox(height: 40),
                  _buildAgentSection(),
                  const SizedBox(height: 40),
                  _buildTransactionHistory(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildFloatingActionButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/KitePay_Dapp.png',
              errorBuilder: (c, e, s) => const Icon(
                Icons.account_balance_wallet,
                color: Colors.blueAccent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome back,",
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            Text(
              "Kite User ${walletAddr.substring(2, 6)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        _statusBadge(),
      ],
    );
  }

  Widget _statusBadge() {
    final Color badgeColor = isConnected
        ? Colors.greenAccent
        : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? "LIVE" : "OFFLINE",
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "NET WORTH",
            style: TextStyle(
              color: Colors.white38,
              letterSpacing: 2,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "\$${balance.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _cryptoPill("USDC", "100.00", Colors.blue),
              const SizedBox(width: 12),
              _cryptoPill("KITE", "450.25", Colors.cyanAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cryptoPill(String symbol, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Text(
            symbol,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "KITE AI AGENT",
          style: TextStyle(
            color: Colors.white38,
            letterSpacing: 1.5,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: isConnected
                          ? [
                              BoxShadow(
                                color: Colors.blueAccent.withValues(
                                  alpha: 0.3 * _glowController.value,
                                ),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                      color: isConnected ? Colors.blueAccent : Colors.white10,
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: isConnected ? Colors.white : Colors.white24,
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? "Agent Active" : "No Active Session",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConnected
                          ? "Auth: $agentId"
                          : "Connect Passport to enable AI payments",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionItem(Icons.north_east, "Send"),
        _actionItem(Icons.south_west, "Receive"),
        _actionItem(Icons.swap_horizontal_circle_outlined, "Swap"),
        _actionItem(Icons.more_horiz, "More"),
      ],
    );
  }

  Widget _actionItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "RECENT ACTIVITY",
              style: TextStyle(
                color: Colors.white38,
                letterSpacing: 1.5,
                fontSize: 11,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "See All",
                style: TextStyle(color: Colors.blueAccent, fontSize: 12),
              ),
            ),
          ],
        ),
        _txItem("Smart Swap", "KITE to USDC", "+\$24.00", Colors.greenAccent),
        _txItem("Agent Fee", "Session Start", "-\$0.02", Colors.white38),
        _txItem("Receive", "From 0x42...f2", "+\$10.00", Colors.greenAccent),
      ],
    );
  }

  Widget _txItem(String title, String sub, String amount, Color amountColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history, color: Colors.white24, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Color(0xFF64B5F6)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleSync,
              borderRadius: BorderRadius.circular(20),
              child: Center(
                child: isSyncing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isConnected
                            ? "PASSPORT CONNECTED"
                            : "SYNC WITH KITE PASSPORT",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
