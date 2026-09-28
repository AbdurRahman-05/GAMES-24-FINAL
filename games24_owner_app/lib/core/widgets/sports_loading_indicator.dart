import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Swiggy/Zomato-style Sports Icon Switching Loader for Games24 Owner.
class SportsLoadingIndicator extends StatefulWidget {
  final double size;
  final String? message;

  const SportsLoadingIndicator({
    super.key,
    this.size = 80.0,
    this.message = 'Gathering venues in Madurai...',
  });

  @override
  State<SportsLoadingIndicator> createState() => _SportsLoadingIndicatorState();
}

class _SportsLoadingIndicatorState extends State<SportsLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _iconTimer;

  int _currentIconIndex = 0;

  static const List<_SportsIconData> _sportsIcons = [
    _SportsIconData(icon: Icons.sports_soccer_rounded, color: Color(0xFF154D36), label: 'Football'),
    _SportsIconData(icon: Icons.sports_cricket_rounded, color: Color(0xFFD96B43), label: 'Cricket'),
    _SportsIconData(icon: Icons.sports_tennis_rounded, color: Color(0xFFEAB308), label: 'Badminton'),
    _SportsIconData(icon: Icons.sports_basketball_rounded, color: Color(0xFFEA580C), label: 'Basketball'),
    _SportsIconData(icon: Icons.sports_volleyball_rounded, color: Color(0xFF06B6D4), label: 'Volleyball'),
    _SportsIconData(icon: Icons.sports_motorsports_rounded, color: AppColors.primary, label: 'Go Kart'),
    _SportsIconData(icon: Icons.pool_rounded, color: Color(0xFF10B981), label: '8-Ball Pool'),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();

    _iconTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (mounted) {
        _animController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentIconIndex = (_currentIconIndex + 1) % _sportsIcons.length;
            });
            _animController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _iconTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _sportsIcons[_currentIconIndex];
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Swiggy/Zomato-style Pulsing Aura Container
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size + 24,
              height: widget.size + 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: current.color.withValues(alpha: 0.12),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: current.color.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Icon(
                        current.icon,
                        size: widget.size * 0.52,
                        color: current.color,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            current.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: current.color,
            ),
          ),
        ],
      ],
    );
  }
}

class _SportsIconData {
  final IconData icon;
  final Color color;
  final String label;

  const _SportsIconData({
    required this.icon,
    required this.color,
    required this.label,
  });
}
