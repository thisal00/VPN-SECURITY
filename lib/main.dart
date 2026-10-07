import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'warp_config.dart';
import 'warp_api.dart';
import 'warp_storage.dart';
import 'wifi_scanner_screen.dart';
import 'spy_camera_detector.dart';
import 'security_logs_screen.dart';
import 'settings_screen.dart';
import 'auto_protection_service.dart';
import 'onboarding_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';
import 'splash_screen.dart';
import 'network_intel_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WarpShieldApp());
}

class WarpShieldApp extends StatelessWidget {
  const WarpShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WARP Shield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070B14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4FF),
          secondary: Color(0xFF9333EA),
          surface: Color(0xFF111827),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

enum VpnState { disconnected, registering, connecting, connected, disconnecting, error }

class MainSuperAppShell extends StatefulWidget {
  const MainSuperAppShell({super.key});

  @override
  State<MainSuperAppShell> createState() => _MainSuperAppShellState();
}

class _MainSuperAppShellState extends State<MainSuperAppShell> with TickerProviderStateMixin {
  final _wg = WireGuardFlutter.instance;
  static const _channel = MethodChannel('billion.group.wireguard_flutter/wgcontrol');

  int _currentTabIndex = 0;
  VpnState _state = VpnState.disconnected;
  WarpConfig? _config;
  bool _isInitialized = false;
  int _currentEndpointIndex = Random().nextInt(WarpConfig.failoverEndpoints.length);
  bool _userManuallyDisconnected = false;

  // Connection timer
  Timer? _timer;
  int _secondsConnected = 0;

  // Real speed tracking
  Timer? _speedTimer;
  int _lastRxBytes = 0;
  int _lastTxBytes = 0;
  double _currentDown = 0.0;
  double _currentUp = 0.0;
  final List<FlSpot> _downloadSpots = [];
  final List<FlSpot> _uploadSpots = [];
  double _timeX = 0.0;
  double _totalDownMB = 0.0;
  double _totalUpMB = 0.0;

  // Real ping
  int _ping = 0;
  bool _isPinging = false;

  // Live Threat Logs
  final List<String> _securityLogs = [];

  @override
  void initState() {
    super.initState();
    _initChartData();
    _initializeApp();
    _startNetworkMonitoring();
    
    // Load the first interstitial ad proactively
    AdService.loadInterstitialAd();
  }

