import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:kitepay_app_2026/services/kite_health_service.dart'; // Ensure correct path
import 'package:kitepay_app_2026/services/web3_service.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Services
  final Web3Service _web3service = Web3Service();
  final KiteHealthService _healthService = KiteHealthService();

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _web3service.initialize();
    dev.log("KitePay: Web3 Engine and Health Monitor Ready.");
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _healthService.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    setState(() => _isSending = true);

    try {
      // 1. Pre-flight check: Ensure network isn't stuck
      final metrics = await _healthService.healthStream.first;

      if (metrics.status == KiteStatus.stuck ||
          metrics.status == KiteStatus.offline) {
        throw Exception(
          "Kite Network is currently unresponsive. Please try again later.",
        );
      }

      // Show the processing dialog (Stateful UI from your previous code)
      _showTransactionStatus();

      // 2. REAL TRANSACTION: Trigger the Kite Chain broadcast
      final txHash = await _web3service.sendKite(
        recipient: _addressController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
      );

      dev.log("Transaction Hash: $txHash");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _confirmSend() {
    final address = _addressController.text.trim();
    final amount = _amountController.text.trim();

    if (address.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a recipient and amount"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Confirm Transaction",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _confirmRow(
              "Recipient",
              address.length > 12
                  ? "${address.substring(0, 6)}...${address.substring(address.length - 4)}"
                  : address,
            ),
            _confirmRow("Amount", "$amount KITE"),
            _confirmRow("Network", "Kite Mainnet"),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _handleSend();
                },
                child: const Text(
                  "Confirm and Send",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionStatus() {
    bool isMined = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Simulated mining time - in a real app, you'd listen to a transaction stream
            Timer(const Duration(seconds: 4), () {
              if (context.mounted && !isMined) {
                setDialogState(() => isMined = true);
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: isMined
                        ? const Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey("success"),
                            color: Colors.greenAccent,
                            size: 90,
                          )
                        : const CircularProgressIndicator(
                            color: Colors.blueAccent,
                          ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    isMined ? "Sent Successfully!" : "Processing...",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isMined) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Dialog
                          Navigator.pop(context); // Screen
                        },
                        child: const Text(
                          "Done",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Send KITE", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // KITE HEALTH BADGE
            StreamBuilder<KiteHealthMetrics>(
              stream: _healthService.healthStream,
              builder: (context, snapshot) {
                final status = snapshot.data?.status ?? KiteStatus.healthy;
                final color = status == KiteStatus.healthy
                    ? Colors.greenAccent
                    : status == KiteStatus.degraded
                    ? Colors.orangeAccent
                    : Colors.redAccent;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status == KiteStatus.healthy
                            ? "Kite Mainnet: Optimized"
                            : "Kite Mainnet: High Latency",
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      "Recipient Address",
                      Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      "Amount (KITE)",
                      Icons.token_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _isSending ? null : _confirmSend,
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Review Transaction",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.blueAccent, width: 2),
      ),
    );
  }
}
