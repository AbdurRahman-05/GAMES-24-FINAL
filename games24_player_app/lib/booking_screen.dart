import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'booking_manager.dart';

class BookingScreen extends StatefulWidget {
  final int? turfId;
  final String turfName;
  final String imageUrl;
  final String price;
  final String location;
  final List<String> sports;
  final List<String>? photoUrls;
  final List<String>? amenities;
  final String? openingTime;
  final String? closingTime;

  const BookingScreen({
    super.key,
    this.turfId,
    required this.turfName,
    required this.imageUrl,
    required this.price,
    required this.location,
    required this.sports,
    this.photoUrls,
    this.amenities,
    this.openingTime,
    this.closingTime,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int? _resolvedTurfId;
  int _selectedDateIndex = 0;
  String _selectedSport = 'Football';
  final Set<String> _selectedTimeSlots = {};
  bool _isOpenForChallenge = false;
  final TextEditingController _teamNameController = TextEditingController();
  int _currentImageIndex = 0;
  bool _isLoadingSlots = false;
  bool _isBookingInProgress = false;
  List<Map<String, dynamic>> _slots = [];
  late final List<Map<String, String>> _dates;

  @override
  void initState() {
    super.initState();
    _resolvedTurfId = widget.turfId;
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    _dates = List.generate(7, (i) {
      final d = now.add(Duration(days: i));
      return {
        'day': weekdays[d.weekday - 1],
        'date': d.day.toString().padLeft(2, '0'),
        'fullDate': "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}",
      };
    });

    if (widget.sports.isNotEmpty) {
      _selectedSport = widget.sports.first;
    }

    _loadSlots();
  }

  Future<int?> _getEffectiveTurfId() async {
    if (_resolvedTurfId != null) return _resolvedTurfId;
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/turfs')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        final match = list.firstWhere(
          (t) => (t['venueName']?.toString().toLowerCase() == widget.turfName.toLowerCase()) ||
                 (t['name']?.toString().toLowerCase() == widget.turfName.toLowerCase()),
          orElse: () => list.isNotEmpty ? list.first : null,
        );
        if (match != null && match['id'] != null) {
          _resolvedTurfId = match['id'] is int ? match['id'] : int.tryParse(match['id'].toString());
        }
      }
    } catch (e) {
      debugPrint("Error resolving turfId: $e");
    }
    _resolvedTurfId ??= 1;
    return _resolvedTurfId;
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    if (!mounted) return;
    setState(() => _isLoadingSlots = true);
    final targetDate = _dates[_selectedDateIndex]['fullDate']!;

    final effectiveTurfId = await _getEffectiveTurfId();

