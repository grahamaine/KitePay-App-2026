import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:turnkey_api_key_stamper/turnkey_api_key_stamper.dart';
import 'package:turnkey_sdk_flutter/turnkey_sdk_flutter.dart';

class TurnkeyService {
  late TurnkeyClient _client;

  TurnkeyService() {
    _init();
  }

  void _init() {
    final stamper = ApiKeyStamper(
      ApiKeyStamperConfig(
        apiPublicKey: dotenv.get('TURNKEY_API_PUBLIC_KEY'),
        apiPrivateKey: dotenv.get('TURNKEY_API_PRIVATE_KEY'),
      ),
    );

    // Using the 2026 THttpConfig requirements
    _client = TurnkeyClient(
      config: THttpConfig(baseUrl: "https://api.turnkey.com"),
      stamper: stamper,
    );
  }

  TurnkeyClient get client => _client;

  Future<String?> getUserId() async {
    try {
      final response = await _client.getWhoami(
        input: TGetWhoamiBody(
          organizationId: dotenv.get('TURNKEY_ORGANIZATION_ID'),
        ),
      );
      return response.userId;
    } catch (e) {
      // ignore: avoid_print
      print("Turnkey Connection Failed: $e");
      return null;
    }
  }
}
