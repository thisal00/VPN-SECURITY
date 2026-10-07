import 'package:flutter/material.dart';
import 'wifi_scanner_screen.dart';
import 'cellular_tracker_screen.dart';

class NetworkScannerScreen extends StatelessWidget {
  final VoidCallback onAutoShield;
  final bool isVpnConnected;

  const NetworkScannerScreen({
    super.key,
    required this.onAutoShield,
    required this.isVpnConnected,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0, // hide actual appbar, just need tab bar
          bottom: const TabBar(
            indicatorColor: Color(0xFF00D4FF),
            labelColor: Color(0xFF00D4FF),
            unselectedLabelColor: Colors.white54,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Wi-Fi Radar'),
              Tab(text: 'Cellular Radar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            WifiScannerScreen(
              onAutoShield: onAutoShield,
              isVpnConnected: isVpnConnected,
            ),
            const CellularTrackerScreen(),
          ],
        ),
      ),
    );
  }
}
