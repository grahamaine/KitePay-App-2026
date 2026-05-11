import 'package:flutter/foundation.dart';
import 'package:turnkey_sdk_flutter/turnkey_sdk_flutter.dart';

/// KiteAgentService wraps TurnkeyProvider to handle all auth & wallet
/// operations for the KitePay app.
class KiteAgentService extends ChangeNotifier {
  // ── Constants ────────────────────────────────────────────────────────────
  static const String _rpId = 'kitepay.vercel.app';
  static const String _orgId = String.fromEnvironment('TURNKEY_ORG_ID');
  static const String _sessionExpiry = '900'; // 15 minutes

  // ── State ─────────────────────────────────────────────────────────────────
  final TurnkeyProvider _turnkey;

  bool _isLoading = false;
  String? _lastError;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  Session? get session => _turnkey.session;
  dynamic get user => _turnkey.user;
  List<dynamic>? get wallets => (_turnkey.wallets as List?)?.cast<dynamic>();

  KiteAgentService(this._turnkey) {
    _turnkey.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _turnkey.removeListener(notifyListeners);
    super.dispose();
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<bool> loginWithPasskey() => _run(() async {
        await _turnkey.loginWithPasskey(
          rpId: _rpId,
          organizationId: _orgId,
          expirationSeconds: _sessionExpiry,
        );
      });

  Future<bool> signUpWithPasskey({
    required String displayName,
    required String email,
  }) =>
      _run(() async {
        await _turnkey.signUpWithPasskey(
          rpId: _rpId,
          organizationId: _orgId,
          expirationSeconds: _sessionExpiry,
          passkeyDisplayName: displayName,
          createSubOrgParams: CreateSubOrgParams(
            userEmail: email,
            userName: displayName,
          ),
        );
      });

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _turnkey.clearSession();
    } catch (e) {
      _lastError = e.toString();
      debugPrint('KiteAgentService logout: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Wallet ────────────────────────────────────────────────────────────────

  Future<bool> createEvmWallet({String walletName = 'KitePay Wallet'}) =>
      _run(() async {
        await _turnkey.createWallet(
          walletName: walletName,
          accounts: [
            const v1WalletAccountParams(
              curve: v1Curve.curve_secp256k1,
              pathFormat: v1PathFormat.path_format_bip32,
              path: "m/44'/60'/0'/0/0",
              addressFormat: v1AddressFormat.address_format_ethereum,
            ),
          ],
        );
      });

  Future<String?> signTransaction({
    required String signWith,
    required String unsignedTransaction,
  }) async {
    String? signed;
    await _run(() async {
      final result = await _turnkey.signTransaction(
        signWith: signWith,
        unsignedTransaction: unsignedTransaction,
        type: v1TransactionType.transaction_type_ethereum,
      );
      signed = result.signedTransaction;
    });
    return signed;
  }

  Future<void> refreshWallets() => _run(_turnkey.refreshWallets);

  Future<bool> refreshSession() => _run(() async {
        await _turnkey.refreshSession(expirationSeconds: _sessionExpiry);
      });

  Future<bool> hasActiveSession() async {
    try {
      return await _turnkey.getSession() != null;
    } catch (_) {
      return false;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() fn) async {
    _setLoading(true);
    _lastError = null;
    try {
      await fn();
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('KiteAgentService error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
