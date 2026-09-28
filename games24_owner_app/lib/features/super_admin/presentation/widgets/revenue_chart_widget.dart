import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

class RevenueChartWidget extends StatelessWidget {
  const RevenueChartWidget({super.key});

  static const List<_MonthlyRevenueData> _monthlyData = [
    _MonthlyRevenueData(month: 'Jan', revenue: 1.1),
    _MonthlyRevenueData(month: 'Feb', revenue: 1.4),
    _MonthlyRevenueData(month: 'Mar', revenue: 1.6),
    _MonthlyRevenueData(month: 'Apr', revenue: 1.9),
    _MonthlyRevenueData(month: 'May', revenue: 2.1),
    _MonthlyRevenueData(month: 'Jun', revenue: 2.3),
    _MonthlyRevenueData(month: 'Jul', revenue: 2.48, isCurrent: true),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly GMV Revenue Growth',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Platform revenue in Lakhs (₹)',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '+125.4% H1 Growth 🚀',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Custom Bar Chart Render
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _monthlyData.map((data) {
                final double heightRatio = data.revenue / 2.8;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '₹${data.revenue}L',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: data.isCurrent ? AppColors.primary : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      width: 28,
                      height: 120 * heightRatio,
                      decoration: BoxDecoration(
                        gradient: data.isCurrent
                            ? AppColors.primaryGradient
                            : LinearGradient(
                                colors: [
                                  isDark ? Colors.white24 : Colors.grey[300]!,
                                  isDark ? Colors.white10 : Colors.grey[200]!,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: data.isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.month,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: data.isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: data.isCurrent ? AppColors.primary : null,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyRevenueData {
  final String month;
  final double revenue;
  final bool isCurrent;

  const _MonthlyRevenueData({
    required this.month,
    required this.revenue,
    this.isCurrent = false,
  });
}
