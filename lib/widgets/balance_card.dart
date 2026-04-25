import 'package:flutter/material.dart';
import 'package:kitepay_app_2026/services/web3_service.dart';

class BalanceCard extends StatelessWidget {
  final Web3Service _web3service = Web3Service();

  // REPLACE THIS WITH YOUR ETH ADDRESS
  final String walletAddress = "0xC47fA20D51F2b809c8837A2F83AF9B0747c3Ce2D";

  BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6), // Blue Accent
            const Color(0xFF1E40AF), // Deep Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Balance",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.contactless_outlined,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // FETCHING THE LIVE BALANCE
          FutureBuilder<String>(
            // We call the service, then convert the double to a 4-decimal string
            future: _web3service
                .getBalance(walletAddress)
                .then((v) => v.toStringAsFixed(4)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Text(
                  "Error",
                  style: TextStyle(color: Colors.redAccent, fontSize: 32),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    snapshot.data ?? "0.0000",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "KITE",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),
          Text(
            "${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
