import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:games24_player_app/booking_screen.dart';
import 'package:games24_player_app/challenge_manager.dart';
import 'package:games24_player_app/tournaments_screen.dart';
import 'package:games24_player_app/my_bookings_screen.dart';
import 'package:games24_player_app/teams_hub_screen.dart';
import 'package:games24_player_app/booking_manager.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onExploreTap;

  const HomeScreen({super.key, this.onExploreTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _allTurfs = [];
  bool _isLoadingTurfs = true;

  @override
  void initState() {
    super.initState();
    _fetchTurfs();
    BookingManager().fetchBookings();
    ChallengeManager().syncWithCurrentUser();
  }

  Future<void> _fetchTurfs() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/turfs'));
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
    {'name': 'Football', 'icon': Icons.sports_soccer, 'isSelected': true},
    {'name': 'Cricket', 'icon': Icons.sports_cricket, 'isSelected': false},
    {'name': 'Tennis', 'icon': Icons.sports_tennis, 'isSelected': false},
    {
      'name': 'Basketball',
      'icon': Icons.sports_basketball,
      'isSelected': false,
    },
    {'name': 'Go-Kart', 'icon': Icons.directions_car, 'isSelected': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: RefreshIndicator(
        color: const Color(0xFF166534),
        onRefresh: () async {
          await Future.wait([_fetchTurfs(), BookingManager().fetchBookings()]);
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
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSearchBar(),
                  ),

                  const SizedBox(height: 24),
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
                          builder: (context) => const TournamentsScreen(),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSectionHeader(
                      'Nearby Turfs',
                      'See all',
                      trailingIcon: Icons.near_me_outlined,
                      onActionTap: widget.onExploreTap,
                    ),
                  ),
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

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.search, color: Color(0xFF6B7280)),
                const SizedBox(width: 12),
                Expanded(
                  child: Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty();
                      }
                      return _allTurfs.where((turf) {
                        return turf['name'].toString().toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        );
                      });
                    },
                    displayStringForOption: (option) => option['name'],
                    onSelected: (option) {
                      final int? tId = option['id'] is int
                          ? option['id'] as int
                          : int.tryParse(option['id']?.toString() ?? '');
                      final List<String> sportsList = (option['sports'] is List)
                          ? (option['sports'] as List)
                                .map((e) => e.toString())
                                .toList()
                          : (option['sports']?.toString().split(' • ') ??
                                ['Football', 'Box Cricket']);
                      final List<String> photoUrls =
                          (option['photoUrls'] is List)
                          ? (option['photoUrls'] as List)
                                .map((e) => e.toString())
                                .toList()
                          : [
                              option['imageUrl'] ??
                                  'https://picsum.photos/seed/turf1/800/400',
                            ];
                      final List<String> amenities =
                          (option['amenities'] is List)
                          ? (option['amenities'] as List)
                                .map((e) => e.toString())
                                .toList()
                          : ['Floodlights', 'Parking', 'Restroom'];

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(
                            turfId: tId,
                            turfName:
                                option['venueName'] ??
                                option['name'] ??
                                'Turf Arena',
                            imageUrl: option['imageUrl'] ?? photoUrls.first,
                            photoUrls: photoUrls,
                            amenities: amenities,
                            openingTime: option['openingTime'] ?? '06:00 AM',
                            closingTime: option['closingTime'] ?? '10:00 PM',
                            price: option['price'] ?? '₹1,200',
                            location: option['location'] ?? 'Madurai',
                            sports: sportsList,
                          ),
                        ),
                      );
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              hintText: 'Search turfs...',
                              hintStyle: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.only(top: 14),
                            ),
                            style: const TextStyle(fontSize: 14),
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: MediaQuery.of(context).size.width - 86,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE5E7EB),
                                  ),
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      option['imageUrl'],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(
                                    option['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    option['location'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            _showFilterBottomSheet(context);
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF166534),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune, color: Colors.white),
          ),
        ),
      ],
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
                for (var category in _categories) {
                  category['isSelected'] = false;
                }
                _categories[index]['isSelected'] = true;
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
    final matches = [
      {
        'time': 'Today, 7:00 PM',
        'slots': '5 slots left',
        't1Initials': 'FC',
        't1Name': 'Strikers',
        't1Color': const Color(0xFF166534),
        't2Initials': 'UN',
        't2Name': 'United',
        't2Color': const Color(0xFFBE123C),
        'location': 'Elite Arena, Turf 2',
      },
      {
        'time': 'Tomorrow, 6:00 PM',
        'slots': '2 slots left',
        't1Initials': 'KN',
        't1Name': 'Knights',
        't1Color': Colors.blue.shade800,
        't2Initials': 'TI',
        't2Name': 'Titans',
        't2Color': Colors.orange.shade800,
        'location': 'City Sports Club, Turf 1',
      },
    ];

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
              child: Row(
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
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOpenChallenges() {
    return ValueListenableBuilder<List<Challenge>>(
      valueListenable: ChallengeManager().challengesNotifier,
      builder: (context, challenges, child) {
        if (challenges.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('No open challenges available.'),
          );
        }
        return SizedBox(
          height: 160,
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
                child: Text(
                  challenge.turfName,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
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

    return Column(
      children: _allTurfs.map((turf) {
        final List<String> tags = (turf['amenities'] is List)
            ? (turf['amenities'] as List).map((e) => e.toString()).toList()
            : ['Floodlights', 'Parking', 'Restroom'];

        final List<String> photoUrls = (turf['photoUrls'] is List)
            ? (turf['photoUrls'] as List).map((e) => e.toString()).toList()
            : [turf['imageUrl'] ?? 'https://picsum.photos/seed/turf1/800/400'];

        final sportsStr = (turf['sports'] is List)
            ? (turf['sports'] as List).join(' • ')
            : (turf['sports']?.toString() ?? 'Football • Box Cricket');

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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Distance',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(value: 5, min: 1, max: 20, onChanged: (val) {}),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF166534),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
