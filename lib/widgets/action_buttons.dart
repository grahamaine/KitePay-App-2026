import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _actionItem(Icons.arrow_upward_rounded, "Send", const Color(0xFF58A6FF)),
        const SizedBox(width: 16),
        _actionItem(Icons.arrow_downward_rounded, "Receive", const Color(0xFF3FB950)),
        const SizedBox(width: 16),
        _actionItem(Icons.swap_horiz_rounded, "Swap", const Color(0xFFD29922)),
      ],
    );
  }

  Widget _actionItem(IconData icon, String label, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            // FIXED: Using .withValues instead of .withOpacity
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            // FIXED: Using .withValues instead of .withOpacity
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}