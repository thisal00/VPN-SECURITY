/// WARP WireGuard configuration builder.
/// Supports both hardcoded fallback keys and dynamically registered keys.
/// Includes multi-endpoint failover for reliability.
class WarpConfig {
  // Fallback hardcoded keys (used if dynamic registration fails)
  static const String _fallbackPrivateKey = "wKU18QIsct8il2wMfjw4QshHEf+HQ6opIYy6FE1lHVc=";
  static const String _fallbackPublicKey = "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";
  static const String _fallbackAddress = "172.16.0.2/32";
  static const String _fallbackEndpoint = "162.159.192.1:2408";

  // Multi-endpoint failover list (try in order if primary fails)
  static const List<String> failoverEndpoints = [
    "162.159.192.1:2408",
    "162.159.193.1:2408",
    "162.159.192.1:4500",
    "162.159.192.1:1701",
    "162.159.193.1:4500",
    "162.159.192.1:500",
  ];

  // Network tuning constants
  static const String dns = "1.1.1.1, 1.0.0.1";
  static const int mtu = 1280; // Lower MTU to bypass strict ISP packet inspection
  static const int keepAlive = 25; // Router idle disconnects වැළැක්වීමට

  final String privateKey;
  final String publicKey;
  final String address;
  final String endpoint;

  const WarpConfig._({
    required this.privateKey,
    required this.publicKey,
    required this.address,
    required this.endpoint,
  });

  /// Create a copy with a different endpoint (for failover)
  WarpConfig withEndpoint(String newEndpoint) {
    return WarpConfig._(
      privateKey: privateKey,
      publicKey: publicKey,
      address: address,
      endpoint: newEndpoint,
    );
  }

  /// Create config from dynamically registered API keys
  factory WarpConfig.fromMap(Map<String, String> keys) {
    final ipv4 = keys['local_ipv4'] ?? '';
    final addr = ipv4.isNotEmpty ? '$ipv4/32' : '';

    return WarpConfig._(
      privateKey: keys['private_key'] ?? _fallbackPrivateKey,
      publicKey: keys['peer_public_key'] ?? _fallbackPublicKey,
      address: addr.isNotEmpty && ipv4.isNotEmpty ? addr : _fallbackAddress,
      endpoint: keys['endpoint'] != null && keys['endpoint']!.isNotEmpty
          ? '${keys['endpoint']}:2408'
          : _fallbackEndpoint,
    );
  }

  /// Create config from hardcoded fallback values
  factory WarpConfig.fallback() {
    return const WarpConfig._(
      privateKey: _fallbackPrivateKey,
      publicKey: _fallbackPublicKey,
      address: _fallbackAddress,
      endpoint: _fallbackEndpoint,
    );
  }

  /// Generate the wg-quick compatible config string with AmneziaWG obfuscation
  String generateWgQuickConfig() {
    return '''[Interface]
PrivateKey = $privateKey
Address = $address
DNS = $dns
MTU = $mtu
Jc = 0
Jmin = 0
Jmax = 0
S1 = 0
S2 = 0
H1 = 1
H2 = 2
H3 = 3
H4 = 4

[Peer]
PublicKey = $publicKey
AllowedIPs = 0.0.0.0/0
Endpoint = $endpoint
PersistentKeepalive = $keepAlive''';
  }
}
