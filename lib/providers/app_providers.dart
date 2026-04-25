import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. The Provider
final walletProvider = NotifierProvider<WalletNotifier, String?>(() {
  return WalletNotifier();
});

// 2. The Notifier Class
class WalletNotifier extends Notifier<String?> {
  @override
  String? build() => null; // Initial state: not connected

  // This defines the 'connect' method main.dart is asking for
  void connect(String address) {
    state = address;
  }

  // This defines the 'disconnect' method main.dart is asking for
  void disconnect() {
    state = null;
  }
}

// Mock Price Stream
final kitePriceProvider = StreamProvider<double>((ref) async* {
  double currentPrice = 1.2450;
  while (true) {
    await Future.delayed(const Duration(seconds: 3));
    currentPrice += (DateTime.now().millisecond % 10 - 5) / 1000;
    yield currentPrice;
  }
});