import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:web3dart/web3dart.dart';

class KiteChainService extends ChangeNotifier {
  static const String _testnetRpc = 'https://rpc-testnet.gokite.ai/';
  static const String _mainnetRpc = 'https://rpc.gokite.ai/';
  static const int _testnetChainId = 2368;
  static const int _mainnetChainId = 2366;
  static const String _testnetExplorer = 'https://testnet.kitescan.ai';
  static const String _mainnetExplorer = 'https://kitescan.ai';

  // Use testnet for development
  bool _useTestnet = true;
  bool get useTestnet => _useTestnet;

  String get rpcUrl => _useTestnet ? _testnetRpc : _mainnetRpc;
  int get chainId => _useTestnet ? _testnetChainId : _mainnetChainId;
  String get explorerUrl => _useTestnet ? _testnetExplorer : _mainnetExplorer;

  late Web3Client _client;
  bool _isInitialized = false;
  String? _lastError;
  String? get lastError => _lastError;

  final _uuid = const Uuid();

  void initialize() {
    _client = Web3Client(rpcUrl, http.Client());
    _isInitialized = true;
    debugPrint(
        'KiteChainService: initialized on ${_useTestnet ? "testnet" : "mainnet"}');
  }

  void switchNetwork({required bool testnet}) {
    _useTestnet = testnet;
    _client.dispose();
    _client = Web3Client(rpcUrl, http.Client());
    notifyListeners();
  }

  // ── Get KITE balance ──────────────────────────────────────────────────────
  Future<double> getBalance(String address) async {
    _ensureInitialized();
    try {
      final addr = EthereumAddress.fromHex(address);
      final balance = await _client.getBalance(addr);
      return balance.getValueInUnit(EtherUnit.ether);
    } catch (e) {
      _lastError = e.toString();
      debugPrint('getBalance error: $e');
      return 0.0;
    }
  }

  // ── Get transaction history from Kite explorer ────────────────────────────
  Future<List<Map<String, dynamic>>> getTransactions(String address) async {
    try {
      final url = Uri.parse(
        '${_useTestnet ? "https://testnet.kitescan.ai" : "https://kitescan.ai"}'
        '/api?module=account&action=txlist&address=$address&sort=desc&limit=20',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == '1') {
          return List<Map<String, dynamic>>.from(data['result'] ?? []);
        }
      }
    } catch (e) {
      debugPrint('getTransactions error: $e');
    }
    return [];
  }

  // ── Send KITE ─────────────────────────────────────────────────────────────
  Future<String?> sendKite({
    required String privateKeyHex,
    required String toAddress,
    required double amountKite,
    String? memo,
  }) async {
    _ensureInitialized();
    try {
      final credentials = EthPrivateKey.fromHex(privateKeyHex);
      final to = EthereumAddress.fromHex(toAddress);
      final amount = EtherAmount.fromBigInt(
        EtherUnit.wei,
        BigInt.from((amountKite * 1e18).toInt()),
      );

      final txHash = await _client.sendTransaction(
        credentials,
        Transaction(
          to: to,
          value: amount,
          gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 gwei
          maxGas: 21000,
        ),
        chainId: chainId,
      );

      // Store attestation
      await _storeAttestation(
        txHash: txHash,
        type: 'transfer',
        fromAddress: credentials.address.hex,
        toAddress: toAddress,
        amount: amountKite,
        memo: memo,
      );

      return txHash;
    } catch (e) {
      _lastError = _friendlyError(e.toString());
      debugPrint('sendKite error: $e');
      return null;
    }
  }

  // ── AI Agent: pay for API call autonomously ───────────────────────────────
  Future<AgentPaymentResult> agentPayForApiCall({
    required String agentPrivateKey,
    required String serviceAddress,
    required double costKite,
    required String serviceName,
    required Future<Map<String, dynamic>> Function() apiCall,
  }) async {
    _ensureInitialized();
    final attestationId = _uuid.v4();

    try {
      debugPrint('Agent: initiating payment for $serviceName ($costKite KITE)');

      // 1. Pay for the service on-chain
      final txHash = await sendKite(
        privateKeyHex: agentPrivateKey,
        toAddress: serviceAddress,
        amountKite: costKite,
        memo: 'Agent payment: $serviceName | $attestationId',
      );

      if (txHash == null) {
        return AgentPaymentResult(
          success: false,
          error: _lastError ?? 'Payment failed',
          attestationId: attestationId,
        );
      }

      debugPrint('Agent: payment confirmed $txHash, calling service...');

      // 2. Execute the paid API call
      final result = await apiCall();

      // 3. Store on-chain attestation of result
      await _storeAttestation(
        txHash: txHash,
        type: 'agent_api_call',
        fromAddress: serviceAddress,
        toAddress: serviceAddress,
        amount: costKite,
        memo:
            'Service: $serviceName | Result: ${jsonEncode(result).substring(0, 100)}',
      );

      return AgentPaymentResult(
        success: true,
        txHash: txHash,
        attestationId: attestationId,
        serviceResult: result,
      );
    } catch (e) {
      _lastError = e.toString();
      return AgentPaymentResult(
        success: false,
        error: e.toString(),
        attestationId: attestationId,
      );
    }
  }

  // ── Store attestation (proof of action) ───────────────────────────────────
  Future<void> _storeAttestation({
    required String txHash,
    required String type,
    required String fromAddress,
    required String toAddress,
    required double amount,
    String? memo,
  }) async {
    // In production: store on-chain via a contract call or IPFS
    // For demo: log to console and store locally
    final attestation = {
      'txHash': txHash,
      'type': type,
      'from': fromAddress,
      'to': toAddress,
      'amount': amount,
      'memo': memo,
      'timestamp': DateTime.now().toIso8601String(),
      'chain': _useTestnet ? 'kite-testnet' : 'kite-mainnet',
      'explorer': '$explorerUrl/tx/$txHash',
    };
    debugPrint('Attestation stored: ${jsonEncode(attestation)}');
  }

  // ── Estimate gas ──────────────────────────────────────────────────────────
  Future<double> estimateTransferGas() async {
    _ensureInitialized();
    try {
      final gasPrice = await _client.getGasPrice();
      const gasLimit = 21000;
      final gasCostWei = gasPrice.getInWei * BigInt.from(gasLimit);
      return gasCostWei / BigInt.from(1e18.toInt());
    } catch (_) {
      return 0.0003; // fallback estimate
    }
  }

  // ── Validate Ethereum address ─────────────────────────────────────────────
  bool isValidAddress(String address) {
    try {
      EthereumAddress.fromHex(address);
      return address.length == 42 && address.startsWith('0x');
    } catch (_) {
      return false;
    }
  }

  String get explorerTxUrl => '$explorerUrl/tx/';
  String get explorerAddressUrl => '$explorerUrl/address/';

  void _ensureInitialized() {
    if (!_isInitialized) initialize();
  }

  String _friendlyError(String e) {
    if (e.contains('insufficient funds')) return 'Insufficient KITE balance.';
    if (e.contains('nonce')) return 'Transaction nonce error. Try again.';
    if (e.contains('gas')) return 'Gas estimation failed.';
    if (e.contains('timeout')) return 'Network timeout. Check connection.';
    return 'Transaction failed. Please try again.';
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }
}

class AgentPaymentResult {
  final bool success;
  final String? txHash;
  final String attestationId;
  final Map<String, dynamic>? serviceResult;
  final String? error;

  AgentPaymentResult({
    required this.success,
    this.txHash,
    required this.attestationId,
    this.serviceResult,
    this.error,
  });
}
