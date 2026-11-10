import 'api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:games24_player_app/booking_screen.dart';
import 'package:games24_player_app/challenge_manager.dart';
import 'package:games24_player_app/my_bookings_screen.dart';
import 'package:games24_player_app/teams_hub_screen.dart';
import 'package:games24_player_app/booking_manager.dart';
import 'package:games24_player_app/match_scorecard_screen.dart';
import 'package:games24_player_app/match_schedule_screen.dart';
import 'package:games24_player_app/location_manager.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onExploreTap;

  const HomeScreen({super.key, this.onExploreTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _allTurfs = [];
  bool _isLoadingTurfs = true;

  // Search and Filter state under Join Team / Open Challenges
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _filterSport = 'All';
  String _filterDistance = 'Any';
  String _filterPrice = 'Any';
  String _filterRating = 'Any';
  final Set<String> _filterAmenities = {};

  @override
  void initState() {
    super.initState();
    LocationManager().locationNotifier.addListener(_onLocationChanged);
    _fetchTurfs();
    BookingManager().fetchBookings();
    ChallengeManager().syncWithCurrentUser();
    ChallengeManager().cleanExpiredChallenges();
    ChallengeManager().fetchChallenges(location: LocationManager().currentLocation);
  }

  @override
  void dispose() {
    LocationManager().locationNotifier.removeListener(_onLocationChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onLocationChanged() {
    if (mounted) {
      setState(() {});
      ChallengeManager().fetchChallenges(location: LocationManager().currentLocation);
    }
  }

  List<Map<String, dynamic>> get _filteredTurfs {
    return _allTurfs.where((turf) {
      // 0. Location Filter based on selected locality
      if (!LocationManager().matchesTurf(turf)) {
        return false;
      }

      final name = (turf['venueName'] ?? turf['name'] ?? '').toString().toLowerCase();
      final location = (turf['location'] ?? '').toString().toLowerCase();

      List<String> sports = [];
      if (turf['sports'] is List) {
        sports = (turf['sports'] as List).map((s) => s.toString().toLowerCase()).toList();
      } else if (turf['sports'] != null) {
        sports = turf['sports']
            .toString()
            .toLowerCase()
            .split(RegExp(r'[,•|/]'))
            .map((s) => s.trim())
            .toList();
      }

      // 1. Search Query filter
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesName = name.contains(query);
        final matchesLocation = location.contains(query);
        final matchesSport = sports.any((s) => s.contains(query));
        if (!matchesName && !matchesLocation && !matchesSport) {
          return false;
        }
      }

      // 2. Sport Filter (from Filter sheet or Category selection)
      if (_filterSport != 'All') {
        final target = _filterSport.toLowerCase();
        final matches = sports.any((s) {
          final sLower = s.toLowerCase();
          return sLower.contains(target) ||
              target.contains(sLower) ||
              (target == 'cricket' && sLower.contains('box cricket')) ||
              (target == 'football' && sLower.contains('soccer')) ||
              (target.contains('pickle') && sLower.contains('pickle'));
        });
        if (!matches) return false;
      }

      // 3. Price Filter
      if (_filterPrice != 'Any') {
        final priceRaw = (turf['price'] ?? '0').toString().replaceAll(RegExp(r'[^0-9]'), '');
        final priceVal = double.tryParse(priceRaw) ?? 0.0;
        if (_filterPrice == 'Under ₹800' && priceVal > 800) return false;
        if (_filterPrice == '₹800 - ₹1,500' && (priceVal < 800 || priceVal > 1500)) return false;
        if (_filterPrice == '₹1,500+' && priceVal < 1500) return false;
      }

      // 4. Rating Filter
      if (_filterRating != 'Any') {
        final ratingRaw = (turf['rating'] ?? '4.8').toString();
        final ratingVal = double.tryParse(ratingRaw) ?? 4.8;
        if (_filterRating == '4.0+ ★' && ratingVal < 4.0) return false;
        if (_filterRating == '4.5+ ★' && ratingVal < 4.5) return false;
      }

      // 5. Amenities Filter
      if (_filterAmenities.isNotEmpty) {
        List<String> turfAmenities = [];
        if (turf['amenities'] is List) {
          turfAmenities = (turf['amenities'] as List).map((a) => a.toString().toLowerCase()).toList();
        }
        for (var req in _filterAmenities) {
          if (!turfAmenities.any((a) => a.contains(req.toLowerCase()))) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  bool get _hasActiveFilters {
    final isLocFiltered = LocationManager().currentLocation != 'All Madurai' &&
        LocationManager().currentLocation != 'All';
    return isLocFiltered ||
        _filterSport != 'All' ||
        _filterDistance != 'Any' ||
        _filterPrice != 'Any' ||
        _filterRating != 'Any' ||
        _filterAmenities.isNotEmpty;
  }

  int get _activeFilterCount {
    int count = 0;
    if (LocationManager().currentLocation != 'All Madurai' &&
        LocationManager().currentLocation != 'All') {
      count++;
    }
    if (_filterSport != 'All') count++;
    if (_filterDistance != 'Any') count++;
    if (_filterPrice != 'Any') count++;
    if (_filterRating != 'Any') count++;
    count += _filterAmenities.length;
    return count;
  }

  void _clearAllFilters() {
    LocationManager().setLocation('All Madurai');
    setState(() {
      _filterSport = 'All';
      _filterDistance = 'Any';
      _filterPrice = 'Any';
      _filterRating = 'Any';
      _filterAmenities.clear();
      _searchQuery = '';
      _searchController.clear();
      _isSearchOpen = false;
      for (var cat in _categories) {
        cat['isSelected'] = false;
      }
    });
  }

  Future<void> _fetchTurfs() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/turfs'));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _allTurfs = list.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoadingTurfs = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching turfs in home_screen: $e");
    }
    if (mounted) {
      setState(() => _isLoadingTurfs = false);
    }
  }

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Football', 'icon': Icons.sports_soccer, 'isSelected': false},
    {'name': 'Cricket', 'icon': Icons.sports_cricket, 'isSelected': false},
    {'name': 'Pickle ball', 'icon': Icons.sports_tennis_rounded, 'isSelected': false},
    {'name': 'Badminton', 'icon': Icons.sports_tennis, 'isSelected': false},
    {'name': 'Tennis', 'icon': Icons.sports_tennis, 'isSelected': false},
    {
      'name': 'Basketball',
      'icon': Icons.sports_basketball,
      'isSelected': false,
    },
  ];

  Widget _buildLocationBanner() {
    return ValueListenableBuilder<String>(
      valueListenable: LocationManager().locationNotifier,
      builder: (context, loc, _) {
        final isAll = loc == 'All Madurai' || loc == 'All';
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF166534).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF166534),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAll ? 'Exploring All Madurai' : 'Locality: $loc',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14532D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAll
                          ? 'Showing turfs & matches across the city'
                          : 'Filtered for turfs & open matches nearby',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF166534),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => LocationManager.showLocationPicker(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF166534),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Change',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_right, size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: RefreshIndicator(
        color: const Color(0xFF166534),
        onRefresh: () async {
          await Future.wait([
            _fetchTurfs(),
            BookingManager().fetchBookings(),
            ChallengeManager().fetchChallenges(location: LocationManager().currentLocation),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: BookingManager().bookingsNotifier,
            builder: (context, _, _) {
              final activeBookings = BookingManager().activeBookings;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildLocationBanner(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSectionHeader('Categories', ''),
                  ),
                  const SizedBox(height: 16),
                  _buildCategories(),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSectionHeader(
                      'Upcoming Matches',
                      'View Schedule',
                      hasLiveBadge: true,
                      onActionTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MatchScheduleScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildUpcomingMatches(),

                  // Red circled section: Only shown if the user has an active booking. If no active bookings, completely removed with no extra blank space.
                  if (activeBookings.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSectionHeader(
                        'Your Active Bookings',
                        'History',
                        onActionTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyBookingsScreen(),
                          ),
                        ).then((_) => BookingManager().fetchBookings()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildActiveBookings(activeBookings),
                    ),
                  ],

                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSectionHeader(
                      'Join Team / Open Challenges',
                      'View All',
                      onActionTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeamsHubScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildOpenChallenges(),

                  const SizedBox(height: 32),
                  // "All Games" Section Header with Search & Filter action icons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildAllGamesHeader(),
                  ),
                  if (_isSearchOpen) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildInlineSearchBar(),
                    ),
                  ],
                  if (_hasActiveFilters) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildActiveFilterChips(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildNearbyTurfs(),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAllGamesHeader() {
    return Row(
      children: [
        const Text(
          'All Games',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Color(0xFF111827),
          ),
        ),
        const Spacer(),
        // Search icon only button
        GestureDetector(
          onTap: () {
            setState(() {
              _isSearchOpen = !_isSearchOpen;
              if (!_isSearchOpen) {
                _searchQuery = '';
                _searchController.clear();
              }
            });
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _isSearchOpen ? const Color(0xFF166534) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isSearchOpen ? const Color(0xFF166534) : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.search,
              size: 20,
              color: _isSearchOpen ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Filter icon button
        GestureDetector(
          onTap: () => _showFilterBottomSheet(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF166534),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF166534).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              if (_hasActiveFilters)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    alignment: Alignment.center,
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInlineSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF166534), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              decoration: const InputDecoration(
                hintText: 'Search games, turfs, sports, or areas...',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Icon(Icons.cancel, size: 18, color: Color(0xFF9CA3AF)),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    final chips = <Widget>[];

    if (LocationManager().currentLocation != 'All Madurai' &&
        LocationManager().currentLocation != 'All') {
      chips.add(_buildFilterPill('📍 ${LocationManager().currentLocation}', () {
        LocationManager().setLocation('All Madurai');
      }));
    }

    if (_filterSport != 'All') {
      chips.add(_buildFilterPill(_filterSport, () {
        setState(() {
          _filterSport = 'All';
          for (var c in _categories) {
            c['isSelected'] = false;
          }
        });
      }));
    }

    if (_filterDistance != 'Any') {
      chips.add(_buildFilterPill(_filterDistance, () {
        setState(() => _filterDistance = 'Any');
      }));
    }

    if (_filterPrice != 'Any') {
      chips.add(_buildFilterPill(_filterPrice, () {
        setState(() => _filterPrice = 'Any');
      }));
    }

    if (_filterRating != 'Any') {
      chips.add(_buildFilterPill(_filterRating, () {
        setState(() => _filterRating = 'Any');
      }));
    }

    for (final a in _filterAmenities) {
      chips.add(_buildFilterPill(a, () {
        setState(() => _filterAmenities.remove(a));
      }));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...chips,
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _clearAllFilters,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Clear All',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF166534).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF166534),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionText, {
    bool hasLiveBadge = false,
    IconData? trailingIcon,
    VoidCallback? onActionTap,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Color(0xFF111827),
          ),
        ),
        if (hasLiveBadge) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF166534),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Live',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const Spacer(),
        GestureDetector(
          onTap: onActionTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              if (trailingIcon != null) ...[
                Icon(trailingIcon, size: 14, color: const Color(0xFF166534)),
                const SizedBox(width: 4),
              ],
              if (actionText.isNotEmpty)
                Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat['isSelected'] as bool;
          return GestureDetector(
            onTap: () {
              setState(() {
                final currentSelected = _categories[index]['isSelected'] as bool;
                for (var category in _categories) {
                  category['isSelected'] = false;
                }
                if (!currentSelected) {
                  _categories[index]['isSelected'] = true;
                  _filterSport = cat['name'] as String;
                } else {
                  _filterSport = 'All';
                }
              });
            },
            child: Container(
              width: 88,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF166534) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF166534).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    color: isSelected ? Colors.white : const Color(0xFF4B5563),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF4B5563),
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingMatches() {
    final matches = <Map<String, dynamic>>[];

    if (matches.isEmpty) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MatchScheduleScreen()),
        ),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sports_soccer_outlined,
                  color: Color(0xFF166534),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No Upcoming Matches',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Book a turf slot or join an open game to play!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: matches.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final match = matches[index];
          return Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        match['time'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    Text(
                      match['slots'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTeamAvatar(
                      match['t1Initials'] as String,
                      match['t1Name'] as String,
                      match['t1Color'] as Color,
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildTeamAvatar(
                      match['t2Initials'] as String,
                      match['t2Name'] as String,
                      match['t2Color'] as Color,
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      match['location'] as String,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _showJoinMatchDialog(context, match);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF166534),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Join',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeamAvatar(String initials, String name, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(fontSize: 10, color: Color(0xFF111827)),
        ),
      ],
    );
  }

  String _formatBookingDate(String? dateStr, String? timeSlot) {
    if (dateStr == null || dateStr.isEmpty) return timeSlot ?? '';
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final bDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final diff = bDate.difference(today).inDays;
        final slotText = (timeSlot != null && timeSlot.isNotEmpty)
            ? ', $timeSlot'
            : '';
        if (diff == 0) {
          return 'Today$slotText';
        } else if (diff == 1) {
          return 'Tomorrow$slotText';
        } else {
          const months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          return '${bDate.day} ${months[bDate.month - 1]}$slotText';
        }
      }
    } catch (_) {}
    return '$dateStr${timeSlot != null && timeSlot.isNotEmpty ? ', $timeSlot' : ''}';
  }

  Widget _buildActiveBookings(List<Map<String, dynamic>> bookings) {
    return Column(
      children: bookings.map((booking) {
        final turfName =
            (booking['turfName'] ?? booking['courtName'] ?? 'Turf Arena')
                .toString();
        final rawImg = (booking['imageUrl'] ?? '').toString();
        final imgUrl = rawImg.isNotEmpty
            ? rawImg
            : 'https://picsum.photos/seed/${booking['id'] ?? 'booking'}/250/250';
        final status = (booking['status'] ?? 'Confirmed').toString();
        final dateStr = (booking['date'] ?? '').toString();
        final timeSlot = (booking['timeSlot'] ?? '').toString();
        final formattedDateTime = _formatBookingDate(dateStr, timeSlot);
        final locationOrCourt =
            (booking['courtName'] ?? booking['location'] ?? 'Turf 1')
                .toString();
        final isCompleted = !BookingManager.isBookingActive(booking) ||
            (booking['status'] ?? '').toString().toLowerCase() == 'completed';
        final isStarted = BookingManager.isMatchStarted(dateStr: dateStr, timeSlot: timeSlot);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyBookingsScreen(),
                ),
              ).then((_) => BookingManager().fetchBookings());
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imgUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.sports_soccer,
                              color: Color(0xFF166534),
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    turfName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDateTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    locationOrCourt,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF111827),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchScorecardScreen(
                                bookingId: (booking['id'] ?? 'BK-1').toString(),
                                turfName: turfName,
                                sport: (booking['sport'] ?? 'Cricket').toString(),
                                date: dateStr,
                                timeSlot: timeSlot,
                                initialTab: isCompleted ? 3 : 0,
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          isCompleted
                              ? Icons.analytics_outlined
                              : (isStarted
                                  ? Icons.sports_score_rounded
                                  : Icons.groups_rounded),
                          size: 16,
                        ),
                        label: Text(
                          isCompleted
                              ? 'Match Details & Result 📋'
                              : (isStarted
                                  ? 'Scorecard & Toss 🏆'
                                  : 'Squad & Pre-Match 🛡️'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompleted
                              ? const Color(0xFF0F6D38)
                              : const Color(0xFF166534),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                      const Text(
                        'View Booking →',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOpenChallenges() {
    return ValueListenableBuilder<List<Challenge>>(
      valueListenable: ChallengeManager().challengesNotifier,
      builder: (context, allChallenges, child) {
        final challenges = allChallenges
            .where((c) => !c.isExpired && LocationManager().isMatchingLocation(c.location))
            .toList();
        if (challenges.isEmpty) {
          final isFiltered = LocationManager().currentLocation != 'All Madurai' &&
              LocationManager().currentLocation != 'All';
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: Color(0xFF166534),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isFiltered
                            ? 'No Matches in ${LocationManager().currentLocation}'
                            : 'No Open Challenges',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isFiltered
                            ? 'Be the first to create an open match in this locality or switch area.'
                            : 'Create an open challenge after booking to invite opponents.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return SizedBox(
          height: 168,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: challenges.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildChallengeCard(challenges[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF166534).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  challenge.sport,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
              Text(
                '${challenge.date}, ${challenge.time}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTeamAvatar(
                challenge.challengerTeamInitials,
                challenge.challengerName,
                challenge.challengerColor,
              ),
              const SizedBox(width: 16),
              const Text(
                'VS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 16),
              if (challenge.isJoined)
                _buildTeamAvatar(
                  challenge.opponentName != null &&
                          challenge.opponentName!.length >= 2
                      ? challenge.opponentName!.substring(0, 2).toUpperCase()
                      : 'VS',
                  challenge.opponentName ?? 'Opponent',
                  const Color(0xFFBE123C),
                )
              else
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD1D5DB),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.help_outline,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Open Slot',
                      style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      challenge.turfName,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (challenge.location.trim().isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 11,
                            color: Color(0xFF166534),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              challenge.location,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (challenge.isJoined)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F5EB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF166534)),
                      SizedBox(width: 4),
                      Text(
                        'Matched',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (challenge.isCreator)
                GestureDetector(
                  onTap: () {
                    _showRequestsDialog(challenge);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: challenge.joinRequests.isNotEmpty
                          ? const Color(0xFF166534)
                          : const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          challenge.joinRequests.isNotEmpty
                              ? 'See Requests (${challenge.joinRequests.length})'
                              : 'See Requests',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (challenge.userHasRequested)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_top_rounded, size: 12, color: Colors.orange.shade900),
                      const SizedBox(width: 4),
                      Text(
                        'Requested',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    _showJoinChallengeDialog(challenge);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF166534),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Join',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showJoinChallengeDialog(Challenge challenge) {
    final teamNameCtrl = TextEditingController();
    final teamSizeCtrl = TextEditingController(text: '7 Players (7v7)');
    final contactCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Join Open Challenge',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_soccer_rounded, size: 18, color: Color(0xFF166534)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Challenge ${challenge.challengerName} • ${challenge.turfName}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: teamNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Team Name',
                    hintText: 'e.g. Thunder FC',
                    prefixIcon: Icon(Icons.shield_outlined, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: teamSizeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Team Size / Format',
                    hintText: 'e.g. 7 Players (7v7)',
                    prefixIcon: Icon(Icons.groups_outlined, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    hintText: 'e.g. +91 98765 43210',
                    prefixIcon: Icon(Icons.phone_outlined, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final tName = teamNameCtrl.text.trim();
                final tSize = teamSizeCtrl.text.trim();
                final cNumber = contactCtrl.text.trim();

                if (tName.isEmpty || tSize.isEmpty || cNumber.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter Team Name, Team Size, and Contact Number.'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                  return;
                }

                ChallengeManager().requestToJoin(
                  challenge.id,
                  tName,
                  tSize,
                  cNumber,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Join request sent to ${challenge.challengerName}!'),
                    backgroundColor: const Color(0xFF166534),
                  ),
                );
              },
              child: const Text('Send Join Request'),
            ),
          ],
        );
      },
    );
  }

  void _showRequestsDialog(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) {
        final requests = challenge.joinRequests;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  requests.isNotEmpty ? 'Join Requests (${requests.length})' : 'Open Challenge Status',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: requests.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          size: 48,
                          color: Color(0xFF166534),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Requests Yet',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your open challenge for ${challenge.sport} at ${challenge.turfName} is live.\n\nOther players can challenge your team with their team name, team size, and contact details.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: requests.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    req.teamName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF111827),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F5EB),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    req.teamSize,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF6B7280)),
                                const SizedBox(width: 4),
                                Text(
                                  req.contactDetails,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                                ),
                                const Spacer(),
                                Text(
                                  req.requestedAt,
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFDC2626),
                                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.close_rounded, size: 14),
                                  label: const Text('Decline', style: TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    ChallengeManager().rejectRequest(challenge.id, req.id);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Request declined.')),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF166534),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.check_circle_rounded, size: 14),
                                  label: const Text('Accept Challenge', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    ChallengeManager().acceptRequest(challenge.id, req);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Challenge accepted! Paired with ${req.teamName}.'),
                                        backgroundColor: const Color(0xFF166534),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNearbyTurfs() {
    if (_isLoadingTurfs) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF166534)),
        ),
      );
    }

    if (_allTurfs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.sports_soccer_rounded,
              size: 44,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 10),
            Text(
              'No verified turfs available yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Once an admin registers and Super Admin verifies, the turf appears here live!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    final displayed = _filteredTurfs;
    if (displayed.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 44,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 10),
            const Text(
              'No games or turfs found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try changing your sport, distance, or search query',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearAllFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text('Reset Filters', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: displayed.map((turf) {
        final List<String> tags = (turf['amenities'] is List)
            ? (turf['amenities'] as List).map((e) => e.toString()).toList()
            : ['Floodlights', 'Parking', 'Restroom'];

        final List<String> photoUrls = (turf['photoUrls'] is List)
            ? (turf['photoUrls'] as List).map((e) => e.toString()).toList()
            : [turf['imageUrl'] ?? 'https://picsum.photos/seed/turf1/800/400'];

        final sportsStr = (turf['sports'] is List)
            ? (turf['sports'] as List).join(' • ')
            : (turf['sports']?.toString() ?? 'Cricket • Football • Pickle ball • Badminton');

        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: _buildTurfCard(
            turfId: turf['id'] is int
                ? turf['id'] as int
                : int.tryParse(turf['id']?.toString() ?? ''),
            name: turf['venueName'] ?? turf['name'] ?? 'Turf Arena',
            price: turf['price'] ?? '₹1,200',
            location: turf['location'] ?? 'Madurai',
            imageUrl: turf['imageUrl'] ?? photoUrls.first,
            photoUrls: photoUrls,
            amenities: tags,
            openingTime: turf['openingTime'] ?? '06:00 AM',
            closingTime: turf['closingTime'] ?? '10:00 PM',
            rating: turf['rating']?.toString() ?? '4.9',
            reviews: turf['reviews']?.toString() ?? '128',
            sports: sportsStr,
            sportsList: (turf['sportsList'] is List) ? (turf['sportsList'] as List) : null,
            tags: tags,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTurfCard({
    int? turfId,
    required String name,
    required String price,
    required String location,
    required String imageUrl,
    List<String>? photoUrls,
    List<String>? amenities,
    String? openingTime,
    String? closingTime,
    required String rating,
    required String reviews,
    required String sports,
    List<dynamic>? sportsList,
    required List<String> tags,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.sports_soccer,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        ' ($reviews)',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    sports,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '/ hour',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags
                            .take(3)
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingScreen(
                              turfId: turfId,
                              turfName: name,
                              imageUrl: imageUrl,
                              photoUrls: photoUrls,
                              amenities: amenities,
                              openingTime: openingTime,
                              closingTime: closingTime,
                              price: price,
                              location: location,
                              sports: sports.split(' • '),
                              sportsList: sportsList,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF166534),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Book Slot',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    String tempSport = _filterSport;
    String tempDistance = _filterDistance;
    String tempPrice = _filterPrice;
    String tempRating = _filterRating;
    final Set<String> tempAmenities = Set<String>.from(_filterAmenities);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Widget buildSectionLabel(String label) {
              return Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 10),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.2,
                  ),
                ),
              );
            }

            Widget buildChip(String title, bool isSelected, VoidCallback onTap) {
              return GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF166534) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF166534) : const Color(0xFFE5E7EB),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                ),
              );
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.78,
              minChildSize: 0.5,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune_rounded, color: Color(0xFF166534), size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Filter Games & Turfs',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempSport = 'All';
                                tempDistance = 'Any';
                                tempPrice = 'Any';
                                tempRating = 'Any';
                                tempAmenities.clear();
                              });
                            },
                            child: const Text(
                              'Reset All',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        children: [
                          // 1. Sport
                          buildSectionLabel('Particular Sport'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'All',
                              'Cricket',
                              'Football',
                              'Pickle ball',
                              'Badminton',
                              'Tennis',
                              'Basketball',
                            ].map((s) {
                              return buildChip(s, tempSport == s, () {
                                setModalState(() => tempSport = s);
                              });
                            }).toList(),
                          ),

                          // 2. Distance
                          buildSectionLabel('Nearby Distance'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Any', '< 5 km', '< 10 km', '< 25 km'].map((d) {
                              return buildChip(d, tempDistance == d, () {
                                setModalState(() => tempDistance = d);
                              });
                            }).toList(),
                          ),

                          // 3. Price
                          buildSectionLabel('Price per Hour'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Any',
                              'Under ₹800',
                              '₹800 - ₹1,500',
                              '₹1,500+',
                            ].map((p) {
                              return buildChip(p, tempPrice == p, () {
                                setModalState(() => tempPrice = p);
                              });
                            }).toList(),
                          ),

                          // 4. Rating
                          buildSectionLabel('Customer Rating'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Any', '4.0+ ★', '4.5+ ★'].map((r) {
                              return buildChip(r, tempRating == r, () {
                                setModalState(() => tempRating = r);
                              });
                            }).toList(),
                          ),

                          // 5. Amenities
                          buildSectionLabel('Amenities & Features'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Floodlights',
                              'Parking',
                              'Restroom',
                              'Drinking Water',
                              'Air Conditioning',
                            ].map((a) {
                              final isSelected = tempAmenities.contains(a);
                              return buildChip(a, isSelected, () {
                                setModalState(() {
                                  if (isSelected) {
                                    tempAmenities.remove(a);
                                  } else {
                                    tempAmenities.add(a);
                                  }
                                });
                              });
                            }).toList(),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    // Bottom Apply Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _filterSport = tempSport;
                                _filterDistance = tempDistance;
                                _filterPrice = tempPrice;
                                _filterRating = tempRating;
                                _filterAmenities.clear();
                                _filterAmenities.addAll(tempAmenities);

                                for (var cat in _categories) {
                                  cat['isSelected'] = (cat['name'] == _filterSport);
                                }
                              });
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF166534),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showJoinMatchDialog(BuildContext context, Map<String, dynamic> match) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Join Match?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Do you want to join the match between ${match['t1Name']} and ${match['t2Name']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Successfully Joined Match!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
