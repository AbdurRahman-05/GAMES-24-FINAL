import 'package:flutter/material.dart';
import '../../../../core/constants/sports_data.dart';
import '../../../../core/theme/app_colors.dart';

class SportsCategoryGrid extends StatelessWidget {
  final String? selectedSportId;
  final ValueChanged<String> onSelectSport;

  const SportsCategoryGrid({
    super.key,
    this.selectedSportId,
    required this.onSelectSport,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 94,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: SportsData.allSports.length,
        itemBuilder: (context, index) {
          final sport = SportsData.allSports[index];
          final isSelected = sport.id == selectedSportId;

          return GestureDetector(
            onTap: () => onSelectSport(sport.id),
            child: Container(
              width: 76,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.cardDark : AppColors.cardLight),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      sport.icon,
                      color: isSelected ? Colors.white : sport.color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sport.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
