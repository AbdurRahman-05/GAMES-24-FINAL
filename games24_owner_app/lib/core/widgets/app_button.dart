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
    final bool isDark = theme.brightness == Brightness.dark;

    Color textColor;
    if (isDisabled) {
      textColor = isDark ? Colors.white38 : Colors.grey[500]!;
    } else if (type == AppButtonType.primary || type == AppButtonType.secondary) {
      textColor = Colors.white;
    } else {
      textColor = AppColors.primary;
    }

    Widget buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              fontWeight: FontWeight.w600,
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
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        border: type == AppButtonType.outline
            ? Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!, width: 1.5)
            : null,
      );
    } else if (type == AppButtonType.primary) {
      decoration = BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (type == AppButtonType.secondary) {
      decoration = BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
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
