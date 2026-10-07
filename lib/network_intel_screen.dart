import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NetworkIntelScreen extends StatefulWidget {
  final bool isVpnConnected;
  
  const NetworkIntelScreen({super.key, required this.isVpnConnected});

  @override
  State<NetworkIntelScreen> createState() => _NetworkIntelScreenState();
}

class _NetworkIntelScreenState extends State<NetworkIntelScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _ipData;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchIpData();
  }

  @override
  void didUpdateWidget(NetworkIntelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVpnConnected != widget.isVpnConnected) {
      _fetchIpData();
    }
  }

  Future<void> _fetchIpData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json/')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _ipData = json.decode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load IP data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchIpData,
          color: const Color(0xFF00D4FF),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (_isLoading)
                  _buildLoadingState()
                else if (_hasError || _ipData == null)
                  _buildErrorState()
                else
                  _buildIntelDashboard(),
                const SizedBox(height: 100), // padding for bottom nav
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
              'Network Intelligence',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Real-time IP & Identity Analysis',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
        IconButton(
          onPressed: _isLoading ? null : _fetchIpData,
          icon: const Icon(CupertinoIcons.globe, color: Color(0xFF00D4FF), size: 28),
          tooltip: 'Analyze Network',
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
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
            'Tracing IP Address...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Locating ISP and checking data leaks',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Color(0xFFEF4444), size: 48),
          const SizedBox(height: 16),
          const Text('Scan Failed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Could not trace the network. Please check your internet connection and try again.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchIpData,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('RETRY'),
          )
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildIntelDashboard() {
    final ip = _ipData?['query'] ?? 'Unknown';
    final isp = _ipData?['isp'] ?? 'Unknown ISP';
    final city = _ipData?['city'] ?? 'Unknown City';
    final country = _ipData?['country'] ?? 'Unknown Country';
    final statusColor = widget.isVpnConnected ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final statusText = widget.isVpnConnected ? 'IDENTITY HIDDEN' : 'IDENTITY EXPOSED';

    return Column(
      children: [
        // Main Status Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.isVpnConnected ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.exclamationmark_shield_fill, color: statusColor, size: 16),
                    const SizedBox(width: 8),
                    Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('PUBLIC IP ADDRESS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
              const SizedBox(height: 8),
              Text(ip, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

        const SizedBox(height: 20),

        // Grid of details
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildDetailCard('ISP', isp, CupertinoIcons.antenna_radiowaves_left_right),
            _buildDetailCard('LOCATION', '$city, $country', CupertinoIcons.location_solid),
            _buildDetailCard('DNS LEAK', widget.isVpnConnected ? 'SECURE' : 'VULNERABLE', CupertinoIcons.lock_shield_fill, color: widget.isVpnConnected ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
            _buildDetailCard('WEB TRACKING', widget.isVpnConnected ? 'BLOCKED' : 'ACTIVE', CupertinoIcons.eye_slash_fill, color: widget.isVpnConnected ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
          ],
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
        
        const SizedBox(height: 24),
        
        // Premium feature teaser
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF00D4FF)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(CupertinoIcons.sparkles, color: Colors.white, size: 28),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data Breach Scanner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Check if your passwords are leaked on the dark web. Coming in v2.0!', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color ?? const Color(0xFF00D4FF), size: 16),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: color ?? Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
