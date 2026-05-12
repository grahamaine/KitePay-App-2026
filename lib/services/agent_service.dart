import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class KiteAgentService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _lastError;
  String? _verificationEmail;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  String? get verificationEmail => _verificationEmail;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  Map<String, dynamic>? get user => _auth.currentUser == null
      ? null
      : {
          'userName': _auth.currentUser!.displayName ?? '',
          'userEmail': _auth.currentUser!.email ?? '',
        };

  List<Map<String, dynamic>> get wallets => [];

  // ── Email OTP (send code) ─────────────────────────────────────────────────
  Future<bool> sendOtp(String email) async {
    _setLoading(true);
    _lastError = null;
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        // New user — create account first
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: _generateTempPassword(email),
        );
      }
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://kitepay-aine.firebaseapp.com/finishSignIn',
          handleCodeInApp: true,
          iOSBundleId: 'com.kitepay.app',
          androidPackageName: 'com.kitepay.app',
          androidInstallApp: true,
          androidMinimumVersion: '12',
        ),
      );
      _verificationEmail = email;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _lastError = _friendlyError(e.code);
      debugPrint('sendOtp error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Email + Password sign in ──────────────────────────────────────────────
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _lastError = null;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _lastError = _friendlyError(e.code);
      return false;
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Email + Password sign up ──────────────────────────────────────────────
  Future<bool> signUpWithEmail(
      String email, String password, String displayName) async {
    _setLoading(true);
    _lastError = null;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user?.updateDisplayName(displayName);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _lastError = _friendlyError(e.code);
      return false;
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Passkey stubs (mobile — coming soon) ──────────────────────────────────
  Future<bool> loginWithPasskey() async {
    _lastError = 'Passkey login coming soon on mobile.';
    notifyListeners();
    return false;
  }

  Future<bool> signUpWithPasskey({
    required String displayName,
    required String email,
  }) async {
    _lastError = 'Passkey sign-up coming soon on mobile.';
    notifyListeners();
    return false;
  }

  // ── Wallet stubs ──────────────────────────────────────────────────────────
  Future<bool> createEvmWallet({String walletName = 'KitePay Wallet'}) async {
    _lastError = 'Wallet creation coming soon.';
    notifyListeners();
    return false;
  }

  Future<void> refreshWallets() async {}

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<bool> hasActiveSession() async => _auth.currentUser != null;

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _generateTempPassword(String email) =>
      'KP_${email.hashCode.abs()}_2026';

  String _friendlyError(String code) {
    return switch (code) {
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'email-already-in-use' => 'An account already exists with this email.',
      'weak-password' => 'Password must be at least 6 characters.',
      'invalid-email' => 'Please enter a valid email address.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' => 'Network error. Check your connection.',
      _ => 'Authentication failed. Please try again.',
    };
  }
}