    if (effectiveTurfId != null) {
      try {
        final res = await http
            .get(Uri.parse('http://localhost:3000/turfs/$effectiveTurfId/slots?date=$targetDate'))
            .timeout(const Duration(seconds: 5));
        if (!mounted) return;
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          if (json['slots'] is List) {
            final rawPrice = int.tryParse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1200;
            if (!mounted) return;
            setState(() {
              _slots = (json['slots'] as List)
                  .where((s) {
                    final map = s is Map ? s : <String, dynamic>{};
                    final status = map['status']?.toString().toLowerCase();
                    return status != 'blocked';
                  })
                  .map<Map<String, dynamic>>((s) {
                final map = s is Map ? s : <String, dynamic>{};
                final timeVal = (map['slot'] ?? map['time'])?.toString() ?? '';
                return <String, dynamic>{
                  'slot': timeVal,
                  'time': timeVal,
                  'status': map['status']?.toString() ?? 'available',
                  'price': map['price'] ?? rawPrice,
                  'originalPrice': map['originalPrice'] ?? map['price'] ?? rawPrice,
                  'rateType': map['rateType']?.toString() ?? '',
                  'isNight': map['isNight'] == true,
                  'offer': map['offer'],
                  'offerTag': map['offerTag'],
                };
              }).toList();
              _isLoadingSlots = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint("Error fetching slots in BookingScreen: $e");
      }
    }

    if (!mounted) return;
    // Fallback: auto-split 1-hour slots from turf schedule
    final rawPrice = int.tryParse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1200;
    final generated = AppConstants.generateTimeSlots(
      widget.openingTime ?? '06:00 AM',
      widget.closingTime ?? '10:00 PM',
    );
    if (!mounted) return;
    setState(() {
      _slots = generated.map<Map<String, dynamic>>((s) => <String, dynamic>{
        'slot': s,
        'time': s,
        'status': 'available',
        'price': rawPrice,
        'isNight': false,
      }).toList();
      _isLoadingSlots = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.turfName,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFFBE123C)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroImage(),
            const SizedBox(height: 16),
            _buildFacilities(),
            const SizedBox(height: 20),
            _buildDateSelector(),
            const SizedBox(height: 20),
            _buildSportSelector(),
            const SizedBox(height: 20),
            _buildTimeSlots(),
            const SizedBox(height: 20),
            _buildChallengeOption(),
            const SizedBox(height: 24),
            _buildBookingSummary(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildBottomButton(),
    );
  }

  Widget _buildHeroImage() {
    final images = (widget.photoUrls != null && widget.photoUrls!.isNotEmpty)
        ? widget.photoUrls!
        : [widget.imageUrl];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                itemCount: images.length,
                onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.sports_soccer_rounded, size: 48, color: Colors.grey),
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                ),
              ),
              if (images.length > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1} / ${images.length} Photos',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF166534),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Super Admin Verified Turf',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.turfName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.location,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacilities() {
    final list = (widget.amenities != null && widget.amenities!.isNotEmpty)
        ? widget.amenities!
        : ['Drinking Water', 'Parking', 'Floodlights', 'Restroom'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Facilities & Amenities',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              if (widget.openingTime != null && widget.closingTime != null)
                Text(
                  '${widget.openingTime} - ${widget.closingTime}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: list.map((item) {
              IconData icon = Icons.check_circle_outline_rounded;
              final lower = item.toLowerCase();
              if (lower.contains('water')) {
                icon = Icons.water_drop_outlined;
              } else if (lower.contains('park')) {
                icon = Icons.local_parking_rounded;
              } else if (lower.contains('light')) {
                icon = Icons.lightbulb_outline_rounded;
              } else if (lower.contains('rest') || lower.contains('toilet')) {
                icon = Icons.wc_rounded;
              } else if (lower.contains('room')) {
                icon = Icons.meeting_room_outlined;
              } else if (lower.contains('aid')) {
                icon = Icons.medical_services_outlined;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF166534).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF166534).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: const Color(0xFF166534)),
                    const SizedBox(width: 5),
                    Text(
                      item,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Date',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              Row(
                children: [
                  Text(
                    _dates[_selectedDateIndex]['fullDate']!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_month, color: Color(0xFF166534), size: 18),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _dates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final date = _dates[index];
              final isSelected = _selectedDateIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDateIndex = index;
                    _selectedTimeSlots.clear();
                  });
                  _loadSlots();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 54,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F6D38) : const Color(0xFFF3F5F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date['day']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white70 : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date['date']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSportSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Select Sport',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: widget.sports.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final sport = widget.sports[index];
              final isSelected = _selectedSport == sport;
              IconData iconData = Icons.sports_soccer;
              if (sport.toLowerCase().contains('cricket')) iconData = Icons.sports_cricket;
              if (sport.toLowerCase().contains('badminton')) iconData = Icons.sports_tennis;
              if (sport.toLowerCase().contains('basketball')) iconData = Icons.sports_basketball;

              return GestureDetector(
                onTap: () => setState(() => _selectedSport = sport),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F6D38) : const Color(0xFFF3F5F1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconData, size: 14, color: isSelected ? Colors.white : const Color(0xFF4B5563)),
                      const SizedBox(width: 6),
                      Text(
                        sport,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    if (_isLoadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF166534))),
      );
    }

    int parseStartHour(Map<String, dynamic> slot) {
      final t = (slot['time'] ?? slot['slot'] ?? '').toString().trim();
      final startPart = t.split('-').first.trim();
      final parts = startPart.split(' ');
      if (parts.isEmpty) return -1;
      final timeParts = parts[0].split(':');
      int hour = int.tryParse(timeParts[0]) ?? -1;
      if (hour == -1) return -1;
      final period = parts.length > 1 ? parts[1].toUpperCase() : '';
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return hour;
    }

    final morning = _slots.where((s) {
      final h = parseStartHour(s);
      return h >= 5 && h < 12;
    }).toList();
    final afternoon = _slots.where((s) {
      final h = parseStartHour(s);
      return h >= 12 && h < 17;
    }).toList();
    final evening = _slots.where((s) {
      final h = parseStartHour(s);
      return h >= 17 || (h >= 0 && h < 5);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Slots (1-Hour Intervals)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              Row(
                children: [
                  _buildLegendItem('Available', const Color(0xFFE5F5EB)),
                  const SizedBox(width: 6),
                  _buildLegendItem('Selected', const Color(0xFF0F6D38)),
                  const SizedBox(width: 6),
                  _buildLegendItem('Booked', const Color(0xFFDC2626)),
                ],
              ),
            ],
          ),
          if (morning.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSlotSection('MORNING SLOTS', morning),
          ],
          if (afternoon.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSlotSection('AFTERNOON SLOTS', afternoon),
          ],
          if (evening.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSlotSection('EVENING / NIGHT SLOTS', evening),
          ],
          if (morning.isEmpty && afternoon.isEmpty && evening.isEmpty) ...[
            const SizedBox(height: 24),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No available slots for this date.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildSlotSection(String title, List<Map<String, dynamic>> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) {
                final isBooked = slot['status'] == 'booked';
                final isBlocked = slot['status'] == 'blocked';
                final isSelected = _selectedTimeSlots.contains(slot['time']);

                final offer = slot['offer'] is Map ? slot['offer'] as Map : null;
                final offerTag = slot['offerTag']?.toString() ?? '';
                final hasOffer = offer != null || offerTag.isNotEmpty;
                final origPrice = (slot['originalPrice'] ?? slot['price'] ?? 1000);
                final currentPrice = (slot['price'] ?? 1000);
                final bool hasPriceDiscount = hasOffer && origPrice != currentPrice;

                String badgeText = '';
                if (offer != null) {
                  if (offer['tagLabel'] != null && offer['tagLabel'].toString().isNotEmpty) {
                    badgeText = offer['tagLabel'].toString();
                  } else if (offer['discountPercent'] != null && (offer['discountPercent'] as num) > 0) {
                    badgeText = '${offer['discountPercent']}% OFF';
                  }
                } else if (offerTag.startsWith('PERCENT|')) {
                  final p = offerTag.split('|');
                  badgeText = p.length > 2 && p[2].isNotEmpty ? p[2] : '${p[1]}% OFF';
                } else if (offerTag.startsWith('PRICE|')) {
                  badgeText = 'Special Price';
                }

                Color bgColor = const Color(0xFFF3F5F1);
                Color textColor = const Color(0xFF111827);
                Color borderColor = Colors.transparent;

                if (isBooked) {
                  bgColor = const Color(0xFFFEE2E2);
                  textColor = const Color(0xFFDC2626);
                } else if (isBlocked) {
                  bgColor = Colors.amber.shade50;
                  textColor = Colors.amber.shade900;
                  borderColor = Colors.amber.shade300;
                } else if (isSelected) {
                  bgColor = const Color(0xFF0F6D38);
                  textColor = Colors.white;
                  borderColor = const Color(0xFF166534);
                } else if (hasOffer) {
                  bgColor = const Color(0xFFF0FDF4);
                  borderColor = const Color(0xFF15803D).withValues(alpha: 0.35);
                }

                return SizedBox(
                  width: itemWidth,
                  child: GestureDetector(
                    onTap: (isBooked || isBlocked)
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isBooked ? 'Slot is already booked.' : 'Slot is blocked for maintenance.'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        : () {
                            setState(() {
                              if (_selectedTimeSlots.contains(slot['time'])) {
                                _selectedTimeSlots.remove(slot['time']);
                              } else {
                                _selectedTimeSlots.clear();
                                _selectedTimeSlots.add(slot['time']);
                              }
                            });
                          },
                    child: Container(
                      height: (hasOffer && badgeText.isNotEmpty) ? 60 : 52,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slot['time'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9.0,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (isBooked || isBlocked) ...[
                            Text(
                              isBooked ? 'Booked' : 'Blocked',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ] else if (hasPriceDiscount) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '₹$origPrice',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: isSelected ? Colors.white70 : const Color(0xFF9CA3AF),
                                    color: isSelected ? Colors.white70 : const Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '₹$currentPrice',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                            if (badgeText.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFF15803D),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (slot['isNight'] == true) ...[
                                  Icon(
                                    Icons.nightlight_round,
                                    size: 9,
                                    color: isSelected ? Colors.white70 : const Color(0xFF166534),
                                  ),
                                  const SizedBox(width: 2),
                                ],
                                Text(
                                  '₹${slot['price'] ?? 1000}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                            if (badgeText.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFF15803D),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChallengeOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFBE123C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Open for Challenge?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Let other teams request to match with you.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isOpenForChallenge,
                  activeColor: const Color(0xFFBE123C),
                  onChanged: (val) {
                    setState(() {
                      _isOpenForChallenge = val;
                    });
                  },
                ),
              ],
            ),
            if (_isOpenForChallenge) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _teamNameController,
                decoration: InputDecoration(
                  hintText: 'Enter your Team Name',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _calculateCourtFee() {
    final rawPrice = int.tryParse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1200;
    int fee = 0;
    for (final s in _selectedTimeSlots) {
      Map<String, dynamic>? slotObj;
      for (final element in _slots) {
        if ((element['slot'] ?? element['time']) == s) {
          slotObj = element;
          break;
        }
      }
      final p = (slotObj != null && slotObj['price'] is num)
          ? (slotObj['price'] as num).toInt()
          : rawPrice;
      fee += p;
    }
    return fee;
  }

  Widget _buildBookingSummary() {
    final slotCount = _selectedTimeSlots.length;
    final courtFee = _calculateCourtFee();
    final convFee = slotCount > 0 ? 50 : 0;
    final taxes = slotCount > 0 ? 40 : 0;
    final total = courtFee + convFee + taxes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Selected Date', _dates[_selectedDateIndex]['fullDate']!),
            const SizedBox(height: 8),
            _buildSummaryRow('Selected Sport', _selectedSport),
            const SizedBox(height: 8),
            _buildSummaryRow('Slots Count', '$slotCount slot(s)'),
            const SizedBox(height: 8),
            _buildSummaryRow('Court Fee', '₹$courtFee'),
            const SizedBox(height: 8),
            _buildSummaryRow('Convenience & Taxes', '₹${convFee + taxes}'),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Payable',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
                Text(
                  '₹$total',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: Color(0xFF111827), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final courtFee = _calculateCourtFee();
    final total = courtFee + (_selectedTimeSlots.isNotEmpty ? 90 : 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isBookingInProgress
                ? null
                : () async {
                    if (_selectedTimeSlots.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select at least one available slot.')),
                      );
                      return;
                    }

                    if (_isOpenForChallenge && _teamNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter your team name for open challenge.')),
                      );
                      return;
                    }

                    final selectedSlot = _selectedTimeSlots.first;
                    final selectedDate = _dates[_selectedDateIndex]['fullDate']!;

                    setState(() => _isBookingInProgress = true);
                    try {
                      final effectiveTurfId = await _getEffectiveTurfId();
                      if (effectiveTurfId != null) {
                        final prefs = await SharedPreferences.getInstance();
                        String customerName = (prefs.getString('fullName') ?? '').trim();
                        String customerPhone = (prefs.getString('mobileNumber') ?? '').trim();

                        if (customerName.isEmpty) {
                          customerName = 'Vignesh';
                        }
                        if (customerPhone.isEmpty) {
                          customerPhone = '+917010396731';
                        }

                        final res = await http.post(
                          Uri.parse('http://localhost:3000/turfs/$effectiveTurfId/book'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'customerName': customerName,
                            'customerPhone': customerPhone,
                            'sport': _selectedSport,
                            'courtName': widget.turfName,
                            'date': selectedDate,
                            'timeSlot': selectedSlot,
                            'amount': courtFee.toDouble(),
                            'paymentMethod': 'UPI (GPay)',
                          }),
                        );

                        if (res.statusCode == 200 || res.statusCode == 201) {
                          try {
                            final resData = jsonDecode(res.body);
                            final bookingObj = resData['booking'] is Map
                                ? Map<String, dynamic>.from(resData['booking'])
                                : <String, dynamic>{};
                            bookingObj['turfName'] = widget.turfName;
                            bookingObj['imageUrl'] = widget.imageUrl;
                            bookingObj['location'] = widget.location;
                            bookingObj['courtName'] = widget.turfName;
                            bookingObj['isActive'] = true;
                            if (bookingObj['date'] == null) bookingObj['date'] = selectedDate;
                            if (bookingObj['timeSlot'] == null) bookingObj['timeSlot'] = selectedSlot;
                            if (bookingObj['status'] == null) bookingObj['status'] = 'Confirmed';
                            BookingManager().addBooking(bookingObj);
                          } catch (e) {
                            debugPrint('Error caching booking locally: $e');
                          }
                          BookingManager().fetchBookings();

                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Color(0xFF166534), size: 28),
                                    SizedBox(width: 8),
                                    Text('Booking Confirmed!'),
                                  ],
                                ),
                                content: Text(
                                  'Your slot "$selectedSlot" on $selectedDate at ${widget.turfName} has been booked in realtime!\n\nIt is now saved in the database and updated in both Player and Turf Owner dashboards.',
                                ),
                                actions: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF166534),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _selectedTimeSlots.clear();
                                      _loadSlots();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                        } else {
                          final json = jsonDecode(res.body);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(json['message'] ?? 'Booking failed. Slot may already be booked.'),
                                backgroundColor: const Color(0xFFDC2626),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            _selectedTimeSlots.clear();
                            _loadSlots(); // Immediately refresh to show real-time slot status
                          }
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Booking Confirmed!')),
                          );
                          Navigator.pop(context);
                        }
                      }
                    } catch (e) {
                      debugPrint("Error creating booking: $e");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Booking error: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isBookingInProgress = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF166534),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isBookingInProgress
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Confirm Booking',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      if (_selectedTimeSlots.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '- ₹$total',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
