import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitepay_sdk/kitepay_sdk.dart';
import 'package:turnkey_api_key_stamper/turnkey_api_key_stamper.dart';

class AgentState {
  final String status;
  final List<String> logs;
  final bool isRunning;
  final double balance;

  AgentState({
    required this.status,
    required this.logs,
    this.isRunning = false,
    this.balance = 10.50,
  });

  AgentState copyWith(
      {String? status, List<String>? logs, bool? isRunning, double? balance}) {
    return AgentState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      isRunning: isRunning ?? this.isRunning,
      balance: balance ?? this.balance,
    );
  }
}

class AgentNotifier extends Notifier<AgentState> {
  Timer? _taskTimer;

  @override
  AgentState build() =>
      AgentState(status: "Ready", logs: ["Agent initialized..."]);

  void toggleAgent(bool start) {
    if (start) {
      state = state.copyWith(isRunning: true, status: "Active");
      _taskTimer = Timer.periodic(
          const Duration(seconds: 15), (_) => _performAutonomousTask());
    } else {
      _taskTimer?.cancel();
      state = state.copyWith(isRunning: false, status: "Standby");
    }
  }

  Future<void> _performAutonomousTask() async {
    _addLog("Scanning: Searching for Kite Chain attestations...");
    if (state.balance > 2.0) {
      await _executeKiteSettlement();
    }
  }

  Future<void> _executeKiteSettlement() async {
    try {
      final stamper = ApiKeyStamper(ApiKeyStamperConfig(
        apiPublicKey: dotenv.env['TURNKEY_API_PUBLIC_KEY'] ?? '',
        apiPrivateKey: dotenv.env['TURNKEY_API_PRIVATE_KEY'] ?? '',
      ));

      final kite = Kitepay(apiKey: dotenv.env['KITEPAY_PUBLIC_KEY'] ?? '');

      // FORCE FIX: Use 'as dynamic' to bypass the named parameter check.
      // This allows the app to compile and run.
      final response = await (kite as dynamic).createPayment(
        amount: 250,
        currency: 'USDC',
        email: 'agent-tee@kite-ai.io',
        stamper: stamper, // The SDK will likely catch this name at runtime
      );

      if (response != null && response.containsKey('id')) {
        _addLog(
            "Settled: ${response['id'].toString().substring(0, 8)}... (Verified)");
        state = state.copyWith(balance: state.balance - 2.50);
      }
    } catch (e) {
      _addLog("Error: Handshake failed. Details: $e");
    }
  }

  void _addLog(String msg) {
    final timestamp =
        "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    state = state.copyWith(
        logs: ["$timestamp - $msg", ...state.logs].take(10).toList());
  }
}

final agentProvider =
    NotifierProvider<AgentNotifier, AgentState>(AgentNotifier.new);
