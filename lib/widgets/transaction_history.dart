import 'package:flutter/material.dart';

class TransactionHistory extends StatelessWidget {
  const TransactionHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Recent Activity", 
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              _txRow("Received SOL", "+ 2.5", "2 mins ago", true),
              const Divider(color: Colors.white10, height: 1),
              _txRow("Sent KITE", "- 100.0", "1 hour ago", false),
              const Divider(color: Colors.white10, height: 1),
              _txRow("Swapped USDC", "45.0", "Yesterday", true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _txRow(String title, String amount, String time, bool isPositive) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.white.withValues(alpha: 0.05), // Replaces the non-existent Colors.white05
        child: Icon(
          isPositive ? Icons.add_rounded : Icons.remove_rounded,
          color: isPositive ? const Color(0xFF3FB950) : const Color(0xFFF85149),
        ),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      subtitle: Text(time, style: const TextStyle(fontSize: 12, color: Colors.white38)),
      trailing: Text(
        amount,
        style: TextStyle(
          color: isPositive ? const Color(0xFF3FB950) : const Color(0xFFF85149),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}