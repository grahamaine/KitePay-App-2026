import 'package:flutter/material.dart';

class TokenListWidget extends StatelessWidget {
  const TokenListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Your Assets", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        Row(
          children: [
            _card("KITE", "1,250", const Color(0xFF58A6FF)),
            const SizedBox(width: 20),
            _card("SOL", "12.45", const Color(0xFF14F195)),
          ],
        ),
      ],
    );
  }

  Widget _card(String symbol, String amount, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.token, color: color),
          const SizedBox(height: 12),
          Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(symbol, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}