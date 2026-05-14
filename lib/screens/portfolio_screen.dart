import 'package:flutter/material.dart';
import '../main.dart' show KiteColors;

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiteColors.navy900,
      appBar: AppBar(
        title: const Text('Portfolio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_graph_rounded, size: 64, color: KiteColors.cyan400),
            SizedBox(height: 20),
            Text(
              'Portfolio Analytics',
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
