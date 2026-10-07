import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui' as dart_ui;
import 'warp_storage.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onClearKeys;

  const SettingsScreen({super.key, required this.onClearKeys});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _killSwitch = false;
  bool _autoConnectWifi = true;
  String _dnsMode = 'malware';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final kill = await WarpStorage.getKillSwitch();
    final auto = await WarpStorage.getAutoConnectWifi();
    final dns = await WarpStorage.getDnsMode();
    if (mounted) {
      setState(() {
        _killSwitch = kill;
        _autoConnectWifi = auto;
        _dnsMode = dns;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Manage your connection preferences and security',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('CONNECTION RULES'),
              const SizedBox(height: 10),
              _buildSwitchTile(
                icon: CupertinoIcons.lock_shield,
                title: 'Kill Switch',
                subtitle: 'Block internet access when the VPN connection drops unexpectedly',
                value: _killSwitch,
                onChanged: (val) async {
                  setState(() => _killSwitch = val);
                  await WarpStorage.setKillSwitch(val);
                },
              ),
              const SizedBox(height: 10),
              _buildSwitchTile(
                icon: CupertinoIcons.wifi,
                title: 'Auto-Connect on Wi-Fi',
                subtitle: 'Automatically secure your connection on open or public networks',
                value: _autoConnectWifi,
                onChanged: (val) async {
                  setState(() => _autoConnectWifi = val);
                  await WarpStorage.setAutoConnectWifi(val);
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('DNS PREFERENCES (CLOUDFLARE)'),
              const SizedBox(height: 10),
              _buildDnsRadio(
                title: 'Block Malware',
                subtitle: 'Filters phishing, ransomware, and malicious domains (Recommended)',
                mode: 'malware',
              ),
              const SizedBox(height: 8),
              _buildDnsRadio(
                title: 'Block Malware & Adult Content',
                subtitle: 'Family-friendly filtering mode',
                mode: 'family',
              ),
              const SizedBox(height: 8),
              _buildDnsRadio(
                title: 'Standard DNS',
                subtitle: 'Maximum performance without content filtering',
                mode: 'standard',
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('TROUBLESHOOTING'),
              const SizedBox(height: 10),
              _buildActionTile(
                icon: CupertinoIcons.arrow_2_circlepath_circle_fill,
                title: 'Reset Connection Keys',
                subtitle: 'Clear saved credentials and re-register device with the network',
                buttonText: 'Reset Keys',
                onTap: widget.onClearKeys,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(0xFF00D4FF),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: dart_ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00D4FF), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00D4FF),
          ),
        ],
      ),
          ),
        ),
    );
  }

  Widget _buildDnsRadio({
    required String title,
    required String subtitle,
    required String mode,
  }) {
    final isSelected = _dnsMode == mode;

    return GestureDetector(
      onTap: () async {
        setState(() => _dnsMode = mode);
        await WarpStorage.setDnsMode(mode);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: dart_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00D4FF).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF00D4FF).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
          children: [
            Icon(
              isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: isSelected ? const Color(0xFF00D4FF) : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: dart_ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFEF4444), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
              foregroundColor: const Color(0xFFEF4444),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFEF4444), width: 0.5),
              ),
            ),
            child: Text(buttonText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
          ),
        ),
    );
  }
}
