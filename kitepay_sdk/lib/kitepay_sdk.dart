library;

class KiteWallet {
  final String address;
  final double balance;
  KiteWallet({required this.address, required this.balance});
}

abstract class KitePayService {
  Future<KiteWallet> connect();
}