import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final bool hasBorder;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20.0,
    this.color,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.cardDark;
    final borderColor = AppColors.borderDark;

    Widget current = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder ? Border.all(color: borderColor, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: current,
        ),
      );
    }

    return current;
  }
}
