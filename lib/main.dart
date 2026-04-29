import 'dart:io';

import 'package:flutter/material.dart';

// --- Placeholder for Kite/Turnkey SDK Imports ---
// Ensure these packages are in your pubspec.yaml
// import 'package:kite_sdk/kite_sdk.dart';
// import 'package:turnkey_sdk/turnkey_sdk.dart';

void main() {
  runApp(const KitePayApp());
}

class KitePayApp extends StatelessWidget {
  const KitePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KitePay 2026',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class KitePayService {
  late String _baseUrl;

  // FIX: Define the KiteConfig method
  void kiteConfig({required String baseUrl}) {
    _baseUrl = baseUrl;
    debugPrint("Kite configured with base URL: $_baseUrl");
  }

  // FIX: Define the KitePay method and link it to the Linux CLI
  Future<void> runKitePayment(double amount) async {
    debugPrint("Initiating payment of \$$amount...");

    // This calls the 'kpass' CLI you installed in Ubuntu
    // It uses 'wallet-send' which was one of the skills we installed
    ProcessResult result = await Process.run('kpass', [
      'wallet-send',
      '--amount',
      amount.toString(),
      '--currency',
      'USD',
    ]);

    if (result.exitCode == 0) {
      debugPrint("✅ Payment Successful: ${result.stdout}");
    } else {
      debugPrint(
        "❌ Payment Failed (Code ${result.exitCode}): ${result.stderr}",
      );
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final KitePayService _kiteService = KitePayService();

  @override
  void initState() {
    super.initState();

    // 1. Initialize Config
    _kiteService.kiteConfig(baseUrl: "https://api.agentpassport.ai");

    // 2. FIX: Correct ApiKeyStamper syntax using a Map
    // This addresses your 'not_enough_positional_arguments' error
    final stamper = {
      'apiPublicKey': 'pk_your_public_key_here',
      'apiPrivateKey': 'sk_your_private_key_here',
    };

    debugPrint("Stamper initialized with keys: ${stamper['apiPublicKey']}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("KitePay Terminal")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _kiteService.runKitePayment(10.0),
          child: const Text(
            r"Pay $10.00 via Kite Passport",
          ), // Added 'r' for raw string
        ),
      ),
    );
  }
}
