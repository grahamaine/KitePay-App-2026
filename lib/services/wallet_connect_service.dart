import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';

class WalletConnectService extends ChangeNotifier {
  ReownAppKitModal? _modal;
  bool _initialized = false;

  bool get isConnected => _modal?.isConnected ?? false;
  String? get connectedAddress => _modal?.session?.getAddress('eip155');
  ReownAppKitModal? get modal => _modal;

  Future<void> init(BuildContext context) async {
    if (_initialized) return;
    _initialized = true;

    // Register Kite custom chains
    ReownAppKitModalNetworks.addSupportedNetworks('eip155', [
      const ReownAppKitModalNetworkInfo(
        name: 'Kite Testnet',
        chainId: '2368',
        currency: 'KITE',
        rpcUrl: 'https://rpc-testnet.gokite.ai/',
        explorerUrl: 'https://testnet.kitescan.ai',
        isTestNetwork: true,
      ),
      const ReownAppKitModalNetworkInfo(
        name: 'Kite',
        chainId: '2366',
        currency: 'KITE',
        rpcUrl: 'https://rpc.gokite.ai/',
        explorerUrl: 'https://kitescan.ai',
      ),
    ]);

    _modal = ReownAppKitModal(
      context: context,
      projectId: '330707bcc383f56d2f8710e23161f96b',
      metadata: const PairingMetadata(
        name: 'KitePay',
        description: 'Fly further with every payment',
        url: 'https://kitepay.vercel.app',
        icons: ['https://kitepay.vercel.app/icon-192.png'],
        redirect: Redirect(
          native: 'kitepay://wc',
          universal: 'https://kitepay.vercel.app/wc',
          linkMode: true,
        ),
      ),
      featuredWalletIds: {
        'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
        '4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0', // Trust Wallet
        'ef333840daf915aafdc4a004525502d6d49d77bd9c65e0642dbaefb3c2ad8ea', // Rainbow
      },
    );

    try {
      await _modal!.init();
      _modal!.addListener(_onModalChanged);
    } catch (_) {
      _initialized = false;
      _modal = null;
      notifyListeners();
      return;
    }
    notifyListeners();
  }

  void _onModalChanged() {
    notifyListeners();
  }

  void openModal([BuildContext? context]) {
    if (_modal == null || !_initialized) return;
    _modal!.openModalView();
  }

  Future<void> disconnect() async {
    await _modal?.disconnect();
    notifyListeners();
  }

  @override
  void dispose() {
    _modal?.removeListener(_onModalChanged);
    super.dispose();
  }
}
