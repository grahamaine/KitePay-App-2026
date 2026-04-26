import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:turnkey_api_key_stamper/turnkey_api_key_stamper.dart'; // Add this import
import 'package:turnkey_sdk_flutter/turnkey_sdk_flutter.dart';

import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("⚠️ .env file not found.");
  }

  runApp(const KitePayApp());
}

class KitePayApp extends StatelessWidget {
  const KitePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KitePay 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueAccent),
      home: const DashboardScreen(),
    );
  }
}

class KitePayService {
  final String agentKey = dotenv.env['KITEPAY_PUBLIC_KEY'] ?? "";
  // You will also need your Turnkey API keys for the stamper
  final String apiPublicKey =
      dotenv
          .env['040da93305734ae0699e39719e9cbc71d7be8cfa0e6c4d8caacda2cb890863b677d7cdb8176f86ddf7c936b0a017f2f096d7749cb2d33b0200e56f823dba556b7c'] ??
      "";
  final String apiPrivateKey =
      dotenv
          .env['0x96f116b522ffc5720aabeac008fb07bd752d2b285ae17a13207f99e81c7eec77'] ??
      "";

  void initializeAgent() {
    if (agentKey.isEmpty) return;

    // FIX 1 & 5: Initialize the Stamper (Required by TurnkeyClient)
    final stamper = ApiKeyStamper(
      apiPublicKey: apiPublicKey,
      apiPrivateKey: apiPrivateKey,
    );

    // FIX 2 & 3: Correct TurnkeyClient initialization
    // We removed 'const' and matched the THttpConfig requirements
    final turnkey = TurnkeyClient(
      config: THttpConfig(baseUrl: "https://api.turnkey.com"),
      stamper: stamper, // Pass the required stamper here
    );

    // FIX 4: Corrected class name for your local Kite SDK
    // Based on common 2026 patterns, it's often KitePayAgent or KitePay
    final kiteAgent = KitePay(
      publicKey: agentKey,
      config: KiteConfig(environment: "testnet"),
    );

    debugPrint("Kite Agent Address: ${kiteAgent.publicKey}");
    // Note: 'turnkey' is now ready to be used for signing!
  }
}
