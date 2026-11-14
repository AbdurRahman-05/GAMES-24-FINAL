import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../admin/presentation/screens/admin_login_screen.dart';
import '../../../admin/providers/admin_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
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
  late Animation<double> _symbolOutlineDraw;
  late Animation<double> _shockwaveProgress;
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
    // Letter-by-letter reveal for original official typography
    // G (0.083), a (0.120), m (0.156), e (0.192), z (0.228), 2 (0.264), 4 (0.300)
    // Hold complete wordmark 0.350 to 0.417
    // =========================================================================
    const letterStart = 0.083;
    const letterStep = 0.036;
    for (int i = 0; i < 7; i++) {
      final start = letterStart + (i * letterStep);
      final end = math.min(1.0, start + 0.075);
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
    // G24 Symbol Assembly above the wordmark
    // =========================================================================
    _wordmarkShiftDown = Tween<double>(begin: 0.0, end: 72.0).animate(
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

    _symbolArcProgress = Tween<double>(begin: 0.60, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.417, 0.560, curve: Curves.easeOutBack),
      ),
    );

    _symbolArcRotation = Tween<double>(begin: -0.25, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.417, 0.560, curve: Curves.easeOutCubic),
      ),
    );

    _symbolOutlineDraw = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.417, 0.550, curve: Curves.easeOutQuad),
      ),
    );

    _symbolGSlide = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.430, 0.550, curve: Curves.easeOutCubic),
      ),
    );

    _symbolTwoSlide = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.450, 0.570, curve: Curves.easeOutCubic),
      ),
    );

    _symbolFourSlide = Tween<double>(begin: 110.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.470, 0.590, curve: Curves.easeOutBack),
      ),
    );

    _shockwaveProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.530, 0.630, curve: Curves.easeOutQuad),
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

    _controller.addListener(() {
      final v = _controller.value;
      // Staggered letter haptics for "GAMEZ24"
      for (int i = 0; i < 7; i++) {
        final threshold = 0.083 + (i * 0.038);
        if (v >= threshold && !_triggeredHaptics.contains(i)) {
          _triggeredHaptics.add(i);
          HapticFeedback.lightImpact();
        }
      }
      // G24 Symbol assembly impact
      if (v >= 0.417 && !_triggeredHaptics.contains(100)) {
        _triggeredHaptics.add(100);
        HapticFeedback.mediumImpact();
      }
      // Complete logo lock-in & shimmer impact
      if (v >= 0.633 && !_triggeredHaptics.contains(200)) {
        _triggeredHaptics.add(200);
        HapticFeedback.heavyImpact();
      }
      // Transition start
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
      final loggedIn = _prefs.getBool('owner_logged_in') ?? false;
      final phone = _prefs.getString('owner_phone');
      if (mounted) {
        setState(() {
          _isLoggedIn = (loggedIn && phone != null && phone.isNotEmpty);
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

    final isLoggedIn = _prefs.getBool('owner_logged_in') ?? false;
    final ownerPhone = _prefs.getString('owner_phone');
    final adminJson = _prefs.getString('verified_admin_data');
    final isPending = _prefs.getBool('owner_is_pending_verification') ?? false;

    if (isLoggedIn && ownerPhone != null && ownerPhone.isNotEmpty) {
      ref.read(isAdminModeProvider.notifier).setMode(true);
      if (adminJson != null) {
        try {
          final data = jsonDecode(adminJson) as Map<String, dynamic>;
          ref.read(turfProfileProvider.notifier).setFromVerifiedAdmin(data);
        } catch (_) {}
      }
      context.go('/admin/dashboard');
    } else if (isPending) {
      context.go('/register');
    } else {
      context.go('/login');
    }
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

    // Target position on AdminLoginScreen:
    // SafeArea + padding 24 + SizedBox 12 + logo height 80
    final targetSymbolTop = topPadding + 24 + 12;
    const targetSymbolHeight = 80.0;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Dynamic coordinates of the traveling G24 symbol during Phase 5
          final currentTop = (centerSymbolTop * (1.0 - _emblemYTransition.value)) +
              (targetSymbolTop * _emblemYTransition.value);
          final currentHeight = (initialSymbolHeight * (1.0 - _emblemYTransition.value)) +
              (targetSymbolHeight * _emblemYTransition.value);
          final currentWidth = currentHeight * 2.113;

          return Stack(
            fit: StackFit.expand,
            children: [
              // ===============================================================
              // LAYER 1: Next Screen Underneath (Fades in during Phase 5)
              // ===============================================================
              if (_controller.value >= 0.75)
                Opacity(
                  opacity: _nextScreenFadeIn.value,
                  child: IgnorePointer(
                    ignoring: _controller.value < 0.98,
                    child: _isLoggedIn
                        ? Container(color: const Color(0xFF0F172A))
                        : const AdminLoginScreen(),
                  ),
                ),

              // ===============================================================
              // LAYER 2: Cinematic Stadium Background (Fades out in Phase 5)
              // ===============================================================
              if (_splashBackgroundFadeOut.value > 0.0)
                Opacity(
                  opacity: _splashBackgroundFadeOut.value,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Stadium Floodlight Cones & Drifting Pitch Particles
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
                    ],
                  ),
                ),

              // ===============================================================
              // LAYER 3: Shockwave Energy Ring at Component Lock-in
              // ===============================================================
              if (_shockwaveProgress.value > 0.0 &&
                  _shockwaveProgress.value < 1.0 &&
                  _splashBackgroundFadeOut.value > 0.5)
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
              // LAYER 4: Phase 2 "Gamez24" Letter-by-Letter Wordmark Reveal
              // Positioned below the G24 symbol, using exact official typography
              // ===============================================================
              if (_wordmarkFadeOut.value > 0.0 && _controller.value >= 0.083)
                Positioned(
                  top: centerSymbolTop +
                      initialSymbolHeight +
                      18.0 -
                      (45.0 * (1.0 - (_wordmarkShiftDown.value / 72.0))),
                  left: (screenSize.width - wordmarkWidth) / 2,
                  width: wordmarkWidth,
                  height: wordmarkHeight,
                  child: Opacity(
                    opacity: _wordmarkFadeOut.value,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Individual letter-by-letter spring reveal
                        for (int i = 0; i < 7; i++)
                          _buildLetterLayer(i, wordmarkWidth, wordmarkHeight),

                        // Master Wordmark Sharp Crossfade once assembled (0.35+)
                        if (_controller.value >= 0.35)
                          Opacity(
                            opacity: math.min(1.0, (_controller.value - 0.35) * 5.0),
                            child: Image.asset(
                              'assets/images/wm_full.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // ===============================================================
              // LAYER 5: The Traveling G24 Symbol (NEVER disappears!)
              // Assembles in Phase 3, holds in Phase 4, travels in Phase 5
              // ===============================================================
              if (_controller.value >= 0.417)
                Positioned(
                  top: currentTop,
                  left: (screenSize.width - currentWidth) / 2,
                  width: currentWidth,
                  height: currentHeight,
                  child: Hero(
                    tag: 'gamez24_logo_emblem',
                    child: Transform.scale(
                      scale: _emblemYTransition.value > 0.0 ? 1.0 : _fullLogoPulse.value,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 5a. Disassembled Entering Components (Phase 3)
                          if (_masterSymbolCrossfade.value < 1.0 && _emblemYTransition.value == 0.0) ...[
                            // Dynamic Circular Football Outline Drawing
                            CustomPaint(
                              painter: _CircularOutlineDrawPainter(
                                progress: _symbolOutlineDraw.value,
                              ),
                            ),

                            // Football Graphic & Arc
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

                            // White letter G (Slide from left)
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

                            // Neon-Lime 2 (Slide from right)
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

                            // Neon-Lime 4 (Slide from top-right)
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

                          // 5b. Master Unified Emblem with Light Sweep (Phase 3 -> Phase 5)
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
                                          alpha: 0.22 * _ambientGlow.value * (1.0 - _emblemYTransition.value),
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
                ),

              // Floating Sound FX Toggle (Top-Right)
              Positioned(
                top: topPadding + 16,
                right: 20,
                child: Opacity(
                  opacity: (1.0 - _nextScreenFadeIn.value).clamp(0.0, 1.0),
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
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds an individual letter from the official wordmark with spring-like entrance
  Widget _buildLetterLayer(int index, double width, double height) {
    final progress = _letterProgress[index].value;
    if (progress <= 0.0) return const SizedBox.shrink();

    final isGreenNumber = (index >= 5); // '2' and '4'
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
          Colors.white.withValues(alpha: 0.08 * lightIntensity),
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
          Colors.white.withValues(alpha: 0.08 * lightIntensity),
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

/// Dynamic Circular Outline Drawing Painter for the football crescent
class _CircularOutlineDrawPainter extends CustomPainter {
  final double progress;

  _CircularOutlineDrawPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = const Color(0xFFD4FF00).withValues(alpha: 0.65 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final sweepAngle = (2 * math.pi) * progress;

    canvas.drawArc(rect, -math.pi * 0.5, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _CircularOutlineDrawPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Shockwave Ripple Painter for component lock-in
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
