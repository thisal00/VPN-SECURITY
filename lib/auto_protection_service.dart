import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'warp_storage.dart';

class AutoProtectionService {
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Start background listener for Wi-Fi / Mobile network transitions
  static void startMonitoring({
    required Function(String ssid) onUntrustedWifiDetected,
    required Function() onNetworkChanged,
  }) {
    _subscription?.cancel();
    _subscription = Connectivity().onConnectivityChanged.listen((results) async {
      onNetworkChanged();

      final isWifi = results.contains(ConnectivityResult.wifi);
      if (isWifi) {
        final autoConnect = await WarpStorage.getAutoConnectWifi();
        if (autoConnect) {
          onUntrustedWifiDetected("Auto-Shield Wi-Fi");
        }
      }
    });
  }

  static void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }
}
