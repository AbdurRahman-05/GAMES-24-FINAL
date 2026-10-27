import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:games24_player_app/booking_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Map<String, dynamic>> _allTurfs = [];
  bool _isLoadingTurfs = true;
  String _selectedSport = 'All Sports';

  @override
  void initState() {
    super.initState();
    _fetchTurfs();
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
      debugPrint("Error fetching turfs in explore_screen: $e");
    }
    if (mounted) {
      setState(() => _isLoadingTurfs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTurfs = _allTurfs.where((turf) {
      if (_selectedSport == 'All Sports') return true;
      final sports = turf['sports'];
      if (sports is List) {
        return sports.any((s) => s.toString().toLowerCase().contains(_selectedSport.toLowerCase()));
      }
      return turf['sports']?.toString().toLowerCase().contains(_selectedSport.toLowerCase()) ?? false;
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 16),
          // Filter Chips
          _buildFilterChips(),
          const SizedBox(height: 24),
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isLoadingTurfs
                      ? 'Discovering Turfs...'
                      : '${filteredTurfs.length} Verified Turfs Available',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF0F6D38)),
                  tooltip: 'Refresh Turfs',
                  onPressed: () {
                    setState(() => _isLoadingTurfs = true);
                    _fetchTurfs();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // List of Turfs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildTurfsList(filteredTurfs),
          ),
        ],
      ),
    );
  }

  Widget _buildTurfsList(List<Map<String, dynamic>> turfs) {
    if (_isLoadingTurfs) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F6D38)),
        ),
      );
    }

    if (turfs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Column(
          children: [
            Icon(Icons.sports_soccer_rounded, size: 52, color: Color(0xFF9CA3AF)),
            SizedBox(height: 12),
            Text(
              'No Verified Turfs Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
            ),
            SizedBox(height: 6),
            Text(
              'When an admin registers a turf and Super Admin approves it, it will appear here in real-time.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: turfs.map((turf) {
        final List<String> amenities = (turf['amenities'] is List)
            ? (turf['amenities'] as List).map((e) => e.toString()).toList()
            : ['Floodlights', 'Parking', 'Restroom'];

        final List<String> photoUrls = (turf['photoUrls'] is List)
            ? (turf['photoUrls'] as List).map((e) => e.toString()).toList()
            : [turf['imageUrl'] ?? 'https://picsum.photos/seed/turf1/800/400'];

        final List<String> sportsList = (turf['sports'] is List)
            ? (turf['sports'] as List).map((e) => e.toString()).toList()
            : (turf['sports']?.toString().split(' • ') ?? ['Football', 'Cricket']);

        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: _buildTurfCard(
            turfId: turf['id'] is int ? turf['id'] as int : int.tryParse(turf['id']?.toString() ?? ''),
            name: turf['venueName'] ?? turf['name'] ?? 'Turf Arena',
            location: turf['location'] ?? 'Madurai',
            price: turf['price'] ?? '₹1,200',
            rating: turf['rating']?.toString() ?? '4.9',
            reviews: turf['reviews']?.toString() ?? '128',
            imageUrl: turf['imageUrl'] ?? photoUrls.first,
            photoUrls: photoUrls,
            amenities: amenities,
            openingTime: turf['openingTime'] ?? '06:00 AM',
            closingTime: turf['closingTime'] ?? '10:00 PM',
            availabilityText: 'Available Today',
            isAvailable: true,
            sports: sportsList,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: Color(0xFF6B7280), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Map<String, dynamic>>.empty();
                }
                return _allTurfs.where((turf) {
                  final name = (turf['venueName'] ?? turf['name'] ?? '').toString().toLowerCase();
                  final loc = (turf['location'] ?? '').toString().toLowerCase();
                  final q = textEditingValue.text.toLowerCase();
                  return name.contains(q) || loc.contains(q);
                });
              },
              displayStringForOption: (option) => option['venueName'] ?? option['name'] ?? '',
              onSelected: (option) {
                final List<String> photoUrls = (option['photoUrls'] is List)
                    ? (option['photoUrls'] as List).map((e) => e.toString()).toList()
                    : [option['imageUrl'] ?? 'https://picsum.photos/seed/turf1/800/400'];

                final List<String> amenities = (option['amenities'] is List)
                    ? (option['amenities'] as List).map((e) => e.toString()).toList()
                    : ['Floodlights', 'Parking', 'Restroom'];

                final List<String> sports = (option['sports'] is List)
                    ? (option['sports'] as List).map((e) => e.toString()).toList()
                    : (option['sports']?.toString().split(' • ') ?? ['Football', 'Cricket']);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(
                      turfId: option['id'] is int ? option['id'] as int : int.tryParse(option['id']?.toString() ?? ''),
                      turfName: option['venueName'] ?? option['name'] ?? 'Turf Arena',
                      imageUrl: option['imageUrl'] ?? photoUrls.first,
                      photoUrls: photoUrls,
                      amenities: amenities,
                      openingTime: option['openingTime'] ?? '06:00 AM',
                      closingTime: option['closingTime'] ?? '10:00 PM',
                      price: option['price'] ?? '₹1,200',
                      location: option['location'] ?? 'Madurai',
                      sports: sports,
                    ),
                  ),
                );
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Search turfs, locations, sports...',
                    hintStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.only(top: 10),
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
                      width: MediaQuery.of(context).size.width - 92,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          final imgUrl = option['imageUrl'] ??
                              ((option['photoUrls'] is List && (option['photoUrls'] as List).isNotEmpty)
                                  ? (option['photoUrls'] as List).first
                                  : 'https://picsum.photos/seed/turf1/800/400');
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imgUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.sports_soccer, size: 20, color: Colors.grey),
                                ),
                              ),
                            ),
                            title: Text(
                              option['venueName'] ?? option['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              option['location'] ?? '',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tune, color: Color(0xFF0F6D38), size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        children: [
          _buildChip('All Sports', Icons.sports_soccer),
          const SizedBox(width: 8),
          _buildChip('Football', Icons.sports_soccer),
          const SizedBox(width: 8),
          _buildChip('Cricket', Icons.sports_cricket),
          const SizedBox(width: 8),
          _buildChip('Tennis', Icons.sports_tennis),
          const SizedBox(width: 8),
          _buildChip('Basketball', Icons.sports_basketball),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    final isSelected = _selectedSport == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSport = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F6D38) : const Color(0xFFF3F5F1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurfCard({
    int? turfId,
    required String name,
    required String location,
    required String price,
    required String rating,
    required String reviews,
    required String imageUrl,
    required List<String> photoUrls,
    required List<String> amenities,
    required String openingTime,
    required String closingTime,
    required String availabilityText,
    required bool isAvailable,
    required List<String> sports,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.sports_soccer, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              // Rating Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviews)',
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              // Availability Badge
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAvailable ? const Color(0xFF0F6D38) : const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        availabilityText,
                        style: const TextStyle(
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
          // Content Area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Color(0xFF6B7280), size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Starts from',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              price,
                              style: const TextStyle(
                                color: Color(0xFF0F6D38),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              '/hr',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: sports.map((sport) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    sport.toLowerCase().contains('cricket') ? Icons.sports_cricket : Icons.sports_soccer,
                                    size: 12,
                                    color: const Color(0xFF4B5563),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    sport,
                                    style: const TextStyle(
                                      color: Color(0xFF4B5563),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                              sports: sports,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6D38),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Book Slot',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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
}
