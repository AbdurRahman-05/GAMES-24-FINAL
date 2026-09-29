import 'package:flutter/material.dart';
import 'package:games24_owner_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/sports_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/providers/app_providers.dart';

class LocationHeader extends ConsumerStatefulWidget {
  final VoidCallback onNotificationTap;

  const LocationHeader({
    super.key,
    required this.onNotificationTap,
  });

  @override
  ConsumerState<LocationHeader> createState() => _LocationHeaderState();
}

class _LocationHeaderState extends ConsumerState<LocationHeader> {
  bool _isAutoLocating = false;

  void _triggerAutoLocate() {
    setState(() => _isAutoLocating = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _isAutoLocating = false);
        ref.read(selectedAreaProvider.notifier).setArea('KK Nagar');
        ToastUtils.showSuccess(context, "Live Location Updated: KK Nagar, Madurai");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedArea = ref.watch(selectedAreaProvider);

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: PopupMenuButton<String>(
                  initialValue: selectedArea,
                  onSelected: (area) {
                    ref.read(selectedAreaProvider.notifier).setArea(area);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _isAutoLocating ? 'Locating...' : '$selectedArea, Madurai',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  itemBuilder: (context) {
                    return SportsData.maduraiAreas.map((area) {
                      return PopupMenuItem<String>(
                        value: area,
                        child: Text(area),
                      );
                    }).toList();
                  },
                ),
              ),
            ],
          ),
        ),

        // Auto GPS Detect Button
        IconButton(
          onPressed: _triggerAutoLocate,
          icon: _isAutoLocating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 22),
          tooltip: 'Auto Detect Live Location',
        ),
        const SizedBox(width: 4),

        // Notification Bell
        GestureDetector(
          onTap: widget.onNotificationTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? AppColors.cardDark
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 22,
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
