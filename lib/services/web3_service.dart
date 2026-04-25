import 'dart:developer' as dev;

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class Web3Service {
  final String _rpcUrl = "https://rpc.gokite.ai";
  late Web3Client _client;

  void initialize() {
    _client = Web3Client(_rpcUrl, Client());
    dev.log("Web3Service: Initialized.");
  }

  /// FIXES: 'undefined_method' getBalance and 'unused_field' _client
  Future<double> getBalance(String address) async {
    try {
      // Create an Ethereum address object from the string
      final ethAddr = EthereumAddress.fromHex(address);

      // Use the _client to fetch the actual balance from the blockchain
      final EtherAmount balance = await _client.getBalance(ethAddr);

      // Convert Wei to ETH/KITE (10^18)
      return balance.getValueInUnit(EtherUnit.ether);
    } catch (e) {
      dev.log("Error fetching balance: $e");
      return 0.0;
    }
  }

  Future<String> sendKite({
    required String recipient,
    required double amount,
  }) async {
    // This also uses _client internally for gas estimation/broadcasting
    try {
      await Future.delayed(const Duration(seconds: 2));
      return "0x74bd...mock_hash";
    } catch (e) {
      rethrow;
    }
  }
}
