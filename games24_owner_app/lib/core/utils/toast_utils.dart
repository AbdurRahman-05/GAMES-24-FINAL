import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../router/app_router.dart';

enum ToastType { success, error, warning, info }

class ToastUtils {
  static OverlayEntry? _activeEntry;
  static _LuxuryToastOverlayWidgetState? _activeState;

  static void showSuccess(BuildContext context, String message) {
    _showLuxuryToast(
      context: context,
      message: message,
      type: ToastType.success,
    );
  }

  static void showError(BuildContext context, String message) {
    _showLuxuryToast(
      context: context,
      message: message,
      type: ToastType.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showLuxuryToast(
      context: context,
      message: message,
      type: ToastType.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showLuxuryToast(
      context: context,
      message: message,
      type: ToastType.info,
    );
  }

  static void dismiss() {
    _activeState?.startDismiss(immediate: true);
  }

  static void _showLuxuryToast({
    required BuildContext context,
    required String message,
    required ToastType type,
  }) {
    HapticFeedback.lightImpact();

    // Safely dismiss previous toast if active
    if (_activeState != null) {
      _activeState?.startDismiss(immediate: true);
    } else if (_activeEntry != null) {
      try {
        _activeEntry?.remove();
      } catch (_) {}
      _activeEntry = null;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        AppRouter.rootNavigatorKey.currentState?.overlay ??
        Navigator.maybeOf(context, rootNavigator: true)?.overlay;

    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return _LuxuryToastOverlayWidget(
          message: message,
          type: type,
          onStateCreated: (state) {
            _activeState = state;
          },
          onDismissed: () {
            if (_activeEntry == entry) {
              _activeEntry = null;
              _activeState = null;
            }
            try {
              if (entry.mounted) {
                entry.remove();
              }
            } catch (_) {}
          },
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }
}

class _LuxuryToastOverlayWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final ValueChanged<_LuxuryToastOverlayWidgetState>? onStateCreated;
  final VoidCallback onDismissed;
  final Duration displayDuration;

  const _LuxuryToastOverlayWidget({
    required this.message,
    required this.type,
    this.onStateCreated,
    required this.onDismissed,
    this.displayDuration = const Duration(milliseconds: 3200),
  });

  @override
  State<_LuxuryToastOverlayWidget> createState() =>
      _LuxuryToastOverlayWidgetState();
}

class _LuxuryToastOverlayWidgetState extends State<_LuxuryToastOverlayWidget>
    with TickerProviderStateMixin {
  late final AnimationController _inController;
  late final AnimationController _outController;
  late final Animation<Offset> _inSlide;
  late final Animation<double> _inFade;
  late final Animation<Offset> _outSlide;
  late final Animation<double> _outFade;

  Timer? _dismissTimer;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated?.call(this);

    // Slide in from LEFT: begins at -1.25, decelerates into place at (0, 0)
    _inController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _inSlide = Tween<Offset>(
      begin: const Offset(-1.25, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _inController,
      curve: Curves.easeOutCubic,
    ));

    _inFade = CurvedAnimation(
      parent: _inController,
      curve: Curves.easeOut,
    );

    // Slide out to RIGHT: begins at (0, 0), accelerates to +1.25
    _outController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _outSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.25, 0.0),
    ).animate(CurvedAnimation(
      parent: _outController,
      curve: Curves.easeInCubic,
    ));

    _outFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _outController,
      curve: Curves.easeIn,
    ));

    _inController.forward().then((_) {
      if (mounted && !_isExiting) {
        _dismissTimer = Timer(widget.displayDuration, () {
          startDismiss();
        });
      }
    });
  }

  void startDismiss({bool immediate = false}) {
    if (_isExiting) return;
    _isExiting = true;
    _dismissTimer?.cancel();

    if (immediate || !mounted) {
      widget.onDismissed();
      return;
    }

    setState(() {});
    _outController.forward().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _inController.dispose();
    _outController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final paddingBottom = mediaQuery.padding.bottom;

    // Position at lower circled area: ~86px above bottom (floating right above bottom navigation bar)
    final bottomPosition = bottomInset > 0
        ? (bottomInset + 16.0)
        : (paddingBottom + 86.0);

    return Positioned(
      left: 14,
      right: 14,
      bottom: bottomPosition,
      child: SlideTransition(
        position: _isExiting ? _outSlide : _inSlide,
        child: FadeTransition(
          opacity: _isExiting ? _outFade : _inFade,
          child: Dismissible(
            key: const ValueKey('luxury_toast_dismissible_key'),
            direction: DismissDirection.horizontal,
            onDismissed: (_) {
              _dismissTimer?.cancel();
              widget.onDismissed();
            },
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => startDismiss(),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: _buildToastCard(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToastCard(BuildContext context) {
    late final Color accentColor;
    late final Color badgeBgColor;
    late final Color borderColor;
    late final List<Color> gradientColors;
    late final IconData icon;
    late final String label;

    switch (widget.type) {
      case ToastType.success:
        accentColor = const Color(0xFF86EFAC);
        badgeBgColor = const Color(0xFF1B2E18);
        borderColor = const Color(0xFF38522A);
        gradientColors = const [Color(0xFF161E14), Color(0xFF0F150D)];
        icon = Icons.verified_rounded;
        label = 'SUCCESS';
        break;
      case ToastType.error:
        accentColor = const Color(0xFFF87171);
        badgeBgColor = const Color(0xFF2E1717);
        borderColor = const Color(0xFF552222);
        gradientColors = const [Color(0xFF201313), Color(0xFF140B0B)];
        icon = Icons.error_outline_rounded;
        label = 'ALERT';
        break;
      case ToastType.warning:
        accentColor = const Color(0xFFFBBF24);
        badgeBgColor = const Color(0xFF2E2413);
        borderColor = const Color(0xFF55411E);
        gradientColors = const [Color(0xFF1E190E), Color(0xFF141008)];
        icon = Icons.warning_amber_rounded;
        label = 'NOTICE';
        break;
      case ToastType.info:
        accentColor = const Color(0xFF38BDF8);
        badgeBgColor = const Color(0xFF132330);
        borderColor = const Color(0xFF1F3D55);
        gradientColors = const [Color(0xFF0E1A22), Color(0xFF091116)];
        icon = Icons.info_outline_rounded;
        label = 'INFO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing Badge Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Ambient Live Indicator Dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.8),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
