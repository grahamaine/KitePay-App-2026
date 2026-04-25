import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitepay_sdk/kitepay_sdk.dart';

// --- WALLET PROVIDERS ---

/// Holds the wallet data (address, balance). 
/// When this is null, the user is considered "logged out".
final walletProvider = StateProvider<KiteWallet?>((ref) => null);

/// Provides the SDK service. 
/// We use a basic Provider because the service instance usually doesn't change.
final sdkProvider = Provider<KitePayService>((ref) {
  // This will throw an error until you provide a real implementation in main.dart
  throw UnimplementedError('Real KitePayService implementation missing.');
});

// --- MARKET DATA PROVIDERS ---

/// This provider emits a new price every 3 seconds.
/// Using async* (yield) allows us to push continuous updates to the UI.
final kitePriceProvider = StreamProvider<double>((ref) async* {
  double price = 1.24; // Starting price
  final random = Random();

  while (true) {
    await Future.delayed(const Duration(seconds: 3));
    
    // Simulate a small market move (-0.02 to +0.02)
    double fluctuation = (random.nextDouble() * 0.04) - 0.02;
    price += fluctuation;
    
    yield price;
  }
});