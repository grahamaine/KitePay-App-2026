import 'package:flutter/material.dart';
import '../widgets/token_list.dart';
import '../widgets/action_buttons.dart';
import '../widgets/transaction_history.dart';
import '../widgets/html_dashboard_renderer.dart';
import '../widgets/portfolio_card.dart';
import '../widgets/checkout_widget.dart'; // Ensure you import your checkout!

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Drawer for mobile users (the Sidebar becomes a menu)
      drawer: isDesktop ? null : Drawer(child: _buildSidebarContent()),
      appBar: isDesktop 
          ? null 
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              title: const Text("KitePay", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
      body: Row(
        children: [
          if (isDesktop) 
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
              ),
              child: _buildSidebarContent(),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 20, 
                vertical: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  
                  // Adaptive Portfolio Section
                  _buildAdaptiveHero(isDesktop),

                  const SizedBox(height: 40),

                  // Content Grid
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _buildSectionCard(
                        "Assets", 
                        const TokenListWidget(), 
                        width: isDesktop ? (screenWidth - 350) * 0.55 : double.infinity
                      ),
                      _buildSectionCard(
                        "Recent Transactions", 
                        const TransactionHistory(), 
                        width: isDesktop ? (screenWidth - 350) * 0.40 : double.infinity
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  const HtmlDashboardRenderer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveHero(bool isDesktop) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 800) {
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: PortfolioCard(totalBalance: "5,820.12", changePercentage: "+5.2%")),
            SizedBox(width: 24),
            Expanded(flex: 1, child: ActionButtons()),
          ],
        );
      } else {
        return const Column(
          children: [
            PortfolioCard(totalBalance: "5,820.12", changePercentage: "+5.2%"),
            SizedBox(height: 24),
            ActionButtons(),
          ],
        );
      }
    });
  }

  Widget _buildSidebarContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("KitePay", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(height: 40),
          _sidebarItem(Icons.dashboard_rounded, "Dashboard", active: true),
          _sidebarItem(Icons.account_balance_wallet_rounded, "Wallets"),
          _sidebarItem(Icons.swap_horiz_rounded, "Transactions"),
          const Spacer(),
          _sidebarItem(Icons.settings_rounded, "Settings"),
          _sidebarItem(Icons.logout_rounded, "Logout"),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: active ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: active ? Colors.blueAccent : Colors.grey[600], size: 20),
              const SizedBox(width: 16),
              Text(
                label, 
                style: TextStyle(
                  fontWeight: active ? FontWeight.bold : FontWeight.w500, 
                  color: active ? Colors.blueAccent : Colors.black87
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back, User!", style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text("Overview", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          ],
        ),
        // Action button to trigger the Checkout Modal
        ElevatedButton.icon(
          onPressed: () => _showCheckout(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.shopping_cart_outlined, size: 18, color: Colors.white),
          label: const Text("Checkout", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _showCheckout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: const CheckoutWidget(),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget content, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }
}