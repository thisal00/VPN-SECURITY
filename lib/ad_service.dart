import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoading = false;

  // Use test ID for development. In production, use your actual AdMob unit ID.
  static final String _adUnitId = defaultTargetPlatform == TargetPlatform.android
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  static void loadInterstitialAd() {
    if (_isAdLoading || _interstitialAd != null) return;
    _isAdLoading = true;

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('InterstitialAd loaded.');
          _interstitialAd = ad;
          _isAdLoading = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('InterstitialAd dismissed.');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(); // Load next ad proactively
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('InterstitialAd failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isAdLoading = false;
        },
      ),
    );
  }

  static Future<void> showInterstitialAd(void Function() onAdDismissed) async {
    if (_interstitialAd == null) {
      debugPrint('Warning: attempt to show interstitial before loaded.');
      onAdDismissed(); // Proceed even if ad isn't ready
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd(); // Reload for next time
        onAdDismissed(); // Trigger the VPN connect logic
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        onAdDismissed();
      },
    );

    await _interstitialAd!.show();
  }
}
