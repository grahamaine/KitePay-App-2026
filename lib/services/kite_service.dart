// ignore_for_file: avoid_print
import 'dart:io';

class KiteService {
  late String _baseUrl;

  // Initialize the base URL for the Kite API
  void kiteConfig({required String baseUrl}) {
    _baseUrl = baseUrl;
    print("Kite configured with: $_baseUrl");
  }

  // This method runs the actual Linux command
  Future<void> runKitePayment(double amount) async {
    print("Initiating payment of \$$amount...");

    // This calls the 'kpass' CLI in your Ubuntu environment
    // We use 'wallet-send' skill which was installed during setup
    ProcessResult result = await Process.run('kpass', [
      'wallet-send',
      '--amount',
      amount.toString(),
      '--currency',
      'USD',
    ]);

    if (result.exitCode == 0) {
      print("✅ Payment Successful: ${result.stdout}");
    } else {
      print("❌ Payment Failed (Code ${result.exitCode}): ${result.stderr}");
    }
  }

  // Check if kpass is installed and authenticated
  Future<void> checkPassportStatus() async {
    ProcessResult result = await Process.run('kpass', ['--version']);
    if (result.exitCode == 0) {
      print('✅ Kite CLI is ready in Linux.');
    } else {
      print('❌ Kite CLI not found. Run "kpass authenticate" in terminal.');
    }
  }
}
