import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:flutter/cupertino.dart';
import 'wifi_security_service.dart';

class SpyCameraDetector extends StatefulWidget {
  const SpyCameraDetector({super.key});

  @override
  State<SpyCameraDetector> createState() => _SpyCameraDetectorState();
}

class _SpyCameraDetectorState extends State<SpyCameraDetector> with TickerProviderStateMixin {
  bool _isScanning = false;
  bool _hasScanned = false;
  List<WiFiAccessPoint> _suspiciousCameras = [];
  
  // Known hidden camera SSID signatures
  final List<String> _cameraSignatures = [
    'cam', 'ipcam', 'hd-', 'ptz', 'v380', 'blink', 'nest', 'ring', 
    'xiaomi', 'hikvision', 'dahua', 'ezviz', 'wyze', 'spy', '720p', '1080p'
  ];

  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _hasScanned = false;
      _suspiciousCameras.clear();
    });
    
    _radarController.repeat();

    // Give it a realistic scan delay for UX
    await Future.delayed(const Duration(seconds: 3));

    final surrounding = await WifiSecurityService.scanSurroundingNetworks();
    
    final suspicious = surrounding.where((ap) {
      final ssidLower = ap.ssid.toLowerCase();
      // Check if SSID contains any of the camera signatures
      return _cameraSignatures.any((sig) => ssidLower.contains(sig));
    }).toList();

    if (mounted) {
      setState(() {
        _isScanning = false;
        _hasScanned = true;
        _suspiciousCameras = suspicious;
      });
      _radarController.stop();
      _radarController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildRadarScanner(),
              const SizedBox(height: 40),
              if (!_isScanning && !_hasScanned)
                _buildStartInfo()
              else if (_isScanning)
                _buildScanningInfo()
              else
                _buildResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.video_camera, color: Color(0xFFF43F5E), size: 28),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spy Cam Detector',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Find hidden cameras via Wi-Fi signals',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadarScanner() {
    return GestureDetector(
      onTap: _isScanning ? null : _startScan,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ripple
          if (_isScanning)
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.3), width: 2),
              ),
            ).animate(onPlay: (c) => c.repeat())
             .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2), duration: 2.seconds)
             .fadeOut(duration: 2.seconds),
             
          // Inner ripple
          if (_isScanning)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.5), width: 2),
              ),
            ).animate(delay: 1.seconds, onPlay: (c) => c.repeat())
             .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2), duration: 2.seconds)
             .fadeOut(duration: 2.seconds),

          // Central Button
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: _isScanning 
                  ? [const Color(0xFFE11D48), const Color(0xFF9F1239)] 
                  : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _isScanning ? const Color(0xFFE11D48).withOpacity(0.5) : Colors.black54,
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
              border: Border.all(
                color: _isScanning ? const Color(0xFFF43F5E) : const Color(0xFF334155),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                _isScanning ? CupertinoIcons.waveform_path : CupertinoIcons.search,
                size: 48,
                color: _isScanning ? Colors.white : const Color(0xFF94A3B8),
              ).animate(target: _isScanning ? 1 : 0).shimmer(duration: 1.seconds),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartInfo() {
    return Column(
      children: [
        const Text(
          'TAP TO SCAN ROOM',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: const Text(
            'We will scan the surrounding area for hidden Wi-Fi networks typically broadcasted by spy cameras, baby monitors, and covert recording devices.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.5),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildScanningInfo() {
    return Column(
      children: [
        const Text(
          'ANALYZING FREQUENCIES...',
          style: TextStyle(
            color: Color(0xFFF43F5E),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 500.ms),
        const SizedBox(height: 8),
        const Text(
          'Please walk around the room slowly',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_suspiciousCameras.isEmpty) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
            ),
            child: const Column(
              children: [
                Icon(CupertinoIcons.checkmark_shield_fill, color: Color(0xFF22C55E), size: 48),
                SizedBox(height: 12),
                Text(
                  'NO HIDDEN CAMERAS DETECTED',
                  style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  'Your environment appears to be safe from covert Wi-Fi recording devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _startScan,
            icon: const Icon(CupertinoIcons.refresh, color: Color(0xFF94A3B8)),
            label: const Text('Scan Again', style: TextStyle(color: Color(0xFF94A3B8))),
          )
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE11D48).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE11D48).withOpacity(0.5)),
          ),
          child: Column(
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Color(0xFFE11D48), size: 36),
              const SizedBox(height: 8),
              Text(
                '${_suspiciousCameras.length} SUSPICIOUS DEVICES FOUND!',
                style: const TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Detected Signals:',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ..._suspiciousCameras.map((cam) => _buildCameraItem(cam)),
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: _startScan,
            icon: const Icon(CupertinoIcons.refresh, color: Color(0xFF94A3B8)),
            label: const Text('Scan Again', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
        )
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildCameraItem(WiFiAccessPoint ap) {
    // Calculate estimated distance based on signal level (dBm)
    // Very rough estimation: -30 is close (~1m), -80 is far (~20m)
    double distance = 1.0;
    if (ap.level < -30) {
      distance = (ap.level.abs() - 30) / 2.0; 
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.camera_fill, color: Color(0xFFF43F5E), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ap.ssid.isNotEmpty ? ap.ssid : 'Hidden SSID',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'MAC: ${ap.bssid}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, letterSpacing: 1),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Est. Distance', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
              const SizedBox(height: 2),
              Text(
                '~${distance.toStringAsFixed(1)}m',
                style: const TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          )
        ],
      ),
    );
  }
}
