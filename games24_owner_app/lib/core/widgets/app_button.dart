import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppButtonType { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDisabled = onPressed == null && !isLoading;

    Color textColor;
    if (isDisabled) {
      textColor = Colors.white38;
    } else if (type == AppButtonType.primary) {
      textColor = Colors.black; // Optimal contrast on Neon Lime (#D4FF00)
    } else if (type == AppButtonType.secondary) {
      textColor = Colors.white;
    } else {
      textColor = AppColors.primary;
    }

    Widget buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == AppButtonType.primary ? Colors.black : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: type == AppButtonType.primary ? FontWeight.w800 : FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    Decoration? decoration;
    if (isDisabled) {
      decoration = BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: type == AppButtonType.outline
            ? Border.all(color: Colors.white12, width: 1.5)
            : null,
      );
    } else if (type == AppButtonType.primary) {
      decoration = BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (type == AppButtonType.secondary) {
      decoration = BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (type == AppButtonType.outline) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1.5),
      );
    }

    return Container(
      width: isFullWidth ? double.infinity : null,
      height: height,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: buttonContent,
          ),
        ),
      ),
    );
  }
}
