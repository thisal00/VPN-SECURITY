import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WarpApi {
  // Cloudflare Client API Registration Endpoint
  static const String _regUrl = 'https://api.cloudflareclient.com/v0i1909051800/reg';

  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  /// Generate a random 32-byte key and encode as base64.
  /// The WARP API accepts this and returns a proper config.
  static Map<String, String> _generateKeyPair() {
    final rnd = Random.secure();
    final privateBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      privateBytes[i] = rnd.nextInt(256);
    }
    // Clamp for X25519 (standard curve25519 clamping)
    privateBytes[0] &= 248;
    privateBytes[31] &= 127;
    privateBytes[31] |= 64;
    final privateKey = base64.encode(privateBytes);
    return {'private_key': privateKey};
  }

  static Future<Map<String, String>?> registerDevice() async {
    const int maxRetries = 3;
    final keyPair = _generateKeyPair();
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await http.post(
          Uri.parse(_regUrl),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'User-Agent': '1.1.1.1/6.31 (Android 13; Scale/3.00)',
            'Accept-Encoding': 'gzip',
          },
          body: jsonEncode({
            "install_id": _generateRandomString(22),
            "tos": DateTime.now().toIso8601String(),
            "key": keyPair['private_key'],
            "type": "Android",
            "locale": "en_US"
          }),
        ).timeout(const Duration(seconds: 10));

        debugPrint("WARP API Response [Attempt ${attempt + 1}]: ${response.statusCode}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final result = data['result'];
          
          return {
            'private_key': result['config']['private_key'] ?? keyPair['private_key']!,
            'local_ipv4': result['config']['interface']['addresses']['v4'],
            'local_ipv6': result['config']['interface']['addresses']['v6'],
            'peer_public_key': result['config']['peers'][0]['public_key'],
            'endpoint': result['config']['peers'][0]['endpoint']['host'],
          };
        } else if (response.statusCode == 429 || response.statusCode >= 500) {
          debugPrint("WARP API Rate Limited/Server Error: ${response.statusCode}");
          if (attempt < maxRetries) {
            // Exponential backoff with jitter: (2^attempt) + random(0..1000) ms
            final delayMs = (pow(2, attempt) * 1000).toInt() + Random().nextInt(1000);
            debugPrint("Retrying in $delayMs ms...");
            await Future.delayed(Duration(milliseconds: delayMs));
            continue;
          }
        } else {
          debugPrint("WARP API Client Error: ${response.statusCode} - ${response.body}");
          break; // Unrecoverable error
        }
      } catch (e) {
        debugPrint("Registration Error [Attempt ${attempt + 1}]: $e");
        if (attempt < maxRetries) {
          final delayMs = (pow(2, attempt) * 1000).toInt() + Random().nextInt(1000);
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }
    }
    return null;
  }
}
