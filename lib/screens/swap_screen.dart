import 'package:flutter/material.dart';
import '../main.dart' show KiteColors;

class SwapScreen extends StatelessWidget {
  const SwapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiteColors.navy900,
      appBar: AppBar(
        title: const Text('Swap Tokens'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz_rounded, size: 64, color: KiteColors.cyan400),
            SizedBox(height: 20),
            Text(
              'Token Swap',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: KiteColors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(fontSize: 14, color: KiteColors.grey400),
            ),
          ],
        ),
      ),
    );
  }
}
