import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

class UsdcService extends ChangeNotifier {
  static final _erc20Abi = ContractAbi.fromJson('''[
    {"constant":true,"inputs":[{"name":"_owner","type":"address"}],
     "name":"balanceOf","outputs":[{"name":"","type":"uint256"}],
     "type":"function"},
    {"constant":false,"inputs":[{"name":"_to","type":"address"},
     {"name":"_value","type":"uint256"}],
     "name":"transfer","outputs":[{"name":"","type":"bool"}],
     "type":"function"},
    {"constant":false,"inputs":[{"name":"_spender","type":"address"},
     {"name":"_value","type":"uint256"}],
     "name":"approve","outputs":[{"name":"","type":"bool"}],
     "type":"function"},
    {"constant":true,"inputs":[{"name":"_owner","type":"address"},
     {"name":"_spender","type":"address"}],
     "name":"allowance","outputs":[{"name":"","type":"uint256"}],
     "type":"function"},
    {"constant":true,"inputs":[],"name":"decimals",
     "outputs":[{"name":"","type":"uint8"}],"type":"function"},
    {"constant":true,"inputs":[],"name":"symbol",
     "outputs":[{"name":"","type":"string"}],"type":"function"},
    {"constant":true,"inputs":[],"name":"totalSupply",
     "outputs":[{"name":"","type":"uint256"}],"type":"function"}
  ]''', 'KitePayToken');

  late Web3Client _client;
  late DeployedContract _contract;
  late ContractFunction _balanceOf;
  late ContractFunction _transfer;
  late ContractFunction _approve;

  bool _initialized = false;
  String? _lastError;
  String? get lastError => _lastError;

  // Spending limits — enforced before any transfer
  double _dailyLimit = 10.0; // USDC per day
  double _perTxLimit = 2.0; // USDC per transaction
  double _spentToday = 0.0;
  DateTime _limitResetAt = DateTime.now().add(const Duration(days: 1));

  double get dailyLimit => _dailyLimit;
  double get perTxLimit => _perTxLimit;
  double get spentToday => _spentToday;
  double get remainingToday =>
      (_dailyLimit - _spentToday).clamp(0, _dailyLimit);

  void setLimits({double? daily, double? perTx}) {
    if (daily != null) _dailyLimit = daily;
    if (perTx != null) _perTxLimit = perTx;
    notifyListeners();
  }

  void initialize() {
    final rpc =
        dotenv.env['KITE_RPC_TESTNET'] ?? 'https://rpc-testnet.gokite.ai/';
    final tokenAddr = dotenv.env['KITE_TOKEN_ADDRESS'] ??
        '0x0105FBf3EDF5297870066ef351E5ca6399b9FF8b';

    _client = Web3Client(rpc, http.Client());
    _contract = DeployedContract(
      _erc20Abi,
      EthereumAddress.fromHex(tokenAddr),
    );
    _balanceOf = _contract.function('balanceOf');
    _transfer = _contract.function('transfer');
    _approve = _contract.function('approve');
    _initialized = true;
    debugPrint('UsdcService: initialized · token $tokenAddr');
  }

  // ── Balance ───────────────────────────────────────────────────────────────
  Future<double> getBalance(String address) async {
    _ensureInit();
    try {
      final result = await _client.call(
        contract: _contract,
        function: _balanceOf,
        params: [EthereumAddress.fromHex(address)],
      );
      final raw = result.first as BigInt;
      return raw / BigInt.from(10).pow(18); // 18 decimals
    } catch (e) {
      _lastError = e.toString();
      return 0.0;
    }
  }

  // ── Transfer with spending guard ──────────────────────────────────────────
  Future<UsdcTransferResult> transfer({
    required String privateKeyHex,
    required String toAddress,
    required double amount,
    String? memo,
  }) async {
    _ensureInit();

    // Reset daily limit if needed
    if (DateTime.now().isAfter(_limitResetAt)) {
      _spentToday = 0.0;
      _limitResetAt = DateTime.now().add(const Duration(days: 1));
    }

    // Enforce per-tx limit
    if (amount > _perTxLimit) {
      return UsdcTransferResult.failed(
        'Amount $amount USDC exceeds per-tx limit of $_perTxLimit USDC',
      );
    }

    // Enforce daily limit
    if (_spentToday + amount > _dailyLimit) {
      return UsdcTransferResult.failed(
        'Daily limit reached. Spent: $_spentToday / $_dailyLimit USDC',
      );
    }

    try {
      final credentials = EthPrivateKey.fromHex(privateKeyHex);
      final to = EthereumAddress.fromHex(toAddress);
      final amountWei = BigInt.from((amount * 1e18).toInt());

      final txHash = await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: _contract,
          function: _transfer,
          parameters: [to, amountWei],
          gasPrice: EtherAmount.inWei(BigInt.from(20000000000)),
          maxGas: 100000,
        ),
        chainId: 2368,
      );

      _spentToday += amount;
      notifyListeners();

      debugPrint('USDC transfer: $amount → $toAddress · tx $txHash');
      return UsdcTransferResult.success(txHash, amount, memo);
    } catch (e) {
      _lastError = _friendlyError(e.toString());
      return UsdcTransferResult.failed(_lastError!);
    }
  }

  // ── Approve spender ───────────────────────────────────────────────────────
  Future<String?> approve({
    required String privateKeyHex,
    required String spenderAddress,
    required double amount,
  }) async {
    _ensureInit();
    try {
      final credentials = EthPrivateKey.fromHex(privateKeyHex);
      final spender = EthereumAddress.fromHex(spenderAddress);
      final amountWei = BigInt.from((amount * 1e18).toInt());

      return await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: _contract,
          function: _approve,
          parameters: [spender, amountWei],
          gasPrice: EtherAmount.inWei(BigInt.from(20000000000)),
          maxGas: 80000,
        ),
        chainId: 2368,
      );
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  void _ensureInit() {
    if (!_initialized) initialize();
  }

  String _friendlyError(String e) {
    if (e.contains('insufficient')) return 'Insufficient token balance.';
    if (e.contains('limit')) return 'Spending limit exceeded.';
    if (e.contains('timeout')) return 'Network timeout.';
    return 'Transfer failed. Try again.';
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }
}

class UsdcTransferResult {
  final bool success;
  final String? txHash;
  final double? amount;
  final String? memo;
  final String? error;

  UsdcTransferResult._({
    required this.success,
    this.txHash,
    this.amount,
    this.memo,
    this.error,
  });

  factory UsdcTransferResult.success(String txHash, double amount,
          [String? memo]) =>
      UsdcTransferResult._(
          success: true, txHash: txHash, amount: amount, memo: memo);

  factory UsdcTransferResult.failed(String error) =>
      UsdcTransferResult._(success: false, error: error);
}
