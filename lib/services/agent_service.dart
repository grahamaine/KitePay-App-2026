import 'package:flutter/foundation.dart';

class KiteAgentService extends ChangeNotifier {
  bool _isLoading = false;
  String? _lastError;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  // Stub user/wallet data
  Map<String, dynamic>? get user => null;
  List<Map<String, dynamic>>? get wallets => [];

  Future<bool> loginWithPasskey() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _isLoading = false;
    _lastError = 'Passkey login coming soon.';
    notifyListeners();
    return false;
  }

  Future<bool> signUpWithPasskey({
    required String displayName,
    required String email,
  }) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _isLoading = false;
    _lastError = 'Passkey sign-up coming soon.';
    notifyListeners();
    return false;
  }

  Future<bool> createEvmWallet({String walletName = 'KitePay Wallet'}) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _isLoading = false;
    _lastError = 'Wallet creation coming soon.';
    notifyListeners();
    return false;
  }

  Future<void> refreshWallets() async {}

  Future<void> logout() async {}

  Future<bool> hasActiveSession() async => false;
}
