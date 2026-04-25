import 'package:flutter/material.dart';

class SwapScreen extends StatelessWidget {
  const SwapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Swap Tokens",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 40),
        Center(
          child: Text(
            "Swap Interface Coming Soon",
            style: TextStyle(color: Colors.white38),
          ),
        ),
      ],
    );
  }
}