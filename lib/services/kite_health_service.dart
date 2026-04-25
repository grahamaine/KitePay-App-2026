import 'dart:async';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

enum KiteStatus { healthy, degraded, stuck, offline }

class KiteHealthService {
  final String _rpcUrl = "https://rpc.gokite.ai";
  late Web3Client _client;

  final _healthController = StreamController<KiteHealthMetrics>.broadcast();
  Stream<KiteHealthMetrics> get healthStream => _healthController.stream;

  KiteHealthService() {
    _client = Web3Client(_rpcUrl, Client());
    Timer.periodic(const Duration(seconds: 3), (_) => checkHealth());
  }

  Future<void> checkHealth() async {
    // Create and start the stopwatch in one go using the cascade operator
    final stopwatch = Stopwatch()..start();

    try {
      final block = await _client.getBlockInformation(blockNumber: 'latest');
      final int latency = stopwatch.elapsedMilliseconds;

      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final int blockTimestamp = block.timestamp.millisecondsSinceEpoch ~/ 1000;
      final int drift = now - blockTimestamp;

      KiteStatus status = KiteStatus.healthy;
      if (latency > 800 || drift > 10) status = KiteStatus.degraded;
      if (latency > 3000 || drift > 30) status = KiteStatus.stuck;

      // SUCCESS: Broadcast metrics to the UI
      _healthController.add(
        KiteHealthMetrics(
          latency: latency,
          drift: drift,
          status: status,
          blockNumber: block.blockNumber,
        ),
      );
    } catch (e) {
      // FAILURE: Notify listeners that the service is offline
      _healthController.add(
        KiteHealthMetrics(
          latency: 0,
          drift: 0,
          status: KiteStatus.offline,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void dispose() {
    _healthController.close();
  }
}

class KiteHealthMetrics {
  final int latency;
  final int drift;
  final KiteStatus status;
  final int blockNumber;
  final String? errorMessage;

  KiteHealthMetrics({
    required this.latency,
    required this.drift,
    required this.status,
    this.blockNumber = 0,
    this.errorMessage,
  });
}
