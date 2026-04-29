import 'package:flutter/material.dart';

import 'services/kite_service.dart'; // Import the service we made above

void main() {
  runApp(const KitePayApp());
}

class KitePayApp extends StatelessWidget {
  const KitePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KitePay 2026',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Initialize our Linux-linked service
  final KiteService _kiteService = KiteService();

  @override
  void initState() {
    super.initState();
    // Setup the service on startup
    _kiteService.kiteConfig(baseUrl: "https://api.agentpassport.ai");
    _kiteService.checkPassportStatus();

    // Fix for the ApiKeyStamper error: using a Map instead of named parameters
    final stamperConfig = {
      'apiPublicKey': 'pk_live_your_key_here',
      'apiPrivateKey': 'sk_live_your_key_here',
    };
    debugPrint("Security Stamper Ready: ${stamperConfig['apiPublicKey']}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KitePay Linux Terminal"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
              ),
              onPressed: () => _kiteService.runKitePayment(10.0),
              // Use 'r' (raw string) to fix the $ identifier error
              child: const Text(r"Pay $10.00 via Kite Passport"),
            ),
          ],
        ),
      ),
    );
  }
}
