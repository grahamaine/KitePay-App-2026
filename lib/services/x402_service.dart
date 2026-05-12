import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'usdc_service.dart';

/// x402 — HTTP 402 Payment Required protocol for autonomous agent payments.
/// Flow: agent calls API → gets 402 with price → pays USDC → retries with proof.
class X402Service extends ChangeNotifier {
  final UsdcService _usdc;
  X402Service(this._usdc);

  final List<X402Transaction> _history = [];
  List<X402Transaction> get history => List.unmodifiable(_history);

  bool _autoPayEnabled = true;
  bool get autoPayEnabled => _autoPayEnabled;

  void setAutoPay(bool enabled) {
    _autoPayEnabled = enabled;
    notifyListeners();
  }

  // ── Core: make a paid API call ────────────────────────────────────────────
  Future<X402Result> call({
    required String url,
    required String method,
    required String agentPrivateKey,
    required String agentAddress,
    Map<String, String>? headers,
    String? body,
    int maxRetries = 2,
  }) async {
    final txRecord = X402Transaction(
      url: url,
      method: method,
      startedAt: DateTime.now(),
    );

    try {
      // Step 1: Initial request (expect 402)
      debugPrint('x402: calling $method $url');
      final initial = await _makeRequest(
        url: url,
        method: method,
        headers: headers,
        body: body,
      );

      // Happy path — no payment needed
      if (initial.statusCode != 402) {
        txRecord.complete(initial.statusCode, initial.body);
        _addHistory(txRecord);
        return X402Result.success(
          statusCode: initial.statusCode,
          body: initial.body,
          paid: false,
        );
      }

      // Step 2: Parse 402 payment requirements
      final requirements = _parsePaymentRequirements(initial);
      if (requirements == null) {
        txRecord.fail('Could not parse payment requirements');
        _addHistory(txRecord);
        return X402Result.failed('Invalid 402 response from server');
      }

      debugPrint('x402: payment required · ${requirements.amount} '
          '${requirements.currency} → ${requirements.recipient}');

      txRecord.paymentRequired = requirements;

      // Step 3: Check auto-pay is enabled and within limits
      if (!_autoPayEnabled) {
        txRecord.fail('Auto-pay disabled');
        _addHistory(txRecord);
        return X402Result.requiresApproval(requirements);
      }

      // Step 4: Pay via USDC
      final transfer = await _usdc.transfer(
        privateKeyHex: agentPrivateKey,
        toAddress: requirements.recipient,
        amount: requirements.amount,
        memo: 'x402: $url',
      );

      if (!transfer.success) {
        txRecord.fail(transfer.error ?? 'Payment failed');
        _addHistory(txRecord);
        return X402Result.failed(transfer.error ?? 'Payment failed');
      }

      txRecord.txHash = transfer.txHash;
      debugPrint('x402: paid · tx ${transfer.txHash}');

      // Step 5: Retry with payment proof
      final proof = _buildPaymentProof(
        txHash: transfer.txHash!,
        amount: requirements.amount,
        currency: requirements.currency,
        recipient: requirements.recipient,
        payer: agentAddress,
      );

      final retryHeaders = {
        ...?headers,
        'X-Payment-Proof': proof,
        'X-Payment-Tx': transfer.txHash!,
        'X-Payment-Chain': '2368',
        'X-Payment-Token': '0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b',
      };

      final retryResponse = await _makeRequest(
        url: url,
        method: method,
        headers: retryHeaders,
        body: body,
      );

      txRecord.complete(retryResponse.statusCode, retryResponse.body);
      _addHistory(txRecord);

      if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
        return X402Result.success(
          statusCode: retryResponse.statusCode,
          body: retryResponse.body,
          paid: true,
          txHash: transfer.txHash,
          amountPaid: requirements.amount,
        );
      }

      return X402Result.failed(
          'Request failed after payment: ${retryResponse.statusCode}');
    } catch (e) {
      txRecord.fail(e.toString());
      _addHistory(txRecord);
      debugPrint('x402 error: $e');
      return X402Result.failed(e.toString());
    }
  }

  // ── Internal helpers ──────────────────────────────────────────────────────
  Future<http.Response> _makeRequest({
    required String url,
    required String method,
    Map<String, String>? headers,
    String? body,
  }) async {
    final uri = Uri.parse(url);
    final h = {'Content-Type': 'application/json', ...?headers};

    switch (method.toUpperCase()) {
      case 'POST':
        return http
            .post(uri, headers: h, body: body)
            .timeout(const Duration(seconds: 15));
      case 'PUT':
        return http
            .put(uri, headers: h, body: body)
            .timeout(const Duration(seconds: 15));
      default:
        return http.get(uri, headers: h).timeout(const Duration(seconds: 15));
    }
  }

  PaymentRequirements? _parsePaymentRequirements(http.Response response) {
    try {
      // Check headers first (standard x402)
      final header = response.headers['x-payment-required'] ??
          response.headers['X-Payment-Required'];

      if (header != null) {
        final parts = header.split(';').map((s) => s.trim()).toList();
        double? amount;
        String currency = 'USDC';
        String? recipient;

        for (final part in parts) {
          if (part.startsWith('amount=')) {
            amount = double.tryParse(part.substring(7));
          } else if (part.startsWith('currency=')) {
            currency = part.substring(9);
          } else if (part.startsWith('recipient=')) {
            recipient = part.substring(10);
          }
        }

        if (amount != null && recipient != null) {
          return PaymentRequirements(
              amount: amount, currency: currency, recipient: recipient);
        }
      }

      // Fall back to JSON body
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final payment = json['payment'] ?? json['x402'] ?? json;
      return PaymentRequirements(
        amount: (payment['amount'] as num).toDouble(),
        currency: payment['currency'] ?? 'USDC',
        recipient: payment['recipient'] ?? payment['to'],
      );
    } catch (_) {
      return null;
    }
  }

  String _buildPaymentProof({
    required String txHash,
    required double amount,
    required String currency,
    required String recipient,
    required String payer,
  }) {
    final payload = {
      'txHash': txHash,
      'amount': amount,
      'currency': currency,
      'recipient': recipient,
      'payer': payer,
      'chain': 2368,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  void _addHistory(X402Transaction tx) {
    _history.insert(0, tx);
    if (_history.length > 100) _history.removeLast();
    notifyListeners();
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
class PaymentRequirements {
  final double amount;
  final String currency;
  final String recipient;
  PaymentRequirements({
    required this.amount,
    required this.currency,
    required this.recipient,
  });
}

class X402Result {
  final bool success;
  final bool paid;
  final int? statusCode;
  final String? body;
  final String? txHash;
  final double? amountPaid;
  final String? error;
  final PaymentRequirements? requiresApproval;

  X402Result._({
    required this.success,
    this.paid = false,
    this.statusCode,
    this.body,
    this.txHash,
    this.amountPaid,
    this.error,
    this.requiresApproval,
  });

  factory X402Result.success({
    required int statusCode,
    required String body,
    required bool paid,
    String? txHash,
    double? amountPaid,
  }) =>
      X402Result._(
        success: true,
        paid: paid,
        statusCode: statusCode,
        body: body,
        txHash: txHash,
        amountPaid: amountPaid,
      );

  factory X402Result.failed(String error) =>
      X402Result._(success: false, error: error);

  factory X402Result.requiresApproval(PaymentRequirements req) =>
      X402Result._(success: false, requiresApproval: req);
}

class X402Transaction {
  final String url;
  final String method;
  final DateTime startedAt;
  PaymentRequirements? paymentRequired;
  String? txHash;
  int? responseCode;
  String? responseBody;
  String? errorMessage;
  DateTime? completedAt;

  bool get succeeded =>
      responseCode != null && responseCode! >= 200 && responseCode! < 300;

  X402Transaction({
    required this.url,
    required this.method,
    required this.startedAt,
  });

  void complete(int code, String body) {
    responseCode = code;
    responseBody = body;
    completedAt = DateTime.now();
  }

  void fail(String error) {
    errorMessage = error;
    completedAt = DateTime.now();
  }
}
