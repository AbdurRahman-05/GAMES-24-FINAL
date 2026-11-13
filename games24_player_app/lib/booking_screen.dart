import 'main_layout.dart';
import 'api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'booking_manager.dart';
import 'challenge_manager.dart';
import 'booking_qr_pass_modal.dart';

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
  final List<dynamic>? sportsList;
  final List<dynamic>? courts;
  final Map<String, dynamic>? turf;
  final String? initialSport;

  const BookingScreen({
    super.key,
    this.turfId,
    required this.turfName,
    required this.imageUrl,
    required this.price,
    required this.location,
    required this.sports,
    this.sportsList,
    this.courts,
    this.photoUrls,
    this.amenities,
    this.openingTime,
    this.closingTime,
    this.turf,
    this.initialSport,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int? _resolvedTurfId;
  int _selectedDateIndex = 0;
  String _selectedSport = 'Football';
  String? _selectedCourt;
  List<dynamic> _turfCourts = [];
  final Set<String> _selectedTimeSlots = {};
  bool _isOpenForChallenge = false;
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _teamSizeController = TextEditingController();
  int _currentImageIndex = 0;
  bool _isLoadingSlots = false;
  bool _isBookingInProgress = false;
  bool _showPassedSlots = false;
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
        'fullDate':
            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}",
      };
    });

    final rawCourts = (widget.courts != null && widget.courts!.isNotEmpty)
        ? widget.courts!
        : (widget.turf != null && widget.turf!['courts'] is List && (widget.turf!['courts'] as List).isNotEmpty)
            ? widget.turf!['courts'] as List
            : [];
    _turfCourts = _filterRealCourts(rawCourts);

    final sports = _availableSports;
    if (widget.initialSport != null &&
        widget.initialSport!.isNotEmpty &&
        widget.initialSport!.toLowerCase() != 'all') {
      final match = sports.firstWhere(
        (s) => s.toLowerCase().trim() == widget.initialSport!.toLowerCase().trim(),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        _selectedSport = match;
      } else if (sports.isNotEmpty) {
        _selectedSport = sports.first;
      } else {
        _selectedSport = widget.initialSport!;
      }
    } else if (sports.isNotEmpty) {
      _selectedSport = sports.first;
    }
    final initialCourts = _getAvailableCourtsForSport(_selectedSport);
    if (initialCourts.isNotEmpty) {
      _selectedCourt = initialCourts.first;
    } else {
      _selectedCourt = widget.turfName;
    }

    _loadSlots();
  }

  bool get _hasSpecialSports {
    return _availableSports.any((s) {
      final sLower = s.toLowerCase().trim();
      return !sLower.contains('cricket') && !sLower.contains('football');
    });
  }

  List<dynamic> _filterRealCourts(List<dynamic> rawCourts) {
    return rawCourts.where((c) {
      if (c is! Map) return false;
      final name = c['name']?.toString().trim() ?? '';
      final isMockPattern = RegExp(
        r'^(Cricket|Football|Pickle ball|Badminton)\s+Court\s+\d+$',
        caseSensitive: false,
      ).hasMatch(name);
      return !isMockPattern;
    }).toList();
  }

  List<String> get _availableSports {
    final raw = widget.sports.isNotEmpty ? widget.sports : ['Cricket', 'Football'];

    final realCourts = _filterRealCourts(_turfCourts);
    if (realCourts.isNotEmpty) {
      final Set<String> supported = {};
      for (final c in realCourts) {
        if (c is Map) {
          if (c['sports'] is List) {
            for (final s in c['sports']) {
              if (s.toString().trim().isNotEmpty) supported.add(s.toString().trim());
            }
          }
          if (c['sport'] != null) {
            for (final s in c['sport'].toString().split(RegExp(r'[•,]'))) {
              if (s.trim().isNotEmpty) supported.add(s.trim());
            }
          }
        }
      }
      final filtered = raw.where((s) => supported.any((sup) => sup.toLowerCase() == s.toLowerCase())).toList();
      if (filtered.isNotEmpty) return filtered;
    }

    final List<String> result = [];
    for (final s in raw) {
      final sLower = s.toLowerCase();
      if (sLower.contains('cricket') || sLower.contains('football')) {
        result.add(s);
      } else {
        final hasExplicit = widget.sportsList != null && widget.sportsList!.any((m) {
          if (m is Map) {
            final name = m['name']?.toString().toLowerCase().trim() ?? '';
            return name == sLower.trim();
          }
          return false;
        });
        if (hasExplicit) {
          result.add(s);
        }
      }
    }
    return result.isNotEmpty ? result : ['Cricket', 'Football'];
  }

  List<String> _getAvailableCourtsForSport(String sport) {
    final realCourts = _filterRealCourts(_turfCourts);
    if (realCourts.isNotEmpty) {
      final matchedCourts = realCourts.where((c) {
        if (c is! Map) return false;
        if (c['sports'] is List) {
          final sportsList = (c['sports'] as List).map((s) => s.toString().toLowerCase().trim()).toList();
          if (sportsList.contains(sport.toLowerCase().trim())) return true;
        }
        final cSport = c['sport']?.toString().toLowerCase().trim() ?? '';
        if (cSport.contains(sport.toLowerCase().trim())) return true;
        return false;
      }).map((c) => (c as Map)['name']?.toString() ?? '').where((name) => name.isNotEmpty).toList();

      if (matchedCourts.isNotEmpty) return matchedCourts;

      final allRealNames = realCourts
          .map((c) => (c as Map)['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      if (allRealNames.isNotEmpty) return allRealNames;
    }

    // Single venue ground by default (no multiple courts)
    return [widget.turfName];
  }

  Future<int?> _getEffectiveTurfId() async {
    if (_resolvedTurfId != null) return _resolvedTurfId;
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/turfs'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        final match = list.firstWhere(
          (t) =>
              (t['venueName']?.toString().toLowerCase() ==
                  widget.turfName.toLowerCase()) ||
              (t['name']?.toString().toLowerCase() ==
                  widget.turfName.toLowerCase()),
          orElse: () => list.isNotEmpty ? list.first : null,
        );
        if (match != null && match['id'] != null) {
          _resolvedTurfId = match['id'] is int
              ? match['id']
              : int.tryParse(match['id'].toString());
          if (_turfCourts.isEmpty && match['courts'] is List && (match['courts'] as List).isNotEmpty) {
            _turfCourts = _filterRealCourts(match['courts'] as List);
          }
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

  double _getSportHourlyRate(String sportName) {
    final sLower = sportName.toLowerCase().trim();
    final turfBaseRate = double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1000.0;

    // For standard turf ground sports (Cricket & Football), the price is identical (unified turf rate)
    if (sLower.contains('cricket') || sLower.contains('football')) {
      return turfBaseRate;
    }

    if (widget.sportsList != null) {
      for (final s in widget.sportsList!) {
        if (s is Map &&
            s['name']?.toString().toLowerCase().trim() == sLower) {
          final rate = double.tryParse(s['hourlyRate']?.toString() ?? '');
          if (rate != null && rate > 0) return rate;
        }
      }
    }
    return turfBaseRate;
  }

  Future<void> _loadSlots() async {
    if (!mounted) return;
    setState(() => _isLoadingSlots = true);
    final targetDate = _dates[_selectedDateIndex]['fullDate']!;
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final isToday = targetDate == todayStr;
    final currentMinutes = now.hour * 60 + now.minute;

    final effectiveTurfId = await _getEffectiveTurfId();

    if (effectiveTurfId != null) {
      try {
        final encodedSport = Uri.encodeComponent(_selectedSport);
        final res = await http
            .get(
              Uri.parse(
                '${ApiConfig.baseUrl}/turfs/$effectiveTurfId/slots?date=$targetDate&sport=$encodedSport',
              ),
            )
            .timeout(const Duration(seconds: 15));
        if (!mounted) return;
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          if (json['slots'] is List) {
            final rawPrice = _getSportHourlyRate(_selectedSport).toInt();
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
                    final timeVal =
                        (map['slot'] ?? map['time'])?.toString() ?? '';
                    final slotStartMin =
                        AppConstants.parseSlotStartMinutes(timeVal);
                    final isPast = map['isPast'] == true ||
                        (isToday &&
                            slotStartMin != -1 &&
                            currentMinutes >= slotStartMin);
                    String status = map['status']?.toString() ?? 'available';
                    if (isPast && status != 'booked') {
                      status = 'passed';
                    }
                    return <String, dynamic>{
                      'slot': timeVal,
                      'time': timeVal,
                      'status': status,
                      'isPast': isPast,
                      'price': map['price'] ?? rawPrice,
                      'originalPrice':
                          map['originalPrice'] ?? map['price'] ?? rawPrice,
                      'rateType': map['rateType']?.toString() ?? '',
                      'isNight': map['isNight'] == true,
                      'offer': map['offer'],
                      'offerTag': map['offerTag'],
                    };
                  })
                  .toList();
              _selectedTimeSlots.removeWhere((t) {
                final startMin = AppConstants.parseSlotStartMinutes(t);
                return isToday && startMin != -1 && currentMinutes >= startMin;
              });
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
    final rawPrice =
        int.tryParse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1200;
    final generated = AppConstants.generateTimeSlots(
      widget.openingTime ?? '06:00 AM',
      widget.closingTime ?? '10:00 PM',
    );
    if (!mounted) return;
    setState(() {
      _slots = generated.map<Map<String, dynamic>>((s) {
        final slotStartMin = AppConstants.parseSlotStartMinutes(s);
        final isPast = isToday &&
            slotStartMin != -1 &&
            currentMinutes >= slotStartMin;
        return <String, dynamic>{
          'slot': s,
          'time': s,
          'status': isPast ? 'passed' : 'available',
          'isPast': isPast,
          'price': rawPrice,
          'isNight': false,
        };
      }).toList();
      _selectedTimeSlots.removeWhere((t) {
        final startMin = AppConstants.parseSlotStartMinutes(t);
        return isToday && startMin != -1 && currentMinutes >= startMin;
      });
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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainLayout()),
              );
            }
          },
        ),
        title: Text(
          widget.turfName,
          overflow: TextOverflow.ellipsis,
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
            if (_hasSpecialSports) ...[
              const SizedBox(height: 20),
              _buildSportSelector(),
            ],
            const SizedBox(height: 16),
            _buildCourtSelector(),
            const SizedBox(height: 20),
            _buildTimeSlots(),
            const SizedBox(height: 20),
            _buildChallengeOption(),
            const SizedBox(height: 24),
            _buildBookingSummary(),
            const SizedBox(height: 16),
            _buildCautionNotice(),
            const SizedBox(height: 120),
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
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                itemCount: images.length,
                onPageChanged: (idx) =>
                    setState(() => _currentImageIndex = idx),
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.sports_soccer_rounded,
                        size: 48,
                        color: Colors.grey,
                      ),
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
                        Colors.black.withValues(alpha: 0.75),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1} / ${images.length} Photos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF154D36),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Super Admin Verified Turf',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              if (widget.openingTime != null && widget.closingTime != null)
                Text(
                  '${widget.openingTime} - ${widget.closingTime}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF154D36),
                    fontWeight: FontWeight.bold,
                  ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF154D36).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF154D36).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: const Color(0xFF154D36)),
                    const SizedBox(width: 5),
                    Text(
                      item,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF154D36),
                      ),
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Row(
                children: [
                  Text(
                    _dates[_selectedDateIndex]['fullDate']!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.calendar_month,
                    color: Color(0xFF154D36),
                    size: 18,
                  ),
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
                    color: isSelected
                        ? const Color(0xFF154D36)
                        : const Color(0xFFF3F5F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date['day']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white70
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date['date']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF111827),
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
    if (!_hasSpecialSports) return const SizedBox.shrink();
    final sports = _availableSports;
    if (sports.isEmpty) return const SizedBox.shrink();
    if (sports.length == 1) {
      final sport = sports.first;
      final rate = _getSportHourlyRate(sport).toInt();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF154D36).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF154D36).withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sports_soccer_rounded, size: 14, color: Color(0xFF154D36)),
                  const SizedBox(width: 6),
                  Text(
                    '$sport • ₹$rate/hr',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF154D36),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Select Sport',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: sports.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final sport = sports[index];
              final isSelected = _selectedSport == sport;
              final sLower = sport.toLowerCase();
              IconData iconData = Icons.sports_soccer;
              if (sLower.contains('cricket')) {
                iconData = Icons.sports_cricket;
              } else if (sLower.contains('badminton')) {
                iconData = Icons.sports_tennis;
              } else if (sLower.contains('pickle')) {
                iconData = Icons.sports_tennis_rounded;
              } else if (sLower.contains('tennis')) {
                iconData = Icons.sports_tennis;
              } else if (sLower.contains('basketball')) {
                iconData = Icons.sports_basketball;
              }
              final rate = _getSportHourlyRate(sport).toInt();

              return GestureDetector(
                onTap: () {
                  if (_selectedSport != sport) {
                    setState(() {
                      _selectedSport = sport;
                      final courts = _getAvailableCourtsForSport(sport);
                      _selectedCourt = courts.isNotEmpty ? courts.first : null;
                      _selectedTimeSlots.clear();
                    });
                    _loadSlots();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF154D36)
                        : const Color(0xFFF3F5F1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        iconData,
                        size: 14,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF4B5563),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$sport • ₹$rate/hr',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4B5563),
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

  Widget _buildCourtSelector() {
    final courts = _getAvailableCourtsForSport(_selectedSport);
    // If the venue has only 1 court (owner did not create extra courts), hide court selector completely!
    if (courts.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Court / Arena',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                '${courts.length} Available',
                style: const TextStyle(fontSize: 11, color: Color(0xFF154D36), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: courts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final court = courts[index];
              final isSelected = _selectedCourt == court || (_selectedCourt == null && index == 0);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCourt = court;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF154D36)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF154D36) : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stadium_outlined,
                        size: 15,
                        color: isSelected ? Colors.white : const Color(0xFF4B5563),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        court,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF1F2937),
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
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF154D36)),
        ),
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

    final targetDate = _dates[_selectedDateIndex]['fullDate']!;
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final isToday = targetDate == todayStr;
    final passedSlotsCount = _slots.where((s) => s['isPast'] == true).length;

    final visibleSlots = _slots.where((s) {
      if (!isToday) return true;
      if (_showPassedSlots) return true;
      return s['isPast'] != true;
    }).toList();

    final morning = visibleSlots.where((s) {
      final h = parseStartHour(s);
      return h >= 5 && h < 12;
    }).toList();
    final afternoon = visibleSlots.where((s) {
      final h = parseStartHour(s);
      return h >= 12 && h < 17;
    }).toList();
    final evening = visibleSlots.where((s) {
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
            children: const [
              Text(
                'Available Slots',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                '1-Hour Intervals',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildLegendItem('Available', const Color(0xFFE5F5EB)),
              _buildLegendItem('Selected', const Color(0xFF154D36)),
              _buildLegendItem('Booked', const Color(0xFFDC2626)),
              if (isToday && _showPassedSlots)
                _buildLegendItem('Passed', const Color(0xFF9CA3AF)),
            ],
          ),
          if (isToday && passedSlotsCount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _showPassedSlots ? Icons.visibility_outlined : Icons.schedule_rounded,
                          size: 15,
                          color: const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _showPassedSlots
                                ? 'Showing All Slots ($passedSlotsCount passed)'
                                : 'Showing upcoming slots for today',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showPassedSlots = !_showPassedSlots;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _showPassedSlots ? const Color(0xFFE5E7EB) : const Color(0xFFE5F5EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _showPassedSlots ? 'Hide Passed' : 'View Passed ($passedSlotsCount)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _showPassedSlots ? const Color(0xFF374151) : const Color(0xFF154D36),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
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
      mainAxisSize: MainAxisSize.min,
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
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.8,
          ),
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
                final isPast = slot['status'] == 'passed' || slot['isPast'] == true;
                final isSelected = _selectedTimeSlots.contains(slot['time']);

                final offer = slot['offer'] is Map
                    ? slot['offer'] as Map
                    : null;
                final offerTag = slot['offerTag']?.toString() ?? '';
                final hasOffer = offer != null || offerTag.isNotEmpty;
                final origPrice =
                    (slot['originalPrice'] ?? slot['price'] ?? 1000);
                final currentPrice = (slot['price'] ?? 1000);
                final bool hasPriceDiscount =
                    hasOffer && origPrice != currentPrice;

                String badgeText = '';
                if (offer != null) {
                  if (offer['tagLabel'] != null &&
                      offer['tagLabel'].toString().isNotEmpty) {
                    badgeText = offer['tagLabel'].toString();
                  } else if (offer['discountPercent'] != null &&
                      (offer['discountPercent'] as num) > 0) {
                    badgeText = '${offer['discountPercent']}% OFF';
                  }
                } else if (offerTag.startsWith('PERCENT|')) {
                  final p = offerTag.split('|');
                  badgeText = p.length > 2 && p[2].isNotEmpty
                      ? p[2]
                      : '${p[1]}% OFF';
                } else if (offerTag.startsWith('PRICE|')) {
                  badgeText = 'Special Price';
                }

                Color bgColor = const Color(0xFFF3F5F1);
                Color textColor = const Color(0xFF111827);
                Color borderColor = Colors.transparent;

                if (isPast) {
                  bgColor = const Color(0xFFF3F4F6);
                  textColor = const Color(0xFF9CA3AF);
                  borderColor = const Color(0xFFE5E7EB);
                } else if (isBooked) {
                  bgColor = const Color(0xFFFEE2E2);
                  textColor = const Color(0xFFDC2626);
                } else if (isBlocked) {
                  bgColor = Colors.amber.shade50;
                  textColor = Colors.amber.shade900;
                  borderColor = Colors.amber.shade300;
                } else if (isSelected) {
                  bgColor = const Color(0xFF154D36);
                  textColor = Colors.white;
                  borderColor = const Color(0xFF154D36);
                } else if (hasOffer) {
                  bgColor = const Color(0xFFF0FDF4);
                  borderColor = const Color(0xFF15803D).withValues(alpha: 0.35);
                }

                return SizedBox(
                  width: itemWidth,
                  child: GestureDetector(
                    onTap: isPast
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Slot ${slot['time']} has already passed for today.',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        : (isBooked || isBlocked)
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isBooked
                                          ? 'Slot is already booked.'
                                          : 'Slot is blocked for maintenance.',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            : () {
                                setState(() {
                                  if (_selectedTimeSlots.contains(slot['time'])) {
                                    _selectedTimeSlots.remove(slot['time']);
                                  } else {
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slot['time'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9.0,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (isPast) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Passed',
                                style: TextStyle(
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ] else if (isBooked || isBlocked) ...[
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
                                    decorationColor: isSelected
                                        ? Colors.white70
                                        : const Color(0xFF9CA3AF),
                                    color: isSelected
                                        ? Colors.white70
                                        : const Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '₹$currentPrice',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF154D36),
                                  ),
                                ),
                              ],
                            ),
                            if (badgeText.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF15803D),
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
                                    color: isSelected
                                        ? Colors.white70
                                        : const Color(0xFF154D36),
                                  ),
                                  const SizedBox(width: 2),
                                ],
                                Text(
                                  '₹${slot['price'] ?? 1000}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF154D36),
                                  ),
                                ),
                              ],
                            ),
                            if (badgeText.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF15803D),
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
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 16,
                  ),
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
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isOpenForChallenge,
                  activeThumbColor: const Color(0xFFBE123C),
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
                  hintText: 'Enter Team Name (e.g. Eagles FC)',
                  prefixIcon: const Icon(Icons.shield_outlined, size: 18),
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _teamSizeController,
                decoration: InputDecoration(
                  hintText: 'Enter Team Size / Format (e.g. 7v7, 5v5)',
                  prefixIcon: const Icon(Icons.groups_outlined, size: 18),
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
    final rawPrice = _getSportHourlyRate(_selectedSport).toInt();
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
    // Zero convenience fee and zero taxes for players - only cost of the hours!
    final total = courtFee;

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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Selected Date',
              _dates[_selectedDateIndex]['fullDate']!,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow('Selected Sport', _selectedSport),
            const SizedBox(height: 8),
            _buildSummaryRow('Playing Court', _selectedCourt ?? '${widget.turfName} Main Arena'),
            const SizedBox(height: 8),
            _buildSummaryRow('Slots Count', '$slotCount slot(s) • $slotCount hr(s)'),
            if (_selectedTimeSlots.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Selected Slots',
                (_selectedTimeSlots.toList()..sort((a, b) => AppConstants.parseSlotStartMinutes(a).compareTo(AppConstants.parseSlotStartMinutes(b)))).join(', '),
              ),
            ],
            const SizedBox(height: 8),
            _buildSummaryRow('Court Fee (Hourly Rate)', '₹$courtFee'),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Convenience & Tax Fee',
              '₹0 (Free • No Extra Taxes)',
              valueColor: const Color(0xFF154D36),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Payable',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  '₹$total',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF154D36),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCautionNotice() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cancellation Policy Notice',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Free cancellation is allowed only up to 3 hours before the slot start time.\n• Slots booked within 3 hours are locked and cannot be cancelled.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF78350F),
                      height: 1.4,
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

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: valueColor ?? const Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final courtFee = _calculateCourtFee();
    final total = courtFee; // Only the cost of the hours! No added fees or taxes
    final hasSlots = _selectedTimeSlots.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hasSlots ? '₹$total' : '₹0',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Text(
                    hasSlots
                        ? '${_selectedTimeSlots.length} slot(s) • ${_selectedCourt ?? "Court"}'
                        : 'Select a slot to proceed',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: hasSlots ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
            onPressed: _isBookingInProgress
                ? null
                : () async {
                    if (_selectedTimeSlots.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select at least one available slot.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (_isOpenForChallenge) {
                      if (_teamNameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter your team name for open challenge.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (_teamSizeController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter team size (e.g. 7v7, 5v5) for open challenge.',
                            ),
                          ),
                        );
                        return;
                      }
                    }

                    final sortedSlots = _selectedTimeSlots.toList()
                      ..sort((a, b) => AppConstants.parseSlotStartMinutes(a)
                          .compareTo(AppConstants.parseSlotStartMinutes(b)));
                    final combinedSlot = sortedSlots.join(', ');
                    final selectedDate =
                        _dates[_selectedDateIndex]['fullDate']!;

                    setState(() => _isBookingInProgress = true);
                    try {
                      final effectiveTurfId = await _getEffectiveTurfId();
                      if (effectiveTurfId != null) {
                        final prefs = await SharedPreferences.getInstance();
                        String customerName =
                            (prefs.getString('fullName') ?? '').trim();
                        String customerPhone =
                            (prefs.getString('mobileNumber') ?? '').trim();

                        if (customerName.isEmpty) {
                          customerName = 'Guest Player';
                        }
                        if (customerPhone.isEmpty) {
                          customerPhone = '';
                        }

                        final tName = _teamNameController.text.trim().isNotEmpty
                            ? _teamNameController.text.trim()
                            : customerName;
                        final tSize = _teamSizeController.text.trim().isNotEmpty
                            ? _teamSizeController.text.trim()
                            : 'Open Squad';

                        final res = await http.post(
                          Uri.parse(
                            '${ApiConfig.baseUrl}/turfs/$effectiveTurfId/book',
                          ),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'customerName': customerName,
                            'customerPhone': customerPhone,
                            'sport': _selectedSport,
                            'courtName': _selectedCourt ?? '${widget.turfName} Main Arena',
                            'date': selectedDate,
                            'timeSlot': combinedSlot,
                            'timeSlots': sortedSlots,
                            'amount': courtFee.toDouble(),
                            'paymentMethod': 'UPI (GPay)',
                            'isOpenMatch': _isOpenForChallenge,
                            'teamName': _isOpenForChallenge ? tName : null,
                            'teamSize': _isOpenForChallenge ? tSize : null,
                          }),
                        );

                        if (res.statusCode == 200 || res.statusCode == 201) {
                          Map<String, dynamic> bookingObj = {};
                          try {
                            final resData = jsonDecode(res.body);
                            final Map<String, dynamic> rawMap = resData is Map<String, dynamic>
                                ? resData
                                : (resData is Map ? Map<String, dynamic>.from(resData) : {});
                            bookingObj = (rawMap['booking'] is Map)
                                ? Map<String, dynamic>.from(rawMap['booking'])
                                : Map<String, dynamic>.from(rawMap);

                            final targetTurfId = bookingObj['turfId'] ??
                                bookingObj['verifiedAdminId'] ??
                                _resolvedTurfId ??
                                widget.turfId ??
                                1;

                            bookingObj['turfId'] = targetTurfId;
                            bookingObj['verifiedAdminId'] = targetTurfId;
                            bookingObj['turfName'] = widget.turfName;
                            bookingObj['imageUrl'] = widget.imageUrl;
                            bookingObj['location'] = widget.location;
                            bookingObj['courtName'] = _selectedCourt ?? '${widget.turfName} Main Arena';
                            bookingObj['isActive'] = true;
                            bookingObj['isOpenMatch'] = _isOpenForChallenge;
                            bookingObj['customerName'] = customerName;
                            bookingObj['customerPhone'] = customerPhone;
                            bookingObj['sport'] = _selectedSport;
                            bookingObj['amount'] = courtFee.toDouble();
                            bookingObj['paymentMethod'] = 'UPI (GPay)';

                            if (bookingObj['date'] == null) {
                              bookingObj['date'] = selectedDate;
                            }
                            if (bookingObj['timeSlot'] == null) {
                              bookingObj['timeSlot'] = combinedSlot;
                            }
                            if (bookingObj['status'] == null) {
                              bookingObj['status'] = 'Confirmed';
                            }
                            if (bookingObj['bookingCode'] == null && bookingObj['id'] != null) {
                              bookingObj['bookingCode'] =
                                  'G24-BK-${bookingObj['id'].toString().padLeft(4, '0')}';
                            }
                            if (bookingObj['bookingId'] == null) {
                              bookingObj['bookingId'] =
                                  bookingObj['bookingCode'] ?? 'G24-BK-0001';
                            }

                            BookingManager().addBooking(bookingObj);
                          } catch (e) {
                            debugPrint('Error caching booking locally: $e');
                          }
                          BookingManager().fetchBookings();

                          if (_isOpenForChallenge) {
                            final initials = tName.length >= 2
                                ? tName.substring(0, 2).toUpperCase()
                                : 'TC';

                            ChallengeManager().addChallenge(
                              Challenge(
                                id: 'ch_${DateTime.now().millisecondsSinceEpoch}',
                                turfName: widget.turfName,
                                location: widget.location,
                                date: selectedDate,
                                time: combinedSlot,
                                sport: _selectedSport,
                                challengerName: tName,
                                challengerTeamInitials: initials,
                                challengerColor: const Color(0xFF154D36),
                                creatorPhone: customerPhone,
                                teamSize: tSize,
                                isCreator: true,
                                joinRequests: [],
                              ),
                            );
                          }

                          if (mounted) {
                            _selectedTimeSlots.clear();
                            _loadSlots();
                            BookingQrPassModal.show(context, bookingObj);
                            return;
                          }
                        } else {
                          final json = jsonDecode(res.body);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  json['message'] ??
                                      'Booking failed. Slot may already be booked.',
                                ),
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
              backgroundColor: const Color(0xFF154D36),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isBookingInProgress
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hasSlots ? 'Confirm Slot' : 'Select Slot',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
          ),
        ),
      ),
          ],
        ),
      ),
    );
  }
}
