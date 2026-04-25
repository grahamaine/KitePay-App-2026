import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitepay_sdk/kitepay_sdk.dart';

// Holds the wallet data (address, balance)
final walletProvider = StateProvider<KiteWallet?>((ref) => null);

// Provides the SDK service (Throws error until real SDK is plugged in)
final sdkProvider = Provider<KitePayService>((ref) {
  throw UnimplementedError('Real KitePayService implementation missing.');
});