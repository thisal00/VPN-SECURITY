import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'warp_storage.dart';
import 'main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    await WarpStorage.setFirstRun(false);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainSuperAppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F172A), Color(0xFF020617)],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildPage(
                        icon: CupertinoIcons.shield_fill,
                        title: 'WARP Shield\nPremium VPN',
                        description: 'Ultra-fast, secure, and private internet access powered by Cloudflare\'s global edge network.',
                        color: const Color(0xFF00D4FF),
                      ),
                      _buildPage(
                        icon: CupertinoIcons.wifi,
                        title: 'Smart Wi-Fi\nSecurity Scanner',
                        description: 'Automatically detects DNS hijacking, rogue access points, and unencrypted networks to keep you safe.',
                        color: const Color(0xFF22C55E),
                      ),
                      _buildPrivacyPage(),
                    ],
                  ),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({required IconData icon, required String title, required String description, required Color color}) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, size: 80, color: color),
          ).animate().scale(duration: 500.ms).fadeIn(),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().slideY(begin: 0.2, duration: 400.ms).fadeIn(),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ).animate().slideY(begin: 0.2, delay: 100.ms, duration: 400.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildPrivacyPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF9333EA).withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(CupertinoIcons.lock_shield_fill, size: 80, color: Color(0xFF9333EA)),
          ).animate().scale(duration: 500.ms).fadeIn(),
          const SizedBox(height: 32),
          const Text(
            'Your Privacy,\nGuaranteed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().slideY(begin: 0.2, duration: 400.ms).fadeIn(),
          const SizedBox(height: 24),
          
          // Google Play VpnService Disclosure
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF9333EA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.3)),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.info_circle_fill, color: Color(0xFF9333EA), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'VPN Service Required',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'WARP Shield uses Android\'s VpnService to create a secure, encrypted tunnel for your internet traffic. This prevents ISPs and hackers from monitoring your activity.\n\nWe do not log your traffic or sell your data. By continuing, you agree to our Privacy Policy.',
                  style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.2, delay: 200.ms, duration: 400.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32, bottom: 48),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? const Color(0xFF00D4FF) : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentPage == 2 ? 'ACCEPT & CONTINUE' : 'NEXT',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
