import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'wifi_security_service.dart';

class WifiScannerScreen extends StatefulWidget {
  final VoidCallback onAutoShield;
  final bool isVpnConnected;

  const WifiScannerScreen({
    super.key,
    required this.onAutoShield,
    required this.isVpnConnected,
  });

  @override
  State<WifiScannerScreen> createState() => _WifiScannerScreenState();
}

class _WifiScannerScreenState extends State<WifiScannerScreen> {
  bool _isScanning = true;
  WifiScanResult? _result;
  List<WiFiAccessPoint> _surroundingNetworks = [];

  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _runScan();
  }

  Future<void> _runScan() async {
    if (!mounted) return;
    setState(() {
      _isScanning = true;
      _locationDenied = false;
    });

    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }
    
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() => _locationDenied = true);
    }

    await Future.delayed(const Duration(milliseconds: 1200)); // smooth scanning UX
    final scan = await WifiSecurityService.scanCurrentNetwork();
    final surrounding = await WifiSecurityService.scanSurroundingNetworks();
    
    if (mounted) {
      setState(() {
        _result = scan;
        _surroundingNetworks = surrounding;
        _isScanning = false;
      });
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 50) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return "SECURE";
    if (score >= 50) return "MODERATE RISK";
    return "DANGEROUS";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _runScan,
          color: const Color(0xFF00D4FF),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                if (_isScanning) _buildScanningCard() else if (_result != null) ...[
                  _buildRiskGaugeCard(),
                  const SizedBox(height: 18),
                  _buildAuditMetrics(),
                  const SizedBox(height: 20),
                  _buildActionShieldButton(),
                  const SizedBox(height: 20),
                  if (_result!.issues.isNotEmpty) _buildIssuesCard(),
                  const SizedBox(height: 24),
                  if (_locationDenied) _buildLocationWarning(),
                  if (_surroundingNetworks.isNotEmpty) _buildSurroundingNetworksList(),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wi-Fi Security Scanner',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Analyze network safety before connecting',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
        IconButton(
          onPressed: _isScanning ? null : _runScan,
          icon: const Icon(CupertinoIcons.arrow_clockwise, color: Color(0xFF00D4FF), size: 28),
          tooltip: 'Rescan Network',
        ),
      ],
    );
  }

  Widget _buildScanningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF00D4FF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Scanning Networks...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analyzing encryption and connection security',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildRiskGaugeCard() {
    final score = _result!.securityScore;
    final color = _getScoreColor(score);
    final label = _getScoreLabel(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _result!.ssid,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'BSSID: ${_result!.bssid}',
                    style: const TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 1.1),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: score / 100.0,
                  strokeWidth: 10,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Text(
                    'SAFETY SCORE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildAuditMetrics() {
    return Column(
      children: [
        _buildMetricItem(
          icon: CupertinoIcons.lock_fill,
          title: 'Encryption Type',
          subtitle: _result!.encryptionType,
          statusText: _result!.encryptionType.contains('Open') ? 'UNSECURED' : 'PROTECTED',
          isClean: !_result!.encryptionType.contains('Open'),
        ),
        const SizedBox(height: 10),
        _buildMetricItem(
          icon: CupertinoIcons.doc_text_search,
          title: 'DNS Hijack Check',
          subtitle: _result!.isDnsHijacked ? 'DNS Redirect Detected' : 'Clean & Untampered',
          statusText: _result!.isDnsHijacked ? 'THREAT' : 'PASS',
          isClean: !_result!.isDnsHijacked,
        ),
        const SizedBox(height: 10),
        _buildMetricItem(
          icon: CupertinoIcons.antenna_radiowaves_left_right,
          title: 'Fake / Rogue AP Check',
          subtitle: _result!.isRogueAp ? 'Spoofed MAC Address detected' : 'Authentic Access Point',
          statusText: _result!.isRogueAp ? 'EVIL TWIN' : 'GENUINE',
          isClean: !_result!.isRogueAp,
        ),
        const SizedBox(height: 10),
        _buildMetricItem(
          icon: CupertinoIcons.lock_shield_fill,
          title: 'SSL Interception (MITM)',
          subtitle: _result!.isSslStripped ? 'SSL Strip proxy detected' : 'Certificates Validated',
          statusText: _result!.isSslStripped ? 'RISK' : 'SAFE',
          isClean: !_result!.isSslStripped,
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusText,
    required bool isClean,
  }) {
    final statusColor = isClean ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
                letterSpacing: 0.8,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionShieldButton() {
    final isConnected = widget.isVpnConnected;

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isConnected
              ? [const Color(0xFF0284C7), const Color(0xFF00D4FF)]
              : [const Color(0xFF9333EA), const Color(0xFF00D4FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: widget.onAutoShield,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnected ? CupertinoIcons.shield_fill : CupertinoIcons.shield,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              isConnected ? 'VPN SHIELD ACTIVE (PROTECTED)' : 'AUTO-SHIELD WITH WARP VPN',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  Widget _buildIssuesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Color(0xFFEF4444), size: 18),
              SizedBox(width: 8),
              Text(
                'Security Advisories',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._result!.issues.map(
            (issue) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
                  Expanded(
                    child: Text(
                      issue,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.location_slash_fill, color: Color(0xFFFBBF24), size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Location Permission Required',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFBBF24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Android requires Location permissions to scan for nearby Wi-Fi networks. Please enable it in Settings to see surrounding networks.',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBBF24).withValues(alpha: 0.2),
              foregroundColor: const Color(0xFFFBBF24),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSurroundingNetworksList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nearby Wi-Fi Networks',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ..._surroundingNetworks.take(10).map((ap) {
          final caps = ap.capabilities.toUpperCase();
          final isWpa3 = caps.contains('WPA3');
          final isWpa2 = caps.contains('WPA2') || caps.contains('WPA');
          final isSecure = isWpa3 || isWpa2;
          
          final iconColor = isWpa3 ? const Color(0xFF22C55E) 
                          : isWpa2 ? const Color(0xFF3B82F6) 
                          : const Color(0xFFEF4444);
                          
          final ratingText = isWpa3 ? 'Excellent (WPA3)' 
                           : isWpa2 ? 'Good (WPA2)' 
                           : 'Unsafe (Open/WEP)';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Icon(
                  isSecure ? CupertinoIcons.lock_fill : CupertinoIcons.lock_open_fill,
                  color: iconColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ap.ssid.isNotEmpty ? ap.ssid : 'Hidden Network',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ratingText,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: iconColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ap.capabilities.split('-').first,
                            style: const TextStyle(fontSize: 10, color: Colors.white54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${ap.level} dBm',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          ap.level > -60 ? CupertinoIcons.wifi
                          : ap.level > -70 ? CupertinoIcons.wifi
                          : CupertinoIcons.wifi, 
                          size: 16, 
                          color: Colors.white54
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
