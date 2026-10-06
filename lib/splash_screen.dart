import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'warp_storage.dart';
import 'onboarding_screen.dart';
import 'main.dart'; // For MainSuperAppShell

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Ads
      await MobileAds.instance.initialize();
      // Check first run
      final isFirstRun = await WarpStorage.isFirstRun();

      // Artificial delay for smooth animation experience
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => isFirstRun ? const OnboardingScreen() : const MainSuperAppShell(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
      // Even if ad init fails, proceed to app
      if (mounted) {
        final isFirstRun = await WarpStorage.isFirstRun();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => isFirstRun ? const OnboardingScreen() : const MainSuperAppShell(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.shield_fill,
                  size: 60,
                  color: Color(0xFF00D4FF),
                ),
              ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack).fadeIn(),
              const SizedBox(height: 24),
              const Text(
                'WARP SHIELD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ).animate().slideY(begin: 0.5, duration: 600.ms, delay: 300.ms).fadeIn(),
              const SizedBox(height: 8),
              const Text(
                'PREMIUM VPN',
                style: TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4.0,
                ),
              ).animate().slideY(begin: 0.5, duration: 600.ms, delay: 500.ms).fadeIn(),
              const SizedBox(height: 48),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF9333EA),
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
