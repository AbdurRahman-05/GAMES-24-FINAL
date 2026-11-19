import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'main_layout.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // --- Animation Phases across 6.0s (6000ms) ---
  // Phase 1: 0.0s - 0.5s  -> (0.000 to 0.083) Black screen & stadium atmosphere
  // Phase 2: 0.5s - 2.5s  -> (0.083 to 0.417) "GAMEZ24" letter-by-letter reveal
  // Phase 3: 2.5s - 3.8s  -> (0.417 to 0.633) G24 symbol dynamic assembly
  // Phase 4: 3.8s - 4.5s  -> (0.633 to 0.750) Complete official logo formation
  // Phase 5: 4.5s - 6.0s  -> (0.750 to 1.000) Seamless continuous symbol travel to next screen

  // Phase 1: Ambient background & center glow
  late Animation<double> _ambientGlow;
  late Animation<double> _stadiumLights;

  // Phase 2: 7 Official Wordmark Letters: G (0), a (1), m (2), e (3), z (4), 2 (5), 4 (6)
  final List<Animation<double>> _letterProgress = [];

  // Phase 3: Symbol Assembly
  late Animation<double> _symbolArcProgress;
  late Animation<double> _symbolArcRotation;
  late Animation<double> _symbolGSlide;
  late Animation<double> _symbolTwoSlide;
  late Animation<double> _symbolFourSlide;
  late Animation<double> _symbolElementsOpacity;
  late Animation<double> _lightSweepPosition;
  late Animation<double> _masterSymbolCrossfade;

  // Wordmark vertical shift when symbol enters above it
  late Animation<double> _wordmarkShiftDown;

  // Phase 4: Complete Logo formation pulse
  late Animation<double> _fullLogoPulse;

  // Phase 5: Continuous transition to next screen
  late Animation<double> _wordmarkFadeOut;
  late Animation<double> _nextScreenFadeIn;
  late Animation<double> _emblemYTransition;
  late Animation<double> _splashBackgroundFadeOut;

  bool _navigationTriggered = false;
  late SharedPreferences _prefs;
  bool _prefsLoaded = false;
  bool _isLoggedIn = false;
  bool _hasSeenWelcome = false;
  Widget _nextScreenWidget = const WelcomeScreen(showLogo: false);

  final Set<int> _triggeredHaptics = {};

  final List<String> _letterFiles = [
    'assets/images/wm_g.png',
    'assets/images/wm_a.png',
    'assets/images/wm_m.png',
    'assets/images/wm_e.png',
    'assets/images/wm_z.png',
    'assets/images/wm_2.png',
    'assets/images/wm_4.png',
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );

    // =========================================================================
    // PHASE 1: 0.0s - 0.5s (0.000 to 0.083)
    // =========================================================================
    _ambientGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.000, 0.083, curve: Curves.easeOut),
      ),
    );

    _stadiumLights = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.020, 0.120, curve: Curves.easeInOut),
      ),
    );

    // =========================================================================
    // PHASE 2: 0.5s - 2.5s (0.083 to 0.417)
    // 7 Official Wordmark Letters: G -> a -> m -> e -> z -> 2 -> 4
    // =========================================================================
    const letterStart = 0.083;
    const letterStep = 0.038;
    for (int i = 0; i < 7; i++) {
      final start = letterStart + (i * letterStep);
      final end = math.min(0.417, start + 0.085);
      _letterProgress.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
      );
    }

    // =========================================================================
    // PHASE 3: 2.5s - 3.8s (0.417 to 0.633)
    // Symbol Elements Dynamic Assembly
    // =========================================================================
    _wordmarkShiftDown = Tween<double>(begin: 0.0, end: 68.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.400, 0.490, curve: Curves.easeOutCubic),
      ),
    );

    _symbolElementsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.417, 0.490, curve: Curves.easeIn),
      ),
    );

    _symbolArcProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.417, 0.560, curve: Curves.easeOutBack),
      ),
    );

    _symbolArcRotation = Tween<double>(begin: -0.45, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.417, 0.560, curve: Curves.easeOutCubic),
      ),
    );

    _symbolGSlide = Tween<double>(begin: -140.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.430, 0.550, curve: Curves.easeOutCubic),
      ),
    );

    _symbolTwoSlide = Tween<double>(begin: 140.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.450, 0.570, curve: Curves.easeOutCubic),
      ),
    );

    _symbolFourSlide = Tween<double>(begin: 150.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.470, 0.590, curve: Curves.easeOutBack),
      ),
    );

    _masterSymbolCrossfade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.530, 0.600, curve: Curves.easeIn),
      ),
    );

    _lightSweepPosition = Tween<double>(begin: -1.6, end: 2.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.550, 0.670, curve: Curves.easeInOutCubic),
      ),
    );

    // =========================================================================
    // PHASE 4: 3.8s - 4.5s (0.633 to 0.750)
    // Full Logo Formation Hold & Glow
    // =========================================================================
    _fullLogoPulse = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.633, 0.750, curve: Curves.easeInOut),
      ),
    );

    // =========================================================================
    // PHASE 5: 4.5s - 6.0s (0.750 to 1.000)
    // Seamless Continuous Symbol Travel to Destination Screen
    // =========================================================================
    _wordmarkFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.750, 0.830, curve: Curves.easeIn),
      ),
    );

    _splashBackgroundFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.780, 0.940, curve: Curves.easeInOut),
      ),
    );

    _nextScreenFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.790, 0.970, curve: Curves.easeIn),
      ),
    );

    _emblemYTransition = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.750, 0.960, curve: Curves.easeInOutCubic),
      ),
    );

    // Sound FX & Haptic Trigger Listener
    _controller.addListener(() {
      final v = _controller.value;
      for (int i = 0; i < 7; i++) {
        final threshold = 0.083 + (i * 0.038);
        if (v >= threshold && !_triggeredHaptics.contains(i)) {
          _triggeredHaptics.add(i);
          HapticFeedback.lightImpact();
        }
      }
      if (v >= 0.417 && !_triggeredHaptics.contains(100)) {
        _triggeredHaptics.add(100);
        HapticFeedback.mediumImpact();
      }
      if (v >= 0.633 && !_triggeredHaptics.contains(200)) {
        _triggeredHaptics.add(200);
        HapticFeedback.heavyImpact();
      }
      if (v >= 0.750 && !_triggeredHaptics.contains(300)) {
        _triggeredHaptics.add(300);
        HapticFeedback.selectionClick();
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });

    _controller.forward();
    _preloadSessionData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/logo.png'), context);
  }

  Future<void> _preloadSessionData() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _prefsLoaded = true;

      final isLoggedIn = _prefs.getBool('is_logged_in') ?? false;
      final mobileNumber = _prefs.getString('mobileNumber');
      final hasSeenWelcome = _prefs.getBool('has_seen_welcome') ?? false;

      if (mounted) {
        setState(() {
          _isLoggedIn =
              (isLoggedIn && mobileNumber != null && mobileNumber.isNotEmpty);
          _hasSeenWelcome = hasSeenWelcome;
          if (_isLoggedIn) {
            _nextScreenWidget = const MainLayout();
          } else if (hasSeenWelcome) {
            _nextScreenWidget = const LoginScreen(showLogo: false);
          } else {
            _nextScreenWidget = const WelcomeScreen(showLogo: false);
          }
        });
      }
    } catch (e) {
      debugPrint('SplashScreen: Error preloading prefs: $e');
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
        transitionDuration: Duration.zero,
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
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final topPadding = mediaQuery.padding.top;

    // G24 Symbol Base Dimensions in Center
    // Original symbol aspect ratio: 930x440 -> 2.113
    final initialSymbolWidth = math.min(screenSize.width * 0.72, 280.0);
    final initialSymbolHeight = initialSymbolWidth / 2.113;

    // Wordmark Dimensions
    // Original wordmark aspect ratio: 1144x150 -> 7.626
    final wordmarkWidth = math.min(screenSize.width * 0.78, 300.0);
    final wordmarkHeight = wordmarkWidth / 7.626;

    // Center symbol top position
    final centerSymbolTop = (screenSize.height - initialSymbolHeight) / 2 - 45;

    // Target position on destination screen header:
    // On LoginScreen: SafeArea (topPadding) + Padding(all: 24.0) -> exact top is topPadding + 24.0
    final topSpacing = math.max(20.0, screenSize.height * 0.14);
    final targetSymbolTop = _hasSeenWelcome ? (topPadding + 24.0) : (topPadding + topSpacing);
    final targetSymbolHeight = _hasSeenWelcome ? 80.0 : 90.0;
    final targetSymbolWidth = targetSymbolHeight * (1098.0 / 487.0);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final currentTop =
              (centerSymbolTop * (1.0 - _emblemYTransition.value)) +
              (targetSymbolTop * _emblemYTransition.value);
          final currentHeight =
              (initialSymbolHeight * (1.0 - _emblemYTransition.value)) +
              (targetSymbolHeight * _emblemYTransition.value);
          final currentWidth =
              (initialSymbolWidth * (1.0 - _emblemYTransition.value)) +
              (targetSymbolWidth * _emblemYTransition.value);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: Next Screen Underneath
              if (_controller.value >= 0.75)
                Opacity(
                  opacity: _nextScreenFadeIn.value,
                  child: IgnorePointer(
                    ignoring: _controller.value < 0.98,
                    child: _nextScreenWidget,
                  ),
                ),

              // Layer 2: Stadium Background & Lights (Clean atmosphere without round circle)
              if (_splashBackgroundFadeOut.value > 0.0)
                Opacity(
                  opacity: _splashBackgroundFadeOut.value,
                  child: CustomPaint(
                    painter: _StadiumAtmospherePainter(
                      lightIntensity: _stadiumLights.value,
                      glowIntensity: _ambientGlow.value,
                      particleTick: _controller.value,
                    ),
                  ),
                ),

              // Layer 4: Phase 2 "Gamez24" Wordmark Letter-by-Letter
              if (_wordmarkFadeOut.value > 0.0 && _controller.value >= 0.083)
                Positioned(
                  top:
                      centerSymbolTop +
                      initialSymbolHeight +
                      18.0 -
                      (42.0 * (1.0 - (_wordmarkShiftDown.value / 68.0))),
                  left: (screenSize.width - wordmarkWidth) / 2,
                  width: wordmarkWidth,
                  height: wordmarkHeight + 40,
                  child: Opacity(
                    opacity: _wordmarkFadeOut.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: wordmarkWidth,
                          height: wordmarkHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              for (int i = 0; i < 7; i++)
                                _buildLetterLayer(
                                  i,
                                  wordmarkWidth,
                                  wordmarkHeight,
                                ),
                              if (_masterSymbolCrossfade.value > 0.0)
                                Opacity(
                                  opacity: _masterSymbolCrossfade.value,
                                  child: Image.asset(
                                    'assets/images/wm_full.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Opacity(
                          opacity: math.min(
                            1.0,
                            math.max(0.0, (_controller.value - 0.35) * 4.0),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFFD4FF00,
                                ).withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'SPORTS VENUE ECOSYSTEM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3.0,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Layer 5: Traveling G24 Symbol
              if (_controller.value >= 0.417)
                Positioned(
                  top: currentTop,
                  left: (screenSize.width - currentWidth) / 2,
                  width: currentWidth,
                  height: currentHeight,
                  child: Hero(
                    tag: 'gamez24_logo_emblem',
                    child: Transform.scale(
                      scale: _emblemYTransition.value > 0.0
                          ? 1.0
                          : _fullLogoPulse.value,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_masterSymbolCrossfade.value < 1.0 &&
                              _emblemYTransition.value == 0.0) ...[
                            Transform(
                              alignment: Alignment.centerLeft,
                              transform: Matrix4.diagonal3Values(
                                _symbolArcProgress.value,
                                _symbolArcProgress.value,
                                1.0,
                              )..rotateZ(_symbolArcRotation.value),
                              child: Opacity(
                                opacity: _symbolElementsOpacity.value,
                                child: Image.asset(
                                  'assets/images/sym_arc.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(_symbolGSlide.value, 0),
                              child: Opacity(
                                opacity: _symbolElementsOpacity.value,
                                child: Image.asset(
                                  'assets/images/sym_g.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(_symbolTwoSlide.value, 0),
                              child: Opacity(
                                opacity: _symbolElementsOpacity.value,
                                child: Image.asset(
                                  'assets/images/sym_2.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(
                                _symbolFourSlide.value,
                                -_symbolFourSlide.value * 0.45,
                              ),
                              child: Opacity(
                                opacity: _symbolElementsOpacity.value,
                                child: Image.asset(
                                  'assets/images/sym_4.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                          if (_masterSymbolCrossfade.value > 0.0)
                            Opacity(
                              opacity: _masterSymbolCrossfade.value,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Master Symbol with Light Sweep
                                  Opacity(
                                    opacity: (1.0 - _emblemYTransition.value)
                                        .clamp(0.0, 1.0),
                                    child: ShaderMask(
                                      shaderCallback: (bounds) {
                                        final sweepX =
                                            _lightSweepPosition.value;
                                        return LinearGradient(
                                          begin: Alignment(sweepX - 0.5, -1.0),
                                          end: Alignment(sweepX + 0.5, 1.0),
                                          colors: [
                                            Colors.white.withValues(alpha: 0.0),
                                            Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            Colors.white.withValues(
                                              alpha: 0.95,
                                            ),
                                            const Color(
                                              0xFFD4FF00,
                                            ).withValues(alpha: 0.8),
                                            Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            Colors.white.withValues(alpha: 0.0),
                                          ],
                                          stops: const [
                                            0.0,
                                            0.35,
                                            0.5,
                                            0.55,
                                            0.7,
                                            1.0,
                                          ],
                                        ).createShader(bounds);
                                      },
                                      blendMode: BlendMode.srcATop,
                                      child: Image.asset(
                                        'assets/images/sym_master.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  // Official Destination Brand Logo that seamlessly settles onto Login Page
                                  if (_emblemYTransition.value > 0.0)
                                    Opacity(
                                      opacity: _emblemYTransition.value.clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLetterLayer(int index, double width, double height) {
    final progress = _letterProgress[index].value;
    if (progress <= 0.0) return const SizedBox.shrink();

    final translateY = 24.0 * (1.0 - progress);
    final scale = 0.6 + (0.4 * progress);

    return Transform.translate(
      offset: Offset(0, translateY),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Image.asset(
            _letterFiles[index],
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// Stadium lighting atmosphere painter with floodlight cones and drifting embers
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
    if (lightIntensity <= 0.0 && glowIntensity <= 0.0) return;

    final conePaint = Paint()..style = PaintingStyle.fill;

    // Top-Left stadium floodlight beam
    final leftPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.55, size.height * 0.70)
      ..lineTo(size.width * 0.15, size.height * 0.90)
      ..close();

    conePaint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.07 * lightIntensity),
        const Color(0xFFD4FF00).withValues(alpha: 0.03 * lightIntensity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(leftPath, conePaint);

    // Top-Right stadium floodlight beam
    final rightPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.45, size.height * 0.70)
      ..lineTo(size.width * 0.85, size.height * 0.90)
      ..close();

    conePaint.shader = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Colors.white.withValues(alpha: 0.07 * lightIntensity),
        const Color(0xFF00E676).withValues(alpha: 0.03 * lightIntensity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(rightPath, conePaint);

    // Drifting stadium dust / pitch embers
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final rnd = math.Random(42);

    for (int i = 0; i < 28; i++) {
      final seedX = rnd.nextDouble();
      final seedY = rnd.nextDouble();
      final speed = 0.1 + rnd.nextDouble() * 0.25;

      final posX =
          (seedX * size.width + math.sin(particleTick * 6.28 + i) * 18.0) %
          size.width;
      final posY =
          (seedY * size.height - (particleTick * speed * size.height)) %
          size.height;
      final alpha =
          (math.sin(particleTick * 3.14 + (i * 0.5)).abs() *
                  0.45 *
                  lightIntensity)
              .clamp(0.0, 1.0);

      particlePaint.color = (i % 3 == 0)
          ? const Color(0xFFD4FF00).withValues(alpha: alpha * 0.6)
          : Colors.white.withValues(alpha: alpha * 0.4);

      canvas.drawCircle(
        Offset(posX, posY),
        (i % 2 == 0) ? 1.5 : 1.0,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StadiumAtmospherePainter oldDelegate) {
    return oldDelegate.lightIntensity != lightIntensity ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.particleTick != particleTick;
  }
}
