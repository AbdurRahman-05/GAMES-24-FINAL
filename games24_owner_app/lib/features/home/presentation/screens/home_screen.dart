import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../booking/presentation/widgets/venue_card.dart';
import '../../../matches/presentation/widgets/match_card.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/repositories/mock_venues.dart';
import '../widgets/location_header.dart';
import '../widgets/promo_banner_carousel.dart';
import '../widgets/quick_host_card.dart';
import '../widgets/sports_category_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedArea = ref.watch(selectedAreaProvider);
    final selectedSportId = ref.watch(selectedSportFilterProvider);
    final favoriteIds = ref.watch(favoriteVenuesProvider);
    final matches = ref.watch(hostedMatchesProvider);
    final userBookings = ref.watch(userBookingsProvider);

    final popularVenues = MockVenuesRepository.venues;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Location Header
              LocationHeader(
                onNotificationTap: () => context.push('/notifications'),
              ),
              const SizedBox(height: 16),

              // Search Bar Launcher
              GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search sports, turfs in $selectedArea...',
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Promotional Banner Carousel
              PromoBannerCarousel(
                onCelebrationTap: () => context.push('/celebrations'),
              ),
              const SizedBox(height: 20),

              // Popular Sports Header & Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Popular Sports', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.push('/search'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SportsCategoryGrid(
                selectedSportId: selectedSportId,
                onSelectSport: (sportId) {
                  ref.read(selectedSportFilterProvider.notifier).setSport(
                      selectedSportId == sportId ? null : sportId);
                  context.push('/search');
                },
              ),
              const SizedBox(height: 24),

              // Upcoming Bookings Card (if any)
              if (userBookings.isNotEmpty) ...[
                Text('Upcoming Booking', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                AppCard(
                  onTap: () => context.push('/my-bookings'),
                  color: AppColors.primary,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userBookings.first.venueName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${userBookings.first.date} • ${userBookings.first.timeSlot}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Popular & Nearby Venues Carousel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Popular Venues in Madurai', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.push('/search'),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 255,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: popularVenues.length,
                  itemBuilder: (context, index) {
                    final venue = popularVenues[index];
                    return VenueCard(
                      venue: venue,
                      width: 260,
                      heroTag: 'pop_${venue.id}',
                      isFavorite: favoriteIds.contains(venue.id),
                      onFavoriteTap: () {
                        ref.read(favoriteVenuesProvider.notifier).toggleFavorite(venue.id);
                      },
                      onTap: () => context.push('/venue-details/${venue.id}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Trending Matches Deck
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trending Matches', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.push('/host-match'),
                    child: const Text('Host Match'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 176,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return MatchCard(
                      match: match,
                      width: 270,
                      onJoinTap: () => context.push('/join-match/${match.id}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Quick Host Card Callout
              QuickHostCard(
                onHostTap: () => context.push('/host-match'),
              ),
              const SizedBox(height: 24),

              // Recommended Venues Header
              Text('Recommended Venues', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: popularVenues.length,
                itemBuilder: (context, index) {
                  final venue = popularVenues[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: VenueCard(
                      venue: venue,
                      heroTag: 'rec_${venue.id}',
                      isFavorite: favoriteIds.contains(venue.id),
                      onFavoriteTap: () {
                        ref.read(favoriteVenuesProvider.notifier).toggleFavorite(venue.id);
                      },
                      onTap: () => context.push('/venue-details/${venue.id}'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
