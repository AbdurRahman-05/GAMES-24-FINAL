import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_layout.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Stage 1: Ambient background & center glow (0.0 -> 0.15)
  late Animation<double> _ambientGlowAnimation;
  late Animation<double> _stadiumLightAnimation;

  // Stage 2: Logo elements entering (0.125 -> 0.375) ~ 0.5s - 1.5s
  late Animation<double> _arcEntryAnimation;
  late Animation<double> _arcRotationAnimation;
  late Animation<double> _gSlideAnimation;
  late Animation<double> _twoSlideAnimation;
  late Animation<double> _fourSlideAnimation;
  late Animation<double> _elementsOpacity;

  // Stage 3: Formation lock, shockwave & light sweep (0.375 -> 0.625) ~ 1.5s - 2.5s
  late Animation<double> _shockwaveProgress;
  late Animation<double> _lightSweepPosition;
  late Animation<double> _masterLogoCrossfade;

  // Stage 4: Typography reveal (0.625 -> 0.80) ~ 2.5s - 3.2s
  late Animation<double> _textRevealProgress;
  late Animation<double> _taglineOpacity;

  // Stage 5: Final Presentation & hold (0.80 -> 1.0) ~ 3.2s - 4.0s
  late Animation<double> _finalPulseAnimation;
  late Animation<double> _exitFadeAnimation;

  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Stage 1: 0.0 -> 0.5s (0.0 -> 0.125)
    _ambientGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.125, curve: Curves.easeOut),
      ),
    );

    _stadiumLightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.04, 0.20, curve: Curves.easeInOut),
      ),
    );

    // Stage 2: 0.5s -> 1.5s (0.125 -> 0.375)
    _elementsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.125, 0.22, curve: Curves.easeIn),
      ),
    );

    _arcEntryAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.125, 0.375, curve: Curves.easeOutBack),
      ),
    );

    _arcRotationAnimation = Tween<double>(begin: -0.22, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.125, 0.375, curve: Curves.easeOutCubic),
      ),
    );

    _gSlideAnimation = Tween<double>(begin: -110.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.14, 0.375, curve: Curves.easeOutCubic),
      ),
    );

    _twoSlideAnimation = Tween<double>(begin: 90.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.375, curve: Curves.easeOutCubic),
      ),
    );

    _fourSlideAnimation = Tween<double>(begin: 120.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.375, curve: Curves.easeOutBack),
      ),
    );

    // Stage 3: 1.5s -> 2.5s (0.375 -> 0.625)
    _shockwaveProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.375, 0.52, curve: Curves.easeOutQuad),
      ),
    );

    _masterLogoCrossfade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.375, 0.45, curve: Curves.easeIn),
      ),
    );

    _lightSweepPosition = Tween<double>(begin: -1.6, end: 2.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.625, curve: Curves.easeInOutCubic),
      ),
    );

    // Stage 4: 2.5s -> 3.2s (0.625 -> 0.80)
    _textRevealProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.625, 0.77, curve: Curves.easeOutCubic),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.82, curve: Curves.easeIn),
      ),
    );

    // Stage 5: 3.2s -> 4.0s (0.80 -> 1.0)
    _finalPulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 0.95, curve: Curves.easeInOut),
      ),
    );

    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.94, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });

    _controller.forward();
    _preloadAppData();
  }

  late SharedPreferences _prefs;
  bool _prefsLoaded = false;

  Future<void> _preloadAppData() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _prefsLoaded = true;
    } catch (e) {
      debugPrint('SplashScreen: Error loading prefs: $e');
    }
  }

  void _navigateNext() async {
    if (_navigationTriggered || !mounted) return;
    _navigationTriggered = true;

    if (!_prefsLoaded) {
      _prefs = await SharedPreferences.getInstance();
    }

    if (!mounted) return;

    final isLoggedIn = _prefs.getBool('is_logged_in') ?? false;
    final mobileNumber = _prefs.getString('mobileNumber');
    final hasSeenWelcome = _prefs.getBool('has_seen_welcome') ?? false;

    Widget nextScreen;
    if (isLoggedIn && mobileNumber != null && mobileNumber.isNotEmpty) {
      nextScreen = const MainLayout();
    } else if (hasSeenWelcome) {
      nextScreen = const LoginScreen();
    } else {
      nextScreen = const WelcomeScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final emblemWidth = math.min(screenSize.width * 0.85, 340.0);
    final emblemHeight = emblemWidth / 1.5; // Exactly 1536x1024 aspect ratio

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Opacity(
            opacity: _exitFadeAnimation.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Stadium Lighting & Subtle Atmosphere
                CustomPaint(
                  painter: _StadiumAtmospherePainter(
                    lightIntensity: _stadiumLightAnimation.value,
                    glowIntensity: _ambientGlowAnimation.value,
                    particleTick: _controller.value,
                  ),
                ),

                // 2. Center Ambient Neon Bloom
                Center(
                  child: Container(
                    width: emblemWidth * 1.3,
                    height: emblemHeight * 1.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFD4FF00).withValues(
                            alpha: 0.16 * _ambientGlowAnimation.value,
                          ),
                          const Color(0xFF00E676).withValues(
                            alpha: 0.08 * _ambientGlowAnimation.value,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Shockwave Energy Ring at Component Connection
                if (_shockwaveProgress.value > 0.0 &&
                    _shockwaveProgress.value < 1.0)
                  Center(
                    child: CustomPaint(
                      painter: _ShockwavePainter(
                        progress: _shockwaveProgress.value,
                        baseRadius: emblemWidth * 0.42,
                      ),
                    ),
                  ),

                // 4. Center Assembling Emblem & Brand Reveal
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Transforming Logo Emblem
                      Transform.scale(
                        scale: _finalPulseAnimation.value,
                        child: SizedBox(
                          width: emblemWidth,
                          height: emblemHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Disassembled Animated Components (Stage 2)
                              if (_masterLogoCrossfade.value < 1.0) ...[
                                // Arc / Football Graphic (Enters with scale & rotation)
                                Transform(
                                  alignment: Alignment.centerLeft,
                                  transform: Matrix4.diagonal3Values(
                                    _arcEntryAnimation.value,
                                    _arcEntryAnimation.value,
                                    1.0,
                                  )..rotateZ(_arcRotationAnimation.value),
                                  child: Opacity(
                                    opacity: _elementsOpacity.value,
                                    child: Image.asset(
                                      'assets/images/logo_layer_arc.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                // White 'G' (Slides from Left)
                                Transform.translate(
                                  offset: Offset(_gSlideAnimation.value, 0),
                                  child: Opacity(
                                    opacity: _elementsOpacity.value,
                                    child: Image.asset(
                                      'assets/images/logo_layer_g.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                // Neon-Green '2' (Enters from Right)
                                Transform.translate(
                                  offset: Offset(_twoSlideAnimation.value, 6 * (1 - _controller.value)),
                                  child: Opacity(
                                    opacity: _elementsOpacity.value,
                                    child: Image.asset(
                                      'assets/images/logo_layer_2.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                // Neon-Green '4' (Enters from Top-Right)
                                Transform.translate(
                                  offset: Offset(
                                    _fourSlideAnimation.value,
                                    -_fourSlideAnimation.value * 0.45,
                                  ),
                                  child: Opacity(
                                    opacity: _elementsOpacity.value,
                                    child: Image.asset(
                                      'assets/images/logo_layer_4.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],

                              // Master Unified Logo with Seamless Crossfade & Light Sweep (Stage 3 -> 5)
                              if (_masterLogoCrossfade.value > 0.0)
                                Opacity(
                                  opacity: _masterLogoCrossfade.value,
                                  child: ShaderMask(
                                    shaderCallback: (bounds) {
                                      final sweepX = _lightSweepPosition.value;
                                      return LinearGradient(
                                        begin: Alignment(sweepX - 0.5, -1.0),
                                        end: Alignment(sweepX + 0.5, 1.0),
                                        colors: [
                                          Colors.white.withValues(alpha: 0.0),
                                          Colors.white.withValues(alpha: 0.15),
                                          Colors.white.withValues(alpha: 0.95),
                                          const Color(0xFFD4FF00).withValues(alpha: 0.8),
                                          Colors.white.withValues(alpha: 0.15),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                        stops: const [0.0, 0.35, 0.5, 0.55, 0.7, 1.0],
                                      ).createShader(bounds);
                                    },
                                    blendMode: BlendMode.srcATop,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFD4FF00).withValues(
                                              alpha: 0.22 * _ambientGlowAnimation.value,
                                            ),
                                            blurRadius: 28,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Image.asset(
                                        'assets/images/logo_master.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Stage 4: Horizontal Wipe Brand Name Reveal ("Gamez" in White + "24" in Neon Lime)
                      ClipRect(
                        child: Align(
                          alignment: Alignment.center,
                          widthFactor: _textRevealProgress.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Gamez',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.5,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.white24,
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '24',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.5,
                                    color: const Color(0xFFD4FF00),
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFFD4FF00).withValues(alpha: 0.7),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tagline / Player Badge with tracked letter spacing
                      Opacity(
                        opacity: _taglineOpacity.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFD4FF00).withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sports_soccer_rounded,
                                size: 12,
                                color: Color(0xFFD4FF00),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'PLAY • BOOK • COMPETE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3.0,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Subtle Bottom Version Tag
                Positioned(
                  bottom: 28,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _taglineOpacity.value * 0.7,
                    child: const Center(
                      child: Text(
                        'v1.0 • POWERED BY GAMEZ24',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                          color: Colors.white30,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Custom Stadium Atmosphere & Beams Painter
class _StadiumAtmospherePainter extends CustomPainter {
  final double lightIntensity;
  final double glowIntensity;
  final double particleTick;

  _StadiumAtmospherePainter({
    required this.lightIntensity,
    required this.glowIntensity,
    required this.particleTick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Left Stadium Floodlight Cone
    final leftLightPath = Path()
      ..moveTo(w * 0.12, -30)
      ..lineTo(w * 0.22, -30)
      ..lineTo(w * 0.70, h * 0.75)
      ..lineTo(w * 0.35, h * 0.75)
      ..close();

    final leftLightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.09 * lightIntensity),
          const Color(0xFFD4FF00).withValues(alpha: 0.04 * lightIntensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(leftLightPath, leftLightPaint);

    // 2. Right Stadium Floodlight Cone
    final rightLightPath = Path()
      ..moveTo(w * 0.88, -30)
      ..lineTo(w * 0.78, -30)
      ..lineTo(w * 0.30, h * 0.75)
      ..lineTo(w * 0.65, h * 0.75)
      ..close();

    final rightLightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.09 * lightIntensity),
          const Color(0xFFD4FF00).withValues(alpha: 0.04 * lightIntensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(rightLightPath, rightLightPaint);

    // 3. Subtle Drifting Pitch Particles (12 lightweight sports embers)
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final particleSeeds = [
      [0.20, 0.85, 2.0, 0.35],
      [0.35, 0.72, 1.5, 0.40],
      [0.50, 0.90, 2.4, 0.50],
      [0.65, 0.80, 1.8, 0.38],
      [0.80, 0.68, 2.2, 0.45],
      [0.28, 0.55, 1.6, 0.30],
      [0.72, 0.58, 2.1, 0.42],
      [0.44, 0.40, 1.4, 0.32],
      [0.58, 0.35, 2.3, 0.48],
      [0.15, 0.45, 1.7, 0.28],
      [0.85, 0.48, 2.0, 0.36],
      [0.48, 0.62, 1.9, 0.44],
    ];

    for (int i = 0; i < particleSeeds.length; i++) {
      final s = particleSeeds[i];
      final baseX = s[0];
      final baseY = s[1];
      final radius = s[2];
      final baseAlpha = s[3];

      final yOffset = ((baseY - (particleTick * 0.45)) % 1.0) * h;
      final xOffset = (baseX * w) + (math.sin(particleTick * 6.28 + i) * 12.0);

      particlePaint.color = (i % 2 == 0 ? const Color(0xFFD4FF00) : Colors.white)
          .withValues(alpha: baseAlpha * glowIntensity);

      canvas.drawCircle(Offset(xOffset, yOffset), radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StadiumAtmospherePainter oldDelegate) =>
      oldDelegate.lightIntensity != lightIntensity ||
      oldDelegate.glowIntensity != glowIntensity ||
      oldDelegate.particleTick != particleTick;
}

/// Shockwave Ripple Painter for component lock-in (1.5s)
class _ShockwavePainter extends CustomPainter {
  final double progress;
  final double baseRadius;

  _ShockwavePainter({
    required this.progress,
    required this.baseRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final currentRadius = baseRadius + (progress * 130.0);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    final wavePaint = Paint()
      ..color = const Color(0xFFD4FF00).withValues(alpha: alpha * 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, (1.0 - progress) * 2.8);

    canvas.drawCircle(Offset.zero, currentRadius, wavePaint);

    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset.zero, currentRadius * 0.94, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _ShockwavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
