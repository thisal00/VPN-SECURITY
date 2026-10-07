import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:math';

class CellularTrackerScreen extends StatefulWidget {
  const CellularTrackerScreen({super.key});

  @override
  State<CellularTrackerScreen> createState() => _CellularTrackerScreenState();
}

class _CellularTrackerScreenState extends State<CellularTrackerScreen> {
  bool _isScanning = true;
  bool _alarmEnabled = true;
  
  // Simulated data
  int _signalStrength = -85; // dBm
  double _distance = 1.2; // km
  String _networkType = "4G LTE";
  String _band = "Band 3 (1800 MHz)";
  String _cellId = "CID: 4829102";
  
  Timer? _simTimer;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() {
    // Artificial delay for initial scan
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isScanning = false);
    });

    _simTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || _isScanning) return;
      
      final random = Random();
      setState(() {
        // Fluctuate signal between -70 and -115
        _signalStrength += random.nextInt(11) - 5;
        if (_signalStrength > -70) _signalStrength = -70;
        if (_signalStrength < -115) _signalStrength = -115;
        
        // Slightly fluctuate distance as user "moves"
        _distance += (random.nextDouble() * 0.1) - 0.05;
        if (_distance < 0.1) _distance = 0.1;
      });
      
      if (_alarmEnabled && _signalStrength <= -105) {
        _showWeakSignalAlarm();
      }
    });
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  void _showWeakSignalAlarm() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.white),
            SizedBox(width: 10),
            Text('ALARM: Weak Cell Signal Detected!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFFE11D48),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getSignalColor() {
    if (_signalStrength >= -85) return const Color(0xFF22C55E); // Excellent
    if (_signalStrength >= -100) return const Color(0xFFFBBF24); // Fair
    return const Color(0xFFEF4444); // Poor
  }

  String _getSignalQuality() {
    if (_signalStrength >= -85) return "EXCELLENT";
    if (_signalStrength >= -100) return "MODERATE";
    return "POOR / DROPPING";
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return _buildScanningState();
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isScanning = true);
        await Future.delayed(const Duration(seconds: 2));
        setState(() => _isScanning = false);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlarmToggle(),
            const SizedBox(height: 20),
            _buildRadarView(),
            const SizedBox(height: 24),
            _buildSignalStrengthCard(),
            const SizedBox(height: 20),
            _buildTowerDetailsGrid(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80, height: 80,
            child: CircularProgressIndicator(color: Color(0xFF9333EA), strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          const Text('Triangulating Nearest Cell Tower...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Analyzing radio frequencies and bands', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildAlarmToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _alarmEnabled ? const Color(0xFFE11D48).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _alarmEnabled ? const Color(0xFFE11D48).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.bell_fill, color: _alarmEnabled ? const Color(0xFFE11D48) : Colors.white54, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weak Signal Alarm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Alerts when tower signal drops', style: TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ],
          ),
          CupertinoSwitch(
            value: _alarmEnabled,
            activeColor: const Color(0xFFE11D48),
            onChanged: (val) => setState(() => _alarmEnabled = val),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarView() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Radar circles
        for (int i = 1; i <= 3; i++)
          Container(
            width: i * 80.0,
            height: i * 80.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.2)),
            ),
          ),
        // Sweep animation
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                const Color(0xFF9333EA).withValues(alpha: 0.0),
                const Color(0xFF9333EA).withValues(alpha: 0.4),
                const Color(0xFF9333EA).withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ).animate(onPlay: (c) => c.repeat()).rotation(duration: 3.seconds),
        // Tower dot
        Positioned(
          top: 40, right: 60,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Color(0xFF00D4FF), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0xFF00D4FF), blurRadius: 10)]),
            child: const Icon(CupertinoIcons.antenna_radiowaves_left_right, size: 16, color: Colors.black),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 1.seconds),
        ),
        // Distance label
        Positioned(
          top: 20, right: 20,
          child: Text('${_distance.toStringAsFixed(2)} km', style: const TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        // Center Phone
        const Icon(CupertinoIcons.device_phone_portrait, color: Colors.white, size: 32),
      ],
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildSignalStrengthCard() {
    final color = _getSignalColor();
    final quality = _getSignalQuality();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 30)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SIGNAL STRENGTH (dBm)', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(quality, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$_signalStrength', style: TextStyle(color: color, fontSize: 48, fontWeight: FontWeight.w900)),
              const Padding(
                padding: EdgeInsets.only(bottom: 10, left: 4),
                child: Text('dBm', style: TextStyle(color: Colors.white54, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_signalStrength + 120) / 50.0, // map -120..-70 to 0..1
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildTowerDetailsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: [
        _buildDetailCard('NETWORK TYPE', _networkType, CupertinoIcons.bolt_horizontal_fill, const Color(0xFF9333EA)),
        _buildDetailCard('FREQUENCY BAND', _band, CupertinoIcons.waveform_path_ecg, const Color(0xFF00D4FF)),
        _buildDetailCard('TOWER DISTANCE', '${_distance.toStringAsFixed(2)} km', CupertinoIcons.location_fill, const Color(0xFFFBBF24)),
        _buildDetailCard('CELL IDENTIFIER', _cellId, CupertinoIcons.building_2_fill, Colors.white70),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildDetailCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
