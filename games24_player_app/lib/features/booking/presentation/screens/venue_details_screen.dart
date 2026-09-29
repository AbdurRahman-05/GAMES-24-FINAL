import 'package:flutter/material.dart';
import 'package:games24_player_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/repositories/mock_venues.dart';

class VenueDetailsScreen extends ConsumerStatefulWidget {
  final String venueId;

  const VenueDetailsScreen({
    super.key,
    required this.venueId,
  });

  @override
  ConsumerState<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends ConsumerState<VenueDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final venue = MockVenuesRepository.venues.firstWhere(
      (v) => v.id == widget.venueId,
      orElse: () => MockVenuesRepository.venues.first,
    );

    final favoriteIds = ref.watch(favoriteVenuesProvider);
    final isFavorite = favoriteIds.contains(venue.id);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image Header Carousel
                Stack(
                  children: [
                    SizedBox(
                      height: 280,
                      child: PageView.builder(
                        itemCount: venue.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Hero(
                            tag: 'venue_img_${venue.id}',
                            child: Image.network(
                              venue.imageUrls[index],
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 48,
                      left: 20,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 48,
                      right: 20,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.black.withValues(alpha: 0.5),
                            child: IconButton(
                              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                              onPressed: () {
                                ToastUtils.showSuccess(context, "Venue link copied to clipboard!");
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            backgroundColor: Colors.black.withValues(alpha: 0.5),
                            child: IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFavorite ? AppColors.error : Colors.white,
                                size: 18,
                              ),
                              onPressed: () {
                                ref.read(favoriteVenuesProvider.notifier).toggleFavorite(venue.id);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              venue.name,
                              style: theme.textTheme.displayMedium,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '${venue.rating} (${venue.reviewCount})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.place_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              venue.address,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text('About Venue', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(venue.description, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 24),

                      // Supported Sports Badges
                      Text('Sports Available', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: venue.sports.map((sport) {
                          return Chip(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            label: Text(
                              sport,
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Amenities Grid
                      Text('Amenities', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: venue.amenities.map((amenity) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
                                const SizedBox(width: 6),
                                Text(amenity, style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Google Maps Preview Card
                      Text('Location & Map', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            Container(
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.map_rounded, size: 48, color: AppColors.primary),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Interactive Map Preview (${venue.area})',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(venue.area, style: theme.textTheme.titleSmall),
                                  TextButton.icon(
                                    onPressed: () {
                                      ToastUtils.showSuccess(context, "Opening Google Maps Directions...");
                                    },
                                    icon: const Icon(Icons.directions_rounded, size: 18),
                                    label: const Text('Get Directions'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Sticky Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Price per hour', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '₹${venue.pricePerHour.toInt()}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: AppButton(
                      text: 'Book Slot',
                      icon: Icons.calendar_today_rounded,
                      onPressed: () {
                        context.push('/slot-booking/${venue.id}');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