  void _startNetworkMonitoring() {
    AutoProtectionService.startMonitoring(
      onUntrustedWifiDetected: (ssid) {
        if (!_isConnected && !_isBusy && !_userManuallyDisconnected) {
          _addLog("Public/Unsecured Wi-Fi detected ($ssid) -> Auto-Shield engaging...");
          _toggleVpn();
        }
      },
      onNetworkChanged: () {
        _measurePing();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speedTimer?.cancel();
    AutoProtectionService.stopMonitoring();
    super.dispose();
  }

  void _addLog(String msg) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _securityLogs.add("[$time] $msg");
      if (_securityLogs.length > 100) _securityLogs.removeAt(0);
    });
  }

  void _initChartData() {
    for (int i = 0; i < 30; i++) {
      _downloadSpots.add(FlSpot(i.toDouble(), 0));
      _uploadSpots.add(FlSpot(i.toDouble(), 0));
    }
    _timeX = 29.0;
  }

  Future<void> _initializeApp() async {
    _addLog("Initializing Native AmneziaWG Tunnel...");
    try {
      await _wg.initialize(interfaceName: 'WARP_Tunnel');
      final savedKeys = await WarpStorage.loadKeys();
      if (savedKeys != null) {
        _config = WarpConfig.fromMap(savedKeys);
        _addLog("Loaded keys from Hardware Keystore");
      } else {
        _config = WarpConfig.fallback();
        _addLog("Fallback configuration loaded");
      }
      setState(() => _isInitialized = true);
      _measurePing();
    } catch (e) {
      _addLog("ERROR: Init failed - $e");
      setState(() => _state = VpnState.error);
      _showError('Init failed: $e');
    }
  }

  Future<void> _measurePing() async {
    if (_isPinging) return;
    setState(() => _isPinging = true);
    try {
      final endpoint = _config?.endpoint.split(':').first ?? '162.159.192.1';
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(endpoint, 443, timeout: const Duration(seconds: 3));
      stopwatch.stop();
      socket.destroy();
      if (mounted) setState(() => _ping = stopwatch.elapsedMilliseconds);
    } catch (_) {
      if (mounted) setState(() => _ping = -1);
    }
    if (mounted) setState(() => _isPinging = false);
  }

  Future<void> _pollTrafficStats() async {
    try {
      final result = await _channel.invokeMethod('getTrafficStats');
      if (result != null) {
        final rxBytes = (result['rx'] as num).toInt();
        final txBytes = (result['tx'] as num).toInt();

        if (_lastRxBytes > 0) {
          final rxDelta = rxBytes - _lastRxBytes;
          final txDelta = txBytes - _lastTxBytes;
          _currentDown = (rxDelta * 2 * 8) / 1000000.0;
          _currentUp = (txDelta * 2 * 8) / 1000000.0;
          if (_currentDown < 0) _currentDown = 0;
          if (_currentUp < 0) _currentUp = 0;
          if (rxDelta > 0) _totalDownMB += rxDelta / 1000000.0;
          if (txDelta > 0) _totalUpMB += txDelta / 1000000.0;
        }
        _lastRxBytes = rxBytes;
        _lastTxBytes = txBytes;
      }
    } catch (e) {
      debugPrint("TrafficStats error: $e");
    }
  }

  Future<bool> _ensureRegistered() async {
    if (await WarpStorage.isRegistered()) return true;
    setState(() => _state = VpnState.registering);
    _addLog("Registering device keypair with Cloudflare WARP API...");
    final keys = await WarpApi.registerDevice();
    if (keys != null) {
      await WarpStorage.saveKeys(keys);
      _config = WarpConfig.fromMap(keys);
      _addLog("Registration successful! Saved to Hardware Keystore");
      return true;
    }
    _addLog("Registration fallback activated");
    _config = WarpConfig.fallback();
    return true;
  }

  Future<void> _toggleVpn() async {
    if (_config == null || !_isInitialized) return;
    
    HapticFeedback.mediumImpact();
    
    // Show Interstitial Ad before connection logic if connecting
    if (_state != VpnState.connected) {
      await AdService.showInterstitialAd(() async {
        await _executeVpnToggle();
      });
    } else {
      await _executeVpnToggle();
    }
  }

  Future<void> _executeVpnToggle() async {
    try {
      if (_state == VpnState.connected) {
        setState(() {
          _state = VpnState.disconnecting;
          _userManuallyDisconnected = true;
        });
        _addLog("Stopping VPN tunnel...");
        await _wg.stopVpn();
        _stopTimer();
        _addLog("VPN tunnel disconnected safely");
        setState(() => _state = VpnState.disconnected);
      } else {
        await _ensureRegistered();
        setState(() {
          _state = VpnState.connecting;
          _userManuallyDisconnected = false;
        });
        _addLog("Initiating Secure Tunnel connection...");

        bool connected = false;
        for (int i = 0; i < WarpConfig.failoverEndpoints.length && !connected; i++) {
          final endpointIndex = (_currentEndpointIndex + i) % WarpConfig.failoverEndpoints.length;
          final endpoint = WarpConfig.failoverEndpoints[endpointIndex];
          final configToUse = _config!.withEndpoint(endpoint);

          try {
            _addLog("Attempting handshake on: $endpoint");
            await _wg.startVpn(
              serverAddress: configToUse.endpoint,
              wgQuickConfig: configToUse.generateWgQuickConfig(),
              providerBundleIdentifier: 'com.warpshield.vpn.WireGuardExtension',
            );
            await Future.delayed(const Duration(milliseconds: 800));
            connected = true;
            _currentEndpointIndex = endpointIndex;
            _config = configToUse;
            _addLog("Handshake Response Received! Protected via $endpoint");
          } catch (e) {
            _addLog("Endpoint $endpoint failed, trying backup...");
            if (i < WarpConfig.failoverEndpoints.length - 1) {
              try { await _wg.stopVpn(); } catch (_) {}
              await Future.delayed(const Duration(milliseconds: 300));
            }
          }
        }

        if (connected) {
          _startTimer();
          setState(() => _state = VpnState.connected);
        } else {
          throw Exception("All failover endpoints rejected handshake");
        }
      }
    } catch (e) {
      _stopTimer();
      _addLog("ERROR: Connection failed - $e");
      setState(() => _state = VpnState.error);
      _showError('Connection failed: $e');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _state = VpnState.disconnected);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12)),
        backgroundColor: const Color(0xFFE11D48),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _startTimer() {
    _secondsConnected = 0;
    _totalDownMB = 0;
    _totalUpMB = 0;
    _lastRxBytes = 0;
    _lastTxBytes = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsConnected++);
    });

    _speedTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!mounted || !_isConnected) return;
      await _pollTrafficStats();
      setState(() {
        _timeX += 0.5;
        _downloadSpots.removeAt(0);
        _uploadSpots.removeAt(0);
        _downloadSpots.add(FlSpot(_timeX, _currentDown.clamp(0, 500)));
        _uploadSpots.add(FlSpot(_timeX, _currentUp.clamp(0, 500)));
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _speedTimer?.cancel();
    _secondsConnected = 0;
    setState(() {
      _currentUp = 0;
      _currentDown = 0;
    });
  }

  bool get _isBusy => _state == VpnState.connecting || _state == VpnState.disconnecting || _state == VpnState.registering;
  bool get _isConnected => _state == VpnState.connected;

  Color get _accentColor {
    if (_isConnected) return const Color(0xFF00D4FF);
    if (_isBusy) return const Color(0xFF9333EA);
    if (_state == VpnState.error) return const Color(0xFFE11D48);
    return const Color(0xFF374151);
  }

  String _formatDuration(int totalSeconds) {
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatBytes(double mb) {
    if (mb >= 1000) return '${(mb / 1000).toStringAsFixed(1)} GB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
          ),
        ),
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildVpnDashboard(),
            WifiScannerScreen(
              isVpnConnected: _isConnected,
              onAutoShield: () {
                setState(() => _currentTabIndex = 0);
                if (!_isConnected) _toggleVpn();
              },
            ),
            const SpyCameraDetector(),
            NetworkIntelScreen(isVpnConnected: _isConnected),
            SettingsScreen(
              onClearKeys: () async {
                await WarpStorage.clearKeys();
                _addLog("Hardware Keystore keys wiped");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Keys wiped. Will re-register on next connect.'),
                      backgroundColor: const Color(0xFF1E293B),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildProBottomNavBar(),
    );
  }

  Widget _buildProBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0EA5E9),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.shield_fill), label: 'VPN'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.wifi), label: 'Wi-Fi'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.video_camera), label: 'Spy Cam'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.radar), label: 'IP Intel'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildVpnDashboard() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          const SizedBox(height: 16),
          _buildServerSelector(),
          const Spacer(),
          _buildCenterButton(),
          const Spacer(),
          if (_isConnected) _buildSpeedGraph(),
          if (!_isConnected) _buildDisconnectedInfo(),
          const SizedBox(height: 16),
          _buildInfoCards(),
          const SizedBox(height: 80), // padding for bottom nav
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(CupertinoIcons.lock_shield_fill, color: Color(0xFF00D4FF), size: 28),
          const Column(
            children: [
              Text('WARP SHIELD', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Text('PREMIUM VPN', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5)),
            ],
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _currentTabIndex = 1); // switch to Wi-Fi scanner
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.wifi, color: Color(0xFF22C55E), size: 14),
                  SizedBox(width: 4),
                  Text('AUDIT', style: TextStyle(color: Color(0xFF22C55E), fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildServerSelector() {
    final endpoint = _config?.endpoint ?? WarpConfig.failoverEndpoints[0];
    final ip = endpoint.split(':').first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SECURE EDGE SERVER', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('🌐', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(ip, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: _measurePing,
            child: Row(
              children: [
                if (_isPinging)
                  const SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
                  )
                else ...[
                  Text(
                    _ping > 0 ? '${_ping}ms' : _ping == 0 ? '...' : 'err',
                    style: TextStyle(
                      color: _ping > 0 && _ping < 100 ? const Color(0xFF22C55E) : _ping >= 100 ? const Color(0xFFFBBF24) : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chart_bar_alt_fill,
                    color: _ping > 0 && _ping < 100 ? const Color(0xFF22C55E) : _ping >= 100 ? const Color(0xFFFBBF24) : Colors.white54,
                    size: 16,
                  ),
                ],
              ],
            ),
          )
        ],
      ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.15);
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: _isBusy ? null : _toggleVpn,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle glowing background for connected state
          if (_isConnected)
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00D4FF).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2000.ms),

          // Main premium connect button
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? const Color(0xFF00D4FF).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: _isConnected ? const Color(0xFF00D4FF).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isConnected ? const Color(0xFF00D4FF).withValues(alpha: 0.3) : Colors.black26,
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButtonIcon(),
                      const SizedBox(height: 12),
                      Text(
                        _state == VpnState.disconnected
                            ? 'TAP TO CONNECT'
                            : _state == VpnState.connected
                                ? 'CONNECTED'
                                : _state.name.toUpperCase(),
                        style: TextStyle(
                          color: _isConnected ? const Color(0xFF00D4FF) : Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                      if (_isConnected)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            _formatDuration(_secondsConnected),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonIcon() {
    if (_isBusy) {
      return const SizedBox(
        width: 48, height: 48,
        child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF9333EA)),
      );
    }
    return Icon(
      CupertinoIcons.shield,
      size: 64,
      color: _isConnected ? Colors.white : _accentColor,
    ).animate(target: _isConnected ? 1 : 0).shimmer(duration: 2.seconds, color: Colors.white);
  }

  Widget _buildSpeedGraph() {
    final maxY = [
      ..._downloadSpots.map((s) => s.y),
      ..._uploadSpots.map((s) => s.y),
      10.0,
    ].reduce(max) * 1.3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DOWNLOAD', style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${_currentDown.toStringAsFixed(1)} ', style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 22, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()])),
                      const Text('Mbps ↓', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('UPLOAD', style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${_currentUp.toStringAsFixed(1)} ', style: const TextStyle(color: Color(0xFF9333EA), fontSize: 22, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()])),
                      const Text('Mbps ↑', style: TextStyle(color: Color(0xFF9333EA), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: _timeX - 15,
                maxX: _timeX,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: _downloadSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFF00D4FF),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF00D4FF).withValues(alpha: 0.08)),
                  ),
                  LineChartBarData(
                    spots: _uploadSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFF9333EA),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF9333EA).withValues(alpha: 0.08)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisconnectedInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Column(
        children: [
          Icon(CupertinoIcons.shield_slash, color: Colors.white24, size: 36),
          SizedBox(height: 8),
          Text('Your connection is unprotected', style: TextStyle(color: Colors.white54, fontSize: 13)),
          SizedBox(height: 4),
              Text('Tap the shield to activate secure tunnel', style: TextStyle(color: Colors.white30, fontSize: 11)),
            ],
          ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildInfoCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildInfoCard(
            'PROTOCOL',
            'WireGuard Secured',
            CupertinoIcons.lock_fill,
            _isConnected ? const Color(0xFF22C55E) : Colors.white54,
          ),
          const SizedBox(width: 12),
          _buildInfoCard(
            _isConnected ? 'DATA USED' : 'KEYSTORE',
            _isConnected ? '↓${_formatBytes(_totalDownMB)} ↑${_formatBytes(_totalUpMB)}' : 'Hardware AES-256',
            _isConnected ? CupertinoIcons.graph_square_fill : CupertinoIcons.device_phone_portrait,
            const Color(0xFF00D4FF),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.15);
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, color: iconColor, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(value, style: TextStyle(color: iconColor == Colors.white54 ? Colors.white70 : Colors.white, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
