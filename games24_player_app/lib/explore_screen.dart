import 'package:flutter/material.dart';
import 'package:games24_player_app/booking_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<Map<String, dynamic>> _allTurfs = [
    {
      'name': 'Apex Sports Club',
      'price': '₹1,200',
      'location': 'Koramangala • 1.2 km away',
      'imageUrl': 'https://picsum.photos/seed/turf1/800/400',
      'rating': '4.9',
      'reviews': '128',
      'sports': 'Football • Cricket',
      'tags': ['Floodlights', 'Parking', 'Changing Room'],
    },
    {
      'name': 'Metro Arena Indoor',
      'price': '₹950',
      'location': 'Indiranagar • 2.5 km away',
      'imageUrl': 'https://picsum.photos/seed/turf2/800/400',
      'rating': '4.7',
      'reviews': '94',
      'sports': 'Badminton • Tennis',
      'tags': ['Indoor AC', 'Cafeteria'],
    },
    {
      'name': 'Green Valley Arena',
      'price': '₹1,500',
      'location': 'HSR Layout • 3.0 km away',
      'imageUrl': 'https://picsum.photos/seed/turf3/800/400',
      'rating': '4.8',
      'reviews': '210',
      'sports': 'Football • Basketball',
      'tags': ['Synthetic Grass', 'Washrooms'],
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  '12 Turfs Nearby',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // List of Turfs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildTurfCard(
                  name: 'Strikers Arena & Turf',
                  location: 'Koramangala 4th Block • 1.2 km away',
                  price: '₹899',
                  rating: '4.9',
                  reviews: '128',
                  imageUrl: 'https://picsum.photos/seed/turf10/800/400',
                  availabilityText: 'Available Today',
                  isAvailable: true,
                  sports: ['Football', 'Cricket'],
                ),
                const SizedBox(height: 20),
                _buildTurfCard(
                  name: 'Skyline Rooftop Sports',
                  location: 'Indiranagar 100ft Rd • 2.8 km away',
                  price: '₹1,200',
                  rating: '4.7',
                  reviews: '94',
                  imageUrl: 'https://picsum.photos/seed/turf11/800/400',
                  availabilityText: 'Almost Full (2 slots left)',
                  isAvailable: false,
                  sports: ['Football'],
                ),
                const SizedBox(height: 20),
                _buildTurfCard(
                  name: 'ProKick Indoor Arena',
                  location: 'HSR Layout Sector 2 • 3.5 km away',
                  price: '₹750',
                  rating: '4.8',
                  reviews: '210',
                  imageUrl: 'https://picsum.photos/seed/turf12/800/400',
                  availabilityText: 'Available Today',
                  isAvailable: true,
                  sports: ['Football', 'Cricket'],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
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
                  return turf['name']
                      .toString()
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              displayStringForOption: (option) => option['name'],
              onSelected: (option) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(
                      turfName: option['name'],
                      imageUrl: option['imageUrl'],
                      price: option['price'],
                      location: option['location'],
                      sports: (option['sports'] as String).split(' • '),
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
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(option['imageUrl'], width: 40, height: 40, fit: BoxFit.cover),
                            ),
                            title: Text(option['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(option['location'], style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
          _buildChip('All Sports', Icons.sports_soccer, true),
          const SizedBox(width: 8),
          _buildChip('Cricket', Icons.sports_cricket, false),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, bool isSelected) {
    return Container(
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
    );
  }

  Widget _buildTurfCard({
    required String name,
    required String location,
    required String price,
    required String rating,
    required String reviews,
    required String imageUrl,
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
                    Row(
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
                                sport == 'Football' ? Icons.sports_soccer : Icons.sports_cricket,
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
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingScreen(
                              turfName: name,
                              imageUrl: imageUrl,
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
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Book Slot',
                        style: TextStyle(
                          fontSize: 15,
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
