import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure Storage for WARP Keys using Android Hardware Keystore (AES-256 + TEE).
/// Automatically migrates any legacy plaintext keys from SharedPreferences.
class WarpStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  static const _keyPrivate = 'warp_private_key';
  static const _keyPublic = 'warp_peer_public_key';
  static const _keyIpv4 = 'warp_local_ipv4';
  static const _keyIpv6 = 'warp_local_ipv6';
  static const _keyEndpoint = 'warp_endpoint';
  static const _keyKillSwitch = 'warp_kill_switch';
  static const _keyAutoConnectWifi = 'warp_auto_connect_wifi';
  static const _keyDnsMode = 'warp_dns_mode';

  /// Check if this device has already been registered
  static Future<bool> isRegistered() async {
    final privateKey = await _storage.read(key: _keyPrivate);
    if (privateKey != null && privateKey.isNotEmpty) return true;

    // Check legacy storage & migrate if present
    final prefs = await SharedPreferences.getInstance();
    final legacyKey = prefs.getString(_keyPrivate);
    if (legacyKey != null && legacyKey.isNotEmpty) {
      final legacyKeys = {
        'private_key': legacyKey,
        'peer_public_key': prefs.getString(_keyPublic) ?? '',
        'local_ipv4': prefs.getString(_keyIpv4) ?? '',
        'local_ipv6': prefs.getString(_keyIpv6) ?? '',
        'endpoint': prefs.getString(_keyEndpoint) ?? '',
      };
      await saveKeys(legacyKeys);
      await prefs.clear();
      return true;
    }
    return false;
  }

  /// Save registration keys securely to Android Keystore
  static Future<void> saveKeys(Map<String, String> keys) async {
    await _storage.write(key: _keyPrivate, value: keys['private_key'] ?? '');
    await _storage.write(key: _keyPublic, value: keys['peer_public_key'] ?? '');
    await _storage.write(key: _keyIpv4, value: keys['local_ipv4'] ?? '');
    await _storage.write(key: _keyIpv6, value: keys['local_ipv6'] ?? '');
    await _storage.write(key: _keyEndpoint, value: keys['endpoint'] ?? '');
  }

  /// Load saved keys from Secure Keystore
  static Future<Map<String, String>?> loadKeys() async {
    final privateKey = await _storage.read(key: _keyPrivate);
    if (privateKey == null || privateKey.isEmpty) {
      if (await isRegistered()) {
        return loadKeys();
      }
      return null;
    }

    return {
      'private_key': privateKey,
      'peer_public_key': await _storage.read(key: _keyPublic) ?? '',
      'local_ipv4': await _storage.read(key: _keyIpv4) ?? '',
      'local_ipv6': await _storage.read(key: _keyIpv6) ?? '',
      'endpoint': await _storage.read(key: _keyEndpoint) ?? '',
    };
  }

  /// Settings: Kill Switch
  static Future<bool> getKillSwitch() async {
    final val = await _storage.read(key: _keyKillSwitch);
    return val == 'true';
  }

  static Future<void> setKillSwitch(bool enabled) async {
    await _storage.write(key: _keyKillSwitch, value: enabled.toString());
  }

  /// Settings: Auto-Connect on Public Wi-Fi
  static Future<bool> getAutoConnectWifi() async {
    final val = await _storage.read(key: _keyAutoConnectWifi);
    return val != 'false'; // default true
  }

  static Future<void> setAutoConnectWifi(bool enabled) async {
    await _storage.write(key: _keyAutoConnectWifi, value: enabled.toString());
  }

  /// Settings: DNS Mode ('standard', 'malware', 'family')
  static Future<String> getDnsMode() async {
    return await _storage.read(key: _keyDnsMode) ?? 'malware';
  }

  static Future<void> setDnsMode(String mode) async {
    await _storage.write(key: _keyDnsMode, value: mode);
  }

  /// Clear all saved keys (for re-registration)
  static Future<void> clearKeys() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('first_run_completed') != true;
  }

  static Future<void> setFirstRun(bool isFirstRun) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_run_completed', !isFirstRun);
  }
}
