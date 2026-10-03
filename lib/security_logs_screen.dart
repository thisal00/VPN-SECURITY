import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/cupertino.dart';

class SecurityLogsScreen extends StatelessWidget {
  final List<String> logs;

  const SecurityLogsScreen({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connection Logs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'System events and background tasks',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 18),
              _buildLeakStatusBanner(),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF030712),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: logs.isEmpty
                      ? const Center(
                          child: Text(
                            'No recent events...',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[logs.length - 1 - index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '> ',
                                    style: TextStyle(
                                      color: Color(0xFF00D4FF),
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      log,
                                      style: TextStyle(
                                        color: log.contains('ERROR') || log.contains('failed')
                                            ? const Color(0xFFEF4444)
                                            : log.contains('success') || log.contains('connected')
                                                ? const Color(0xFF22C55E)
                                                : Colors.white70,
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeakStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(CupertinoIcons.checkmark_shield_fill, color: Color(0xFF22C55E), size: 22),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DNS Leak Protection: Active',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22C55E),
                ),
              ),
              Text(
                'Queries are routed securely via VPN tunnel',
                style: TextStyle(fontSize: 10, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
