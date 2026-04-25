import 'package:flutter/material.dart';
import '../../widgets/token_list.dart';
import '../../widgets/action_buttons.dart';
import '../../widgets/transaction_history.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text("Dashboard Overview", 
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        SizedBox(height: 30),
        TokenListWidget(),
        SizedBox(height: 40),
        ActionButtons(),
        SizedBox(height: 40),
        TransactionHistory(),
      ],
    );
  }
}