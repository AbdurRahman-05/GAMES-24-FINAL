import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../booking/presentation/widgets/venue_card.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/repositories/mock_venues.dart';
import '../widgets/filter_bottom_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;
  double _maxPrice = 3000;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FilterBottomSheet(
          selectedSport: ref.read(selectedSportFilterProvider),
          selectedArea: ref.read(selectedAreaProvider),
          onApply: (filters) {
            setState(() {
              if (filters['sport'] != null) {
                ref.read(selectedSportFilterProvider.notifier).setSport(filters['sport']);
              }
              if (filters['area'] != null) {
                ref.read(selectedAreaProvider.notifier).setArea(filters['area']);
              }
              _maxPrice = filters['maxPrice'] ?? 3000;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedSportId = ref.watch(selectedSportFilterProvider);
    final selectedArea = ref.watch(selectedAreaProvider);
    final favoriteIds = ref.watch(favoriteVenuesProvider);

    final allVenues = MockVenuesRepository.venues;

    final filteredVenues = allVenues.where((v) {
      final query = _searchController.text.toLowerCase();
      final matchesQuery = query.isEmpty ||
          v.name.toLowerCase().contains(query) ||
          v.area.toLowerCase().contains(query) ||
          v.sports.any((s) => s.toLowerCase().contains(query));

      final matchesArea = selectedArea == 'All Madurai' || v.area == selectedArea;

      final matchesSport = selectedSportId == null ||
          v.sports.any((s) => s.toLowerCase() == selectedSportId.toLowerCase());

      final matchesPrice = v.pricePerHour <= _maxPrice;

      return matchesQuery && matchesArea && matchesSport && matchesPrice;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _searchController,
                      hint: 'Search venue name, area, or sport...',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).setQuery(val);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _openFilters,
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            // Active Filter Chips Row
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (selectedSportId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('Sport: $selectedSportId'),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () {
                          ref.read(selectedSportFilterProvider.notifier).setSport(null);
                        },
                      ),
                    ),
                  if (selectedArea != 'All Madurai')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('Area: $selectedArea'),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () {
                          ref.read(selectedAreaProvider.notifier).setArea('All Madurai');
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text('Max ₹${_maxPrice.toInt()}/hr'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredVenues.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No Venues Found',
                      description: 'Try adjusting your search query or reset location filters.',
                      buttonText: 'Reset Filters',
                      onButtonPressed: () {
                        setState(() {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).setQuery('');
                          ref.read(selectedSportFilterProvider.notifier).setSport(null);
                          ref.read(selectedAreaProvider.notifier).setArea('All Madurai');
                          _maxPrice = 3000;
                        });
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                      itemCount: filteredVenues.length,
                      itemBuilder: (context, index) {
                        final venue = filteredVenues[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: VenueCard(
                            venue: venue,
                            isFavorite: favoriteIds.contains(venue.id),
                            onFavoriteTap: () {
                              ref.read(favoriteVenuesProvider.notifier).toggleFavorite(venue.id);
                            },
                            onTap: () => context.push('/venue-details/${venue.id}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
