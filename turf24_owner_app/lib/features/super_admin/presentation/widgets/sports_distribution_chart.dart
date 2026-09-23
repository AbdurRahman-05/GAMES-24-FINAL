import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

class SportsDistributionChart extends StatelessWidget {
  const SportsDistributionChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sport Category Popularity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Distribution of turf bookings by sport',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 18),

          _buildSportMeter(
            label: 'Football (7v7 & 5v5)',
            percentage: 42,
            bookings: '1,040 slots',
            color: const Color(0xFF154D36),
            icon: Icons.sports_soccer_rounded,
          ),
          const SizedBox(height: 12),
          _buildSportMeter(
            label: 'Box Cricket Arena',
            percentage: 35,
            bookings: '865 slots',
            color: const Color(0xFFD96B43),
            icon: Icons.sports_cricket_rounded,
          ),
          const SizedBox(height: 12),
          _buildSportMeter(
            label: 'Badminton Courts',
            percentage: 15,
            bookings: '370 slots',
            color: const Color(0xFFEAB308),
            icon: Icons.sports_tennis_rounded,
          ),
          const SizedBox(height: 12),
          _buildSportMeter(
            label: 'Go Kart & VR Gaming',
            percentage: 8,
            bookings: '195 slots',
            color: AppColors.primary,
            icon: Icons.sports_motorsports_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSportMeter({
    required String label,
    required int percentage,
    required String bookings,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            Text(
              '$percentage% ($bookings)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
