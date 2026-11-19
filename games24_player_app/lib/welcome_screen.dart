import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final bool showLogo;
  const WelcomeScreen({super.key, this.showLogo = true});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/logo.png'), context);
  }

  void _finishWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final topSpacing = math.max(20.0, screenSize.height * 0.14);
    const logoHeight = 90.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F3D1F), // Dark green
              Color(0xFF071F0F), // Very dark green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: topSpacing),

              // Logo & Subtitle
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showLogo)
                    Image.asset(
                      'assets/images/logo.png',
                      height: logoHeight,
                      fit: BoxFit.contain,
                    )
                  else
                    const SizedBox(height: logoHeight),
                  const SizedBox(height: 16),
                  const Text(
                    'Discover, book, and play turfs instantly',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Features Row
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FeatureIcon(
                    icon: Icons.calendar_month_outlined,
                    label: 'Discover',
                  ),
                  _FeatureIcon(
                    icon: Icons.event_available_outlined,
                    label: 'Book',
                  ),
                  _FeatureIcon(
                    icon: Icons.directions_run_outlined,
                    label: 'Play',
                  ),
                ],
              ),

              const Spacer(),

              // Get Started Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _finishWelcome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade400,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios, size: 18),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
              width: 1,
            ),
            color: Colors.green.withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: Colors.greenAccent.shade400, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
