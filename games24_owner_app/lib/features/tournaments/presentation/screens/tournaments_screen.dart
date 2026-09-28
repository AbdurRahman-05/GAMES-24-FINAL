import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/sports_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../matches/presentation/widgets/match_card.dart';
import '../../../shared/providers/app_providers.dart';
import '../../providers/tournament_provider.dart';
import '../dialogs/user_tournament_details_dialog.dart';

class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key});

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSportFilter;
  final TextEditingController _searchController = TextEditingController();



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allMatches = ref.watch(hostedMatchesProvider);

    final filteredMatches = allMatches.where((m) {
      final matchesSport = _selectedSportFilter == null ||
          m.sportName.toLowerCase() == _selectedSportFilter!.toLowerCase();
      final matchesSearch = _searchController.text.isEmpty ||
          m.venueName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          m.sportName.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesSport && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches & Tournaments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hosted Games'),
            Tab(text: 'Tournaments'),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Search games or venues...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Sport Category Filters
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: SportsData.allSports.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedSportFilter == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: const Text('All Games'),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedSportFilter = null);
                      },
                    ),
                  );
                }

                final sport = SportsData.allSports[index - 1];
                final isSelected = _selectedSportFilter == sport.name;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: Icon(sport.icon, size: 14, color: isSelected ? Colors.white : sport.color),
                    label: Text(sport.name),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedSportFilter = selected ? sport.name : null);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // TabBar View (Hosted Matches vs Tournaments)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Hosted Matches List
                filteredMatches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sports_kabaddi_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text('No hosted games found', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 6),
                            const Text('Be the first to host a match in Madurai!'),
                            const SizedBox(height: 16),
                            AppButton(
                              text: 'Host a Game',
                              isFullWidth: false,
                              onPressed: () => context.push('/host-match'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 100),
                        itemCount: filteredMatches.length,
                        itemBuilder: (context, index) {
                          final match = filteredMatches[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MatchCard(
                              match: match,
                              width: double.infinity,
                              onJoinTap: () => context.push('/join-match/${match.id}'),
                            ),
                          );
                        },
                      ),

                // 2. Real-time Synced Tournaments List
                Consumer(
                  builder: (ctx, ref, _) {
                    final tournState = ref.watch(adminTournamentProvider);
                    final tournamentsList = tournState.tournaments;

                    if (tournamentsList.isEmpty) {
                      return const Center(
                        child: Text('No tournaments currently available.'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 100),
                      itemCount: tournamentsList.length,
                      itemBuilder: (context, index) {
                        final item = tournamentsList[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: AppCard(
                            padding: EdgeInsets.zero,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => UserTournamentDetailsDialog(tournament: item),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        item.bannerUrl,
                                        height: 130,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          height: 130,
                                          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                                          child: const Center(
                                            child: Icon(Icons.emoji_events_rounded, size: 48, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        left: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: item.status == 'Live' ? Colors.red : AppColors.primary,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            item.status == 'Live' ? '🔴 LIVE NOW' : item.sportType,
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(item.subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.place_rounded, size: 15, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(item.courtAllocation, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text('Starts: ${item.startDate} (${item.matchStartTime})', style: theme.textTheme.bodySmall),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      if (item.liveScore.isNotEmpty) ...[
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.red.shade200),
                                          ),
                                          child: Text('🔴 ${item.liveScore}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                                        ),
                                        const SizedBox(height: 10),
                                      ],

                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text('Prize: ${item.championPrize}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary), overflow: TextOverflow.ellipsis),
                                            ),
                                            Text('${item.registeredTeamsCount}/${item.maxTeams} Teams', style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      AppButton(
                                        text: 'View Details & Register (₹${item.teamEntryFee.toInt()})',
                                        icon: Icons.shield_rounded,
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => UserTournamentDetailsDialog(tournament: item),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/host-match'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Host Match', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
