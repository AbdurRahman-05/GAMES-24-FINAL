import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/sports_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/sports_loading_indicator.dart';
import '../../../shared/providers/app_providers.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState
    extends ConsumerState<LocationPermissionScreen> {
  bool _isLocating = true;
  String _detectedArea = 'KK Nagar';

  @override
  void initState() {
    super.initState();
    // Simulate automatic live location fetch
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _detectedArea = 'KK Nagar';
        });
        ref.read(selectedAreaProvider.notifier).setArea('KK Nagar');
      }
    });
  }

  void _detectLocation() {
    setState(() => _isLocating = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _detectedArea = 'KK Nagar';
        });
        ref.read(selectedAreaProvider.notifier).setArea('KK Nagar');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedArea = ref.watch(selectedAreaProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Header Badge & Radar Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Madurai GPS Live',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location_rounded,
                        color: AppColors.primary),
                    onPressed: _detectLocation,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                _isLocating ? 'Detecting Live GPS...' : 'Location Set',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'We automatically pinpoint your nearest sports arena in Madurai for instant turf booking.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Live Auto-Detected Location Box with Swiggy/Zomato Sports Loader
              AppCard(
                color: AppColors.primary.withValues(alpha: 0.08),
                hasBorder: true,
                padding: const EdgeInsets.all(20),
                child: _isLocating
                    ? const Center(
                        child: SportsLoadingIndicator(
                          size: 64,
                          message: 'Scanning Madurai Neighborhoods...',
                        ),
                      )
                    : Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.gps_fixed_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Live Location Detected',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$_detectedArea, Madurai',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 24),
                        ],
                      ),
              ),
              const SizedBox(height: 28),

              Text(
                'Or Select Neighborhood',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),

              // Madurai Area Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: SportsData.maduraiAreas.length - 1,
                  itemBuilder: (context, index) {
                    final area = SportsData.maduraiAreas[index + 1];
                    final isSelected = area == selectedArea;

                    return AppCard(
                      padding: const EdgeInsets.all(12),
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : null,
                      onTap: () {
                        ref.read(selectedAreaProvider.notifier).setArea(area);
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.place_rounded,
                            size: 18,
                            color: isSelected ? AppColors.primary : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              area,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: isSelected ? AppColors.primary : null,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Continue with $selectedArea',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
