import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SlotChip extends StatelessWidget {
  final String slotTime;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback onTap;

  const SlotChip({
    super.key,
    required this.slotTime,
    required this.isSelected,
    this.isAvailable = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color backgroundColor = isDark ? AppColors.cardDark : Colors.white;
    Color textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    if (isSelected) {
      backgroundColor = AppColors.primary;
      textColor = Colors.white;
    } else if (!isAvailable) {
      backgroundColor = Colors.grey.withValues(alpha: 0.12);
      textColor = Colors.grey;
    }

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? null : Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Text(
          slotTime,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            decoration: isAvailable ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }
}
