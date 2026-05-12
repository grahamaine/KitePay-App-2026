import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart' show KiteColors;
import '../services/kite_chain_service.dart';
import '../widgets/pay_widget.dart';
import '../widgets/receive_widget.dart';
import '../widgets/send_widget.dart';
import '../widgets/vault_widget.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    context.read<KiteChainService>().initialize();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiteColors.navy900,
      appBar: AppBar(
        title: const Text('Wallet'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: KiteColors.cyan400,
          labelColor: KiteColors.cyan400,
          unselectedLabelColor: KiteColors.grey400,
          tabs: const [
            Tab(icon: Icon(Icons.lock_outline), text: 'Vault'),
            Tab(icon: Icon(Icons.arrow_upward), text: 'Send'),
            Tab(icon: Icon(Icons.arrow_downward), text: 'Receive'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Pay'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          VaultWidget(),
          SendWidget(),
          ReceiveWidget(),
          PayWidget(),
        ],
      ),
    );
  }
}
