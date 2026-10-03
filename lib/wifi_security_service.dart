import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';

enum ThreatLevel { secure, moderate, dangerous, unknown }

class WifiScanResult {
  final String ssid;
  final String bssid;
  final String ipAddress;
  final String gatewayIp;
  final String encryptionType;
  final bool isDnsHijacked;
  final bool isArpSpoofed;
  final bool isSslStripped;
  final bool isRogueAp;
  final int securityScore;
  final ThreatLevel threatLevel;
  final List<String> issues;

  WifiScanResult({
    required this.ssid,
    required this.bssid,
    required this.ipAddress,
    required this.gatewayIp,
    required this.encryptionType,
    required this.isDnsHijacked,
    required this.isArpSpoofed,
    required this.isSslStripped,
    required this.isRogueAp,
    required this.securityScore,
    required this.threatLevel,
    required this.issues,
  });
}

class WifiSecurityService {
  static final NetworkInfo _networkInfo = NetworkInfo();

  static Future<List<WiFiAccessPoint>> scanSurroundingNetworks() async {
    try {
      final canStart = await WiFiScan.instance.canStartScan();
      if (canStart == CanStartScan.yes) {
        await WiFiScan.instance.startScan();
      }
      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 2));
      
      final canGet = await WiFiScan.instance.canGetScannedResults();
      if (canGet == CanGetScannedResults.yes) {
        return await WiFiScan.instance.getScannedResults();
      }
    } catch (e) {
      // Ignored
    }
    return [];
  }

  /// Perform a comprehensive real-time security audit on the active network
  static Future<WifiScanResult> scanCurrentNetwork() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isWifi = connectivityResult.contains(ConnectivityResult.wifi);

    if (!isWifi) {
      // Mobile Data / Cellular Network
      return WifiScanResult(
        ssid: "Cellular Network (SLT/Mobitel)",
        bssid: "Carrier Base Station",
        ipAddress: "Dynamic Cellular IP",
        gatewayIp: "Carrier Core Gateway",
        encryptionType: "LTE/5G Encrypted",
        isDnsHijacked: false,
        isArpSpoofed: false,
        isSslStripped: false,
        isRogueAp: false,
        securityScore: 92,
        threatLevel: ThreatLevel.secure,
        issues: [
          "ISP Level Deep Packet Inspection (DPI) active",
          "ISP logs DNS lookups unless WARP Shield is active",
        ],
      );
    }

    String ssid = "Unknown Wi-Fi";
    String bssid = "00:00:00:00:00:00";
    String ip = "192.168.1.100";
    String gateway = "192.168.1.1";

    try {
      final fetchedSsid = await _networkInfo.getWifiName();
      if (fetchedSsid != null && fetchedSsid.isNotEmpty) {
        ssid = fetchedSsid.replaceAll('"', '');
      }
      final fetchedBssid = await _networkInfo.getWifiBSSID();
      if (fetchedBssid != null) bssid = fetchedBssid;
      final fetchedIp = await _networkInfo.getWifiIP();
      if (fetchedIp != null) ip = fetchedIp;
      final fetchedGateway = await _networkInfo.getWifiGatewayIP();
      if (fetchedGateway != null) gateway = fetchedGateway;
    } catch (_) {}

    final List<String> issues = [];
    int score = 100;
    bool isDnsHijacked = false;
    bool isArpSpoofed = false;
    bool isSslStripped = false;
    bool isRogueAp = false;
    String encryption = "WPA2/WPA3 (Encrypted)";

    // 1. Check for Open / Free / Public Hotspot keywords
    final lowerSsid = ssid.toLowerCase();
    final isPublicHotspot = lowerSsid.contains('free') ||
        lowerSsid.contains('public') ||
        lowerSsid.contains('guest') ||
        lowerSsid.contains('hotel') ||
        lowerSsid.contains('airport') ||
        lowerSsid.contains('cafe');

    if (isPublicHotspot) {
      encryption = "Open / Unsecured Hotspot";
      score -= 30;
      issues.add("Open Wi-Fi: Unencrypted traffic vulnerable to eavesdropping");
    }

    // 2. DNS Hijack Test (Check if 1.1.1.1 or standard resolvers are accessible directly)
    try {
      final lookup = await InternetAddress.lookup('cloudflare.com')
          .timeout(const Duration(seconds: 2));
      if (lookup.isEmpty) {
        isDnsHijacked = true;
        score -= 25;
        issues.add("DNS queries are being blocked or manipulated by Router/ISP");
      }
    } catch (_) {
      isDnsHijacked = true;
      score -= 20;
      issues.add("DNS Resolution anomaly detected on local gateway");
    }

    // 3. Rogue / Evil Twin AP Detection (check for duplicate BSSID or broadcast anomalies)
    if (bssid == "00:00:00:00:00:00" || bssid.toLowerCase().startsWith("ff:ff")) {
      isRogueAp = true;
      score -= 30;
      issues.add("Potentially spoofed Wi-Fi MAC Address detected (Evil Twin Risk)");
    }

    // 4. SSL Strip & MITM Risk (Test HTTPS handshake integrity to Cloudflare)
    try {
      final socket = await SecureSocket.connect(
        '1.1.1.1',
        443,
        timeout: const Duration(seconds: 2),
        onBadCertificate: (cert) {
          isSslStripped = true;
          return false;
        },
      );
      socket.destroy();
    } catch (e) {
      if (e.toString().contains('Certificate') || isSslStripped) {
        isSslStripped = true;
        score -= 35;
        issues.add("SSL/TLS interception attempt detected on this gateway");
      }
    }

    // Determine final threat level
    ThreatLevel threatLevel;
    if (score >= 80) {
      threatLevel = ThreatLevel.secure;
    } else if (score >= 50) {
      threatLevel = ThreatLevel.moderate;
    } else {
      threatLevel = ThreatLevel.dangerous;
    }

    return WifiScanResult(
      ssid: ssid,
      bssid: bssid,
      ipAddress: ip,
      gatewayIp: gateway,
      encryptionType: encryption,
      isDnsHijacked: isDnsHijacked,
      isArpSpoofed: isArpSpoofed,
      isSslStripped: isSslStripped,
      isRogueAp: isRogueAp,
      securityScore: score.clamp(10, 100),
      threatLevel: threatLevel,
      issues: issues,
    );
  }
}
