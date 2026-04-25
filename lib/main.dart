import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import logic and screens
import 'providers/app_providers.dart';
import 'screens/dashboard_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/swap_screen.dart';

void main() {
  runApp(const ProviderScope(child: KitePayApp()));
}

class KitePayApp extends StatelessWidget {
  const KitePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KitePay DApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: const Color(0xFF58A6FF),
        fontFamily: 'Inter',
      ),
      home: const MainLayoutShell(),
    );
  }
}

class MainLayoutShell extends ConsumerStatefulWidget {
  const MainLayoutShell({super.key});

  @override
  ConsumerState<MainLayoutShell> createState() => _MainLayoutShellState();
}

class _MainLayoutShellState extends ConsumerState<MainLayoutShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PortfolioScreen(),
    const SwapScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      body: Row(
        children: [
          // --- SIDEBAR ---
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              border: Border(right: BorderSide(color: Colors.white10, width: 1)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const ListTile(
                  leading: Icon(Icons.tsunami, color: Color(0xFF58A6FF), size: 32),
                  title: Text('KitePay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                const SizedBox(height: 20),
                _navItem(Icons.dashboard_rounded, "Dashboard", 0),
                _navItem(Icons.account_balance_wallet_rounded, "Portfolio", 1),
                _navItem(Icons.swap_horizontal_circle_rounded, "Swap", 2),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildWalletStatusCard(wallet),
                ),
              ],
            ),
          ),

          // --- MAIN CONTENT ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40.0),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      onTap: () => setState(() => _selectedIndex = index),
      leading: Icon(icon, color: isSelected ? const Color(0xFF58A6FF) : Colors.white54),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54)),
    );
  }

  Widget _buildWalletStatusCard(String? wallet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(wallet == null ? "Not Connected" : "Connected", 
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58A6FF),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 40),
            ),
            // ✅ NEW 2026 WAY (Call a method on the Notifier)
onPressed: () {
  if (wallet == null) {
    ref.read(walletProvider.notifier).connect("0xKite...8822");
  } else {
    ref.read(walletProvider.notifier).disconnect();
  }
            },
            child: Text(wallet == null ? "Connect" : "Disconnect"),
          )
        ],
      ),
    );
  }
}
