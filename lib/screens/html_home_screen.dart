import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:kitepay_app_2026/screens/send_screen.dart'; // Ensure this path is correct
import 'package:kitepay_app_2026/widgets/balance_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Dark-themed HTML Quick Actions
  static const String _htmlQuickActions = '''
    <div style="font-family: sans-serif; padding: 10px 0;">
      <h3 style="color: #94a3b8; font-size: 16px;">Quick Actions</h3>
      <div style="display: flex; gap: 15px;">
        <a href="kitepay://send" style="text-decoration: none; flex: 1;">
          <div style="background: #1e293b; padding: 20px; border-radius: 16px; text-align: center; border: 1px solid #334155; color: white;">
            <b>Send</b>
          </div>
        </a>
        <a href="kitepay://receive" style="text-decoration: none; flex: 1;">
          <div style="background: #1e293b; padding: 20px; border-radius: 16px; text-align: center; border: 1px solid #334155; color: white;">
            <b>Receive</b>
          </div>
        </a>
      </div>
    </div>
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the dark background for the whole screen
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/logo.png',
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.account_balance_wallet, color: Colors.blue),
          ),
        ),
        title: const Text(
          "KitePay",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Balance Card
            BalanceCard(),

            const SizedBox(height: 20),

            // 2. HTML Quick Actions with Navigation Logic
            HtmlWidget(
              _htmlQuickActions,
              onTapUrl: (url) {
                dev.log("Action: $url");

                if (url == "kitepay://send") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SendScreen()),
                  );
                }
                // You can add kitepay://receive logic here later

                return true;
              },
            ),

            const SizedBox(height: 30),

            // 3. Portfolio Analysis Section
            const Text(
              "Portfolio Analysis",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildAnalysisCard(
                  "Weekly Growth",
                  "+12.5%",
                  Icons.trending_up,
                  Colors.greenAccent,
                ),
                const SizedBox(width: 15),
                _buildAnalysisCard(
                  "Assets",
                  "4 Tokens",
                  Icons.pie_chart,
                  Colors.blueAccent,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 4. Native Activity Button
            const Text(
              "Recent Activity",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 15),
            _nativeButton(Icons.history, "View History"),
          ],
        ),
      ),
    );
  }

  // Helper for Analysis Widgets
  Widget _buildAnalysisCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Activity Button Widget
  Widget _nativeButton(IconData icon, String label) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Icon(icon, color: Colors.blue[400]),
        ),
        const SizedBox(width: 15),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}
