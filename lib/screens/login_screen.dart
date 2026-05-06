import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth state to show loading spinners or errors
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          // Futuristic gradient background
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your Logo from assets
            Image.asset(
              'assets/KitePay_Dapp.png',
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              "KITE PAY",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const Text(
              "Next-Gen AI Payments",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 60),

            // UI logic based on the AsyncValue state
            authState.when(
              data: (state) => state.isAuthenticated
                  ? const Text("Authenticated!",
                      style: TextStyle(color: Colors.green))
                  : _LoginButton(),
              loading: () =>
                  const CircularProgressIndicator(color: Colors.cyanAccent),
              error: (err, stack) => Column(
                children: [
                  Text("Error: $err",
                      style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 10),
                  _LoginButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: () {
        // Trigger the Turnkey login logic in your provider
        ref.read(authProvider.notifier).loginWithTurnkey();
      },
      child: const Text(
        "USE KITE PASSPORT",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
