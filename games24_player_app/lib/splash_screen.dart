import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
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

  // --- Animation Phases across 5.5s (5500ms) ---
  // Phase 1: 0.0s - 0.5s  -> (0.000 to 0.091) Black screen & stadium atmosphere
  // Phase 2: 0.5s - 2.5s  -> (0.091 to 0.455) "GAMEZ24" letter-by-letter reveal
  // Phase 3: 2.5s - 3.8s  -> (0.455 to 0.690) G24 symbol dynamic assembly
  // Phase 4: 3.8s - 4.7s  -> (0.690 to 0.855) Complete official logo formation & glow hold
  // Phase 5: 4.7s - 5.5s  -> (0.855 to 1.000) Smooth fade-out directly to Next Screen

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
  late Animation<double> _symbolOutlineDraw;
  late Animation<double> _shockwaveProgress;
  late Animation<double> _lightSweepPosition;
  late Animation<double> _masterSymbolCrossfade;

  // Wordmark vertical shift when symbol enters above it
  late Animation<double> _wordmarkShiftDown;

  // Phase 4: Complete Logo formation pulse
  late Animation<double> _fullLogoPulse;

  // Phase 5: Smooth fade-out directly into destination screen
  late Animation<double> _splashFadeOut;

  bool _navigationTriggered = false;
  late SharedPreferences _prefs;
  bool _prefsLoaded = false;

  // Sound Effects & Haptics
  AudioPlayer? _audioPlayer;
  bool _isMuted = false;
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
      duration: const Duration(milliseconds: 5500),
    );

    // =========================================================================
    // PHASE 1: 0.0s - 0.5s (0.000 to 0.091)
    // =========================================================================
    _ambientGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.000, 0.091, curve: Curves.easeOut),
      ),
    );

    _stadiumLights = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.020, 0.120, curve: Curves.easeInOut),
      ),
    );

    // =========================================================================
    // PHASE 2: 0.5s - 2.5s (0.091 to 0.455)
    // 7 Official Wordmark Letters: G -> a -> m -> e -> z -> 2 -> 4
    // =========================================================================
    const letterStart = 0.091;
    const letterStep = 0.038;
    for (int i = 0; i < 7; i++) {
      final start = letterStart + (i * letterStep);
      final end = math.min(0.430, start + 0.085);
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
    // PHASE 3: 2.5s - 3.8s (0.455 to 0.690)
    // Symbol Elements Dynamic Assembly
    // =========================================================================
    _wordmarkShiftDown = Tween<double>(begin: 0.0, end: 68.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.440, 0.530, curve: Curves.easeOutCubic),
      ),
    );

    _symbolElementsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.455, 0.530, curve: Curves.easeIn),
      ),
    );

    _symbolArcProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.455, 0.600, curve: Curves.easeOutBack),
      ),
    );

    _symbolArcRotation = Tween<double>(begin: -0.45, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.455, 0.600, curve: Curves.easeOutCubic),
      ),
    );

    _symbolOutlineDraw = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.455, 0.590, curve: Curves.easeOutQuad),
      ),
    );

    _symbolGSlide = Tween<double>(begin: -140.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.465, 0.590, curve: Curves.easeOutCubic),
      ),
    );

    _symbolTwoSlide = Tween<double>(begin: 140.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.485, 0.610, curve: Curves.easeOutCubic),
      ),
    );

    _symbolFourSlide = Tween<double>(begin: 150.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.505, 0.630, curve: Curves.easeOutBack),
      ),
    );

    _shockwaveProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.560, 0.670, curve: Curves.easeOutQuad),
      ),
    );

    _masterSymbolCrossfade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.570, 0.650, curve: Curves.easeIn),
      ),
    );

    _lightSweepPosition = Tween<double>(begin: -1.6, end: 2.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.590, 0.720, curve: Curves.easeInOutCubic),
      ),
    );

    // =========================================================================
    // PHASE 4: 3.8s - 4.7s (0.690 to 0.855)
    // Full Logo Formation Hold & Glow
    // =========================================================================
    _fullLogoPulse = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.690, 0.855, curve: Curves.easeInOut),
      ),
    );

    // =========================================================================
    // PHASE 5: 4.7s - 5.5s (0.855 to 1.000)
    // Smooth cinematic fade-out directly into destination screen
    // =========================================================================
    _splashFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.855, 1.000, curve: Curves.easeInOut),
      ),
    );

    // Sound FX & Haptic Trigger Listener
    _controller.addListener(() {
      final v = _controller.value;
      for (int i = 0; i < 7; i++) {
        final threshold = 0.091 + (i * 0.038);
        if (v >= threshold && !_triggeredHaptics.contains(i)) {
          _triggeredHaptics.add(i);
          HapticFeedback.lightImpact();
        }
      }
      if (v >= 0.455 && !_triggeredHaptics.contains(100)) {
        _triggeredHaptics.add(100);
        HapticFeedback.mediumImpact();
      }
      if (v >= 0.690 && !_triggeredHaptics.contains(200)) {
        _triggeredHaptics.add(200);
        HapticFeedback.heavyImpact();
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });

    _initAudio();
    _controller.forward();
    _preloadSessionData();
  }

  Future<void> _initAudio() async {
    try {
      final player = AudioPlayer();
      _audioPlayer = player;
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setVolume(1.0);
      await player.play(AssetSource('audio/gamez24_intro.wav'));
    } catch (e) {
      debugPrint('SplashScreen audio error: $e');
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _audioPlayer?.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  Future<void> _preloadSessionData() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _prefsLoaded = true;
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
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    try {
      _audioPlayer?.stop();
      _audioPlayer?.dispose();
    } catch (_) {}
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

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Opacity(
            opacity: _splashFadeOut.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ===============================================================
                // LAYER 1: Cinematic Stadium Background (Lights & Particles)
                // ===============================================================
                CustomPaint(
                  painter: _StadiumAtmospherePainter(
                    lightIntensity: _stadiumLights.value,
                    glowIntensity: _ambientGlow.value,
                    particleTick: _controller.value,
                  ),
                ),

                // Center Neon Lime Radial Glow Bloom
                Center(
                  child: Container(
                    width: initialSymbolWidth * 1.5,
                    height: initialSymbolHeight * 1.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFD4FF00).withValues(
                            alpha: 0.16 * _ambientGlow.value,
                          ),
                          const Color(0xFF00E676).withValues(
                            alpha: 0.08 * _ambientGlow.value,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // ===============================================================
                // LAYER 2: Shockwave Energy Ring at Component Lock-in
                // ===============================================================
                if (_shockwaveProgress.value > 0.0 && _shockwaveProgress.value < 1.0)
                  Positioned(
                    top: centerSymbolTop + (initialSymbolHeight / 2),
                    left: screenSize.width / 2,
                    child: CustomPaint(
                      painter: _ShockwavePainter(
                        progress: _shockwaveProgress.value,
                        baseRadius: initialSymbolWidth * 0.45,
                      ),
                    ),
                  ),

                // ===============================================================
                // LAYER 3: Phase 2 "Gamez24" Letter-by-Letter Wordmark Reveal
                // Positioned below the G24 symbol, using exact official typography
                // ===============================================================
                if (_controller.value >= 0.091)
                  Positioned(
                    top: centerSymbolTop +
                        initialSymbolHeight +
                        18.0 -
                        (45.0 * (1.0 - (_wordmarkShiftDown.value / 72.0))),
                    left: (screenSize.width - wordmarkWidth) / 2,
                    width: wordmarkWidth,
                    height: wordmarkHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        for (int i = 0; i < 7; i++)
                          _buildLetterLayer(i, wordmarkWidth, wordmarkHeight),

                        if (_controller.value >= 0.42)
                          Opacity(
                            opacity: math.min(1.0, (_controller.value - 0.42) * 5.0),
                            child: Image.asset(
                              'assets/images/wm_full.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                  ),

                // ===============================================================
                // LAYER 4: Centered Official G24 Symbol Assembly
                // ===============================================================
                if (_controller.value >= 0.455)
                  Positioned(
                    top: centerSymbolTop,
                    left: (screenSize.width - initialSymbolWidth) / 2,
                    width: initialSymbolWidth,
                    height: initialSymbolHeight,
                    child: Transform.scale(
                      scale: _fullLogoPulse.value,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_masterSymbolCrossfade.value < 1.0) ...[
                            CustomPaint(
                              painter: _CircularOutlineDrawPainter(
                                progress: _symbolOutlineDraw.value,
                              ),
                            ),
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
                                          alpha: 0.22 * _ambientGlow.value,
                                        ),
                                        blurRadius: 28,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/sym_master.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // ===============================================================
                // LAYER 5: Floating Sound FX Toggle (Top-Right)
                // ===============================================================
                Positioned(
                  top: topPadding + 16,
                  right: 20,
                  child: GestureDetector(
                    onTap: _toggleMute,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: _isMuted ? Colors.white38 : const Color(0xFFD4FF00),
                        size: 18,
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

  Widget _buildLetterLayer(int index, double width, double height) {
    final progress = _letterProgress[index].value;
    if (progress <= 0.0) return const SizedBox.shrink();

    final isGreenNumber = (index >= 5);
    final translateY = 24.0 * (1.0 - progress);
    final scale = 0.6 + (0.4 * progress);

    return Transform.translate(
      offset: Offset(0, translateY),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: isGreenNumber
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4FF00).withValues(alpha: 0.35 * progress),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : null,
            child: Image.asset(
              _letterFiles[index],
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for dynamic neon circular football outline drawing
class _CircularOutlineDrawPainter extends CustomPainter {
  final double progress;

  _CircularOutlineDrawPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final center = Offset(size.width * 0.49, size.height * 0.51);
    final radius = size.height * 0.44;

    final glowPaint = Paint()
      ..color = const Color(0xFFD4FF00).withValues(alpha: 0.25 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final linePaint = Paint()
      ..color = const Color(0xFFD4FF00).withValues(alpha: 0.85 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      glowPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularOutlineDrawPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Dynamic shockwave energy wave that bursts outward when elements unite
class _ShockwavePainter extends CustomPainter {
  final double progress;
  final double baseRadius;

  _ShockwavePainter({required this.progress, required this.baseRadius});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final currentRadius = baseRadius + (progress * 130.0);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = const Color(0xFFD4FF00).withValues(alpha: 0.40 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * (1.0 - progress) + 0.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(Offset.zero, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _ShockwavePainter oldDelegate) {
    return oldDelegate.progress != progress;
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

      final posX = (seedX * size.width + math.sin(particleTick * 6.28 + i) * 18.0) % size.width;
      final posY = (seedY * size.height - (particleTick * speed * size.height)) % size.height;
      final alpha = (math.sin(particleTick * 3.14 + (i * 0.5)).abs() * 0.45 * lightIntensity).clamp(0.0, 1.0);

      particlePaint.color = (i % 3 == 0)
          ? const Color(0xFFD4FF00).withValues(alpha: alpha * 0.6)
          : Colors.white.withValues(alpha: alpha * 0.4);

      canvas.drawCircle(Offset(posX, posY), (i % 2 == 0) ? 1.5 : 1.0, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StadiumAtmospherePainter oldDelegate) {
    return oldDelegate.lightIntensity != lightIntensity ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.particleTick != particleTick;
  }
}
