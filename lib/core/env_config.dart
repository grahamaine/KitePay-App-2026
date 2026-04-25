import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get orgId => dotenv.get('TURNKEY_ORGANIZATION_ID');
  static String get walletId => dotenv.get('TURNKEY_ETH_WALLET_ID');
  static String get ethAddress => dotenv.get('KITE_ETH_ADDRESS');
  static String get rpcUrl => dotenv.get('ETH_RPC_URL');

  // Use this to check if we are in dev or prod
  static bool get isDev => dotenv.get('ENVIRONMENT') == 'development';
}
