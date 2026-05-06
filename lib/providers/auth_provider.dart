import 'package:flutter_riverpod/flutter_riverpod.dart';

// This holds the state of our user
class AuthState {
  final bool isAuthenticated;
  final String? walletAddress;
  final String? error;

  AuthState({this.isAuthenticated = false, this.walletAddress, this.error});
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Logic to check if a session already exists on startup
    return AuthState(isAuthenticated: false);
  }

  Future<void> loginWithTurnkey() async {
    state = const AsyncValue.loading();
    try {
      // 1. Initialize Turnkey with your credentials from .env
      // 2. Trigger the passkey prompt
      // 3. Update the state
      state = AsyncValue.data(
          AuthState(isAuthenticated: true, walletAddress: '0x...'));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void logout() {
    state = AsyncValue.data(AuthState(isAuthenticated: false));
  }
}

// The global provider that your UI will "watch"
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
