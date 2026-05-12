import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:web3dart/web3dart.dart';

class IdentityService extends ChangeNotifier {
  static const _rpc = 'https://rpc-testnet.gokite.ai/';
  static const _chainId = 2368;

  final _uuid = const Uuid();
  AgentIdentity? _identity;
  AgentIdentity? get identity => _identity;

  late Web3Client _client;

  void initialize() {
    _client = Web3Client(_rpc, http.Client());
  }

  // ── Create and attest agent identity on Kite chain ────────────────────────
  Future<AgentIdentity?> createIdentity({
    required String privateKeyHex,
    required String agentName,
    required String agentPurpose,
    required double maxSpendUsdcPerDay,
  }) async {
    try {
      final credentials = EthPrivateKey.fromHex(privateKeyHex);
      final address = credentials.address.hex;
      final agentId = _uuid.v4();

      final identityPayload = {
        'agentId': agentId,
        'agentName': agentName,
        'agentPurpose': agentPurpose,
        'address': address,
        'maxSpendUsdcPerDay': maxSpendUsdcPerDay,
        'chainId': _chainId,
        'createdAt': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      // Sign the identity payload
      final payloadStr = jsonEncode(identityPayload);
      final payloadBytes = Uint8List.fromList(utf8.encode(payloadStr));
      final signature =
          credentials.signPersonalMessageToUint8List(payloadBytes);
      final sigHex = '0x${_bytesToHex(signature)}';

      // Store attestation on Kite chain via a simple ETH transfer
      // with the identity hash in the data field
      final identityHash = _keccak256Hex(payloadStr);

      final txHash = await _client.sendTransaction(
        credentials,
        Transaction(
          to: credentials.address, // self-attestation
          value: EtherAmount.zero(),
          data: Uint8List.fromList(utf8.encode('KiteIdentity:$identityHash')),
          gasPrice: EtherAmount.inWei(BigInt.from(20000000000)),
          maxGas: 50000,
        ),
        chainId: _chainId,
      );

      _identity = AgentIdentity(
        agentId: agentId,
        agentName: agentName,
        agentPurpose: agentPurpose,
        address: address,
        maxSpendUsdcPerDay: maxSpendUsdcPerDay,
        attestationTxHash: txHash,
        signature: sigHex,
        createdAt: DateTime.now(),
      );

      notifyListeners();
      debugPrint('Identity attested: $txHash');
      return _identity;
    } catch (e) {
      debugPrint('createIdentity error: $e');
      return null;
    }
  }

  // ── Verify agent is authorized for a payment ──────────────────────────────
  bool isAuthorized({
    required double amount,
    required double spentToday,
  }) {
    if (_identity == null) return false;
    return (spentToday + amount) <= _identity!.maxSpendUsdcPerDay;
  }

  String _bytesToHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  String _keccak256Hex(String input) {
    // Simple hash for demo — in production use pointycastle keccak256
    final bytes = utf8.encode(input);
    var hash = 0;
    for (final b in bytes) {
      hash = ((hash << 5) - hash) + b;
      hash = hash & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(64, '0');
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }
}

class AgentIdentity {
  final String agentId;
  final String agentName;
  final String agentPurpose;
  final String address;
  final double maxSpendUsdcPerDay;
  final String attestationTxHash;
  final String signature;
  final DateTime createdAt;

  AgentIdentity({
    required this.agentId,
    required this.agentName,
    required this.agentPurpose,
    required this.address,
    required this.maxSpendUsdcPerDay,
    required this.attestationTxHash,
    required this.signature,
    required this.createdAt,
  });
}
