import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../booking/presentation/widgets/venue_card.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/repositories/mock_venues.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteVenuesProvider);
    final favVenues = MockVenuesRepository.venues.where((v) => favoriteIds.contains(v.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Favorites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: favVenues.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'No Favorites Saved',
              description: 'Tap the heart icon on any venue to save it for quick booking.',
              buttonText: 'Discover Venues',
              onButtonPressed: () => context.go('/search'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: favVenues.length,
              itemBuilder: (context, index) {
                final venue = favVenues[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: VenueCard(
                    venue: venue,
                    isFavorite: true,
                    onFavoriteTap: () {
                      ref.read(favoriteVenuesProvider.notifier).toggleFavorite(venue.id);
                    },
                    onTap: () => context.push('/venue-details/${venue.id}'),
                  ),
                );
              },
            ),
    );
  }
}
