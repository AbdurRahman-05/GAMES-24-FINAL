import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../providers/admin_providers.dart';

class AdminSlotManagerScreen extends ConsumerStatefulWidget {
  const AdminSlotManagerScreen({super.key});

  @override
  ConsumerState<AdminSlotManagerScreen> createState() => _AdminSlotManagerScreenState();
}

class _AdminSlotManagerScreenState extends ConsumerState<AdminSlotManagerScreen> {
  String? _selectedCourt;
  DateTime _selectedDate = DateTime.now();
  String _selectedSlotFilter = 'All'; // 'All', 'Available', 'Booked', 'Blocked', 'Offers', 'Passed'
  bool _isRefreshing = false;

  final List<String> _weekdays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late final TextEditingController _discountPercentController;
  late final TextEditingController _offerLabelController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _discountedPriceController;

  static const List<String> _scheduleTimeOptions = [
    '04:00 AM', '05:00 AM', '06:00 AM', '07:00 AM', '08:00 AM', '09:00 AM',
    '10:00 AM', '11:00 AM', '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM',
    '04:00 PM', '05:00 PM', '06:00 PM', '07:00 PM', '08:00 PM', '09:00 PM',
    '10:00 PM', '11:00 PM', '12:00 AM',
  ];

  @override
  void initState() {
    super.initState();
    _discountPercentController = TextEditingController(text: '20');
    _offerLabelController = TextEditingController(text: 'Happy Hour');
    _originalPriceController = TextEditingController(text: '1000');
    _discountedPriceController = TextEditingController(text: '800');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRealtimeSlots();
    });
  }

  @override
  void dispose() {
    _discountPercentController.dispose();
    _offerLabelController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    super.dispose();
  }

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadRealtimeSlots() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final profile = ref.read(turfProfileProvider);
      final adminId = profile.verifiedAdminId ?? profile.adminUserId ?? 1;
      await ref.read(adminSlotProvider.notifier).fetchSlotsForDate(adminId, _getDateKey(_selectedDate));
      if (profile.ownerPhone.isNotEmpty) {
        await ref.read(turfProfileProvider.notifier).fetchVerifiedAdminByPhone(profile.ownerPhone);
      }
    } catch (e) {
      debugPrint("Error loading realtime slots: $e");
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  TurfBookingHistoryItem? _findBookingForSlot(String slot, DateTime date) {
    final dateKey = _getDateKey(date);
    final profile = ref.read(turfProfileProvider);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final normSlot = slot.replaceAll(RegExp(r'\s*-\s*'), '-').replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

    for (final b in profile.bookingHistory) {
      if (b.isCancelled) continue;
      final d = b.effectiveDate.trim();
      final isMatchingDate = d == dateKey || (isToday && (d.toLowerCase() == 'today' || d.isEmpty));
      if (isMatchingDate) {
        final bSlots = b.effectiveTimeSlot.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty);
        for (final bs in bSlots) {
          final normBs = bs.replaceAll(RegExp(r'\s*-\s*'), '-').replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
          if (normBs == normSlot || normBs.contains(normSlot) || normSlot.contains(normBs)) {
            return b;
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(turfProfileProvider);
    final adminSlotState = ref.watch(adminSlotProvider);
    final dateKey = _getDateKey(_selectedDate);

    final allSlotsForDate = adminSlotState.getAvailableSlotsForDate(_selectedDate);
    final totalSlotsCount = allSlotsForDate.length;

    final blockedSet = adminSlotState.getBlockedSlotsForDate(dateKey);
    final remoteBooked = adminSlotState.getBookedSlotsForDate(dateKey);
    final historyBooked = <String>{};
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    for (final b in profile.bookingHistory) {
      if (b.isCancelled) continue;
      final d = b.effectiveDate.trim();
      final isMatchingDate = d == dateKey || (isToday && (d.toLowerCase() == 'today' || d.isEmpty));
      if (isMatchingDate) {
        final bSlots = b.effectiveTimeSlot.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty);
        for (final bs in bSlots) {
          final normBs = bs.replaceAll(RegExp(r'\s*-\s*'), '-').replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
          for (final actualSlot in allSlotsForDate) {
            final normActual = actualSlot.replaceAll(RegExp(r'\s*-\s*'), '-').replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
            if (normActual == normBs || normActual.contains(normBs) || normBs.contains(normActual)) {
              historyBooked.add(actualSlot);
            }
          }
          historyBooked.add(bs);
        }
      }
    }
    final bookedSet = {...remoteBooked, ...historyBooked};
    final offerMap = adminSlotState.getDiscountedSlotsForDate(dateKey);

    // Compute classification for every slot on the selected date:
    // 1. Booked: any slot reserved on this date (takes priority so owner sees true booked count)
    // 2. Blocked: owner maintenance hold
    // 3. Passed: unbooked slot whose time has expired
    // 4. Available: actionable upcoming bookable slot
    int passedCount = 0;
    int bookedCount = 0;
    int blockedCount = 0;
    int offerCount = 0;
    int availableCount = 0;

    for (final slot in allSlotsForDate) {
      final isPast = AppConstants.isSlotPast(slot, _selectedDate);
      final isBooked = bookedSet.contains(slot);
      final isBlocked = blockedSet.contains(slot);
      final hasOffer = offerMap.containsKey(slot);

      if (isBooked) {
        bookedCount++;
      } else if (isBlocked) {
        blockedCount++;
      } else if (isPast) {
        passedCount++;
      } else {
        availableCount++;
        if (hasOffer) offerCount++;
      }
    }

    // Filter slots based on active tab
    final filteredSlots = allSlotsForDate.where((slot) {
      final isPast = AppConstants.isSlotPast(slot, _selectedDate);
      final isBooked = bookedSet.contains(slot);
      final isBlocked = blockedSet.contains(slot);
      final hasOffer = offerMap.containsKey(slot);

      if (_selectedSlotFilter == 'Available') {
        return !isPast && !isBooked && !isBlocked;
      } else if (_selectedSlotFilter == 'Booked') {
        return isBooked;
      } else if (_selectedSlotFilter == 'Blocked') {
        return isBlocked;
      } else if (_selectedSlotFilter == 'Offers') {
        return hasOffer && !isPast && !isBooked;
      } else if (_selectedSlotFilter == 'Passed') {
        return isPast && !isBooked;
      }
      return true; // 'All'
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildProAppBar(context, profile),
      body: RefreshIndicator(
        onRefresh: _loadRealtimeSlots,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Operating Schedule & Live KPI Bento Card
              _buildHeroScheduleCard(
                context,
                profile,
                adminSlotState,
                totalSlots: totalSlotsCount,
                availableCount: availableCount,
                bookedCount: bookedCount,
                blockedCount: blockedCount,
                offerCount: offerCount,
                passedCount: passedCount,
              ),
              const SizedBox(height: 18),

              // 2. Interactive Court & Arena Segmented Bar
              _buildCourtSelectorSection(profile),
              const SizedBox(height: 18),

              // 3. Calendar Date Strip (Today, Tomorrow + 7 Days + Custom Picker)
              _buildDateSelectorStrip(theme),
              const SizedBox(height: 18),

              // 4. Filter Pills & Batch Operational Quick Actions
              _buildFilterPillsSection(
                totalCount: totalSlotsCount,
                availableCount: availableCount,
                bookedCount: bookedCount,
                blockedCount: blockedCount,
                offerCount: offerCount,
                passedCount: passedCount,
              ),
              const SizedBox(height: 14),

              // 5. Section Header & Quick Status Guide
              _buildSlotsHeaderGuide(allSlotsForDate.length, filteredSlots.length),
              const SizedBox(height: 12),

              // 6. Responsive 2-Column Slots Bento Grid
              if (filteredSlots.isNotEmpty)
                _buildSlotsGrid(
                  context,
                  filteredSlots: filteredSlots,
                  dateKey: dateKey,
                  blockedSet: blockedSet,
                  bookedSet: bookedSet,
                  offerMap: offerMap,
                )
              else
                _buildEmptySlotsState(),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. PRO APP BAR ---
  PreferredSizeWidget _buildProAppBar(BuildContext context, TurfProfileState profile) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF1E293B)),
        ),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Slots & Pricing Engine',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 1),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                profile.venueName.isNotEmpty ? '${profile.venueName} • Live Controls' : 'Live Operating Control',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Sync Realtime Slots',
          onPressed: _loadRealtimeSlots,
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF154D36)),
                  )
                : const Icon(Icons.sync_rounded, size: 18, color: Color(0xFF154D36)),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // --- 2. HERO OPERATING SCHEDULE CARD & LIVE STATS ---
  Widget _buildHeroScheduleCard(
    BuildContext context,
    TurfProfileState profile,
    AdminSlotState adminSlotState, {
    required int totalSlots,
    required int availableCount,
    required int bookedCount,
    required int blockedCount,
    required int offerCount,
    required int passedCount,
  }) {
    final opening = adminSlotState.weekdayOpeningTime.isNotEmpty ? adminSlotState.weekdayOpeningTime : profile.weekdayOpeningTime;
    final closing = adminSlotState.weekdayClosingTime.isNotEmpty ? adminSlotState.weekdayClosingTime : profile.weekdayClosingTime;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C2B1E), Color(0xFF154D36)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF154D36).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.schedule_rounded, color: Color(0xFFFBBF24), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Operating Schedule',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _openEditScheduleDialog(context, opening, closing),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Edit Hours',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            opening == '24 Hours' ? 'Open 24 Hours (All Day)' : '$opening – $closing',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Auto-divided into $totalSlots hourly bookable slots • Synced with Player App',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // Mini Metric Counter Bar inside Hero Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeroMiniStat('Available', '$availableCount', const Color(0xFF4ADE80)),
                _buildStatDivider(),
                _buildHeroMiniStat('Booked', '$bookedCount', const Color(0xFFF87171)),
                _buildStatDivider(),
                _buildHeroMiniStat('Blocked', '$blockedCount', const Color(0xFFFBBF24)),
                _buildStatDivider(),
                _buildHeroMiniStat('Deals', '$offerCount', const Color(0xFF38BDF8)),
                _buildStatDivider(),
                _buildHeroMiniStat('Passed', '$passedCount', const Color(0xFF94A3B8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMiniStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  // --- 3. COURT & ARENA HORIZONTAL SELECTOR ---
  Widget _buildCourtSelectorSection(TurfProfileState profile) {
    final courts = profile.courts;
    final courtNames = courts.map((c) => c.name).toList();
    if (courtNames.isEmpty) courtNames.add('Main Arena');

    if (_selectedCourt == null || !courtNames.contains(_selectedCourt)) {
      _selectedCourt = courtNames.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Court / Arena',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${courts.length} Arenas Active',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: courts.isNotEmpty ? courts.length : 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final court = courts.isNotEmpty
                  ? courts[index]
                  : TurfCourtVenueItem(
                      id: 'CR-01',
                      name: 'Main Turf Arena A',
                      sport: 'Football',
                      surface: 'Synthetic Turf',
                      hourlyRate: 1200,
                      timings: '05:00 AM - 11:00 PM',
                    );

              final isSelected = _selectedCourt == court.name;
              final sportEmoji = _getSportEmoji(court.sport);

              return InkWell(
                onTap: () => setState(() => _selectedCourt = court.name),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF154D36) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF154D36) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF154D36).withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(sportEmoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            court.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '₹${court.hourlyRate.toInt()}/hr • ${court.sport}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
                            ),
                          ),
                        ],
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

  // --- 4. DATE SELECTOR STRIP WITH QUICK CHIPS ---
  Widget _buildDateSelectorStrip(ThemeData theme) {
    final now = DateTime.now();
    final isSelectedToday = DateUtils.isSameDay(_selectedDate, now);
    final tomorrow = now.add(const Duration(days: 1));
    final isSelectedTomorrow = DateUtils.isSameDay(_selectedDate, tomorrow);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_rounded, size: 16, color: Color(0xFF154D36)),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Select Custom Date',
                icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF154D36), size: 20),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            onSurface: Color(0xFF0F172A),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    _loadRealtimeSlots();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Preset Date Pills
          Row(
            children: [
              _buildQuickDatePresetPill(
                label: 'Today',
                isSelected: isSelectedToday,
                onTap: () {
                  setState(() => _selectedDate = now);
                  _loadRealtimeSlots();
                },
              ),
              const SizedBox(width: 6),
              _buildQuickDatePresetPill(
                label: 'Tomorrow',
                isSelected: isSelectedTomorrow,
                onTap: () {
                  setState(() => _selectedDate = tomorrow);
                  _loadRealtimeSlots();
                },
              ),
              const SizedBox(width: 6),
              _buildQuickDatePresetPill(
                label: 'This Weekend',
                isSelected: _selectedDate.weekday == DateTime.saturday || _selectedDate.weekday == DateTime.sunday,
                onTap: () {
                  final daysUntilSat = (DateTime.saturday - now.weekday + 7) % 7;
                  final nextSat = now.add(Duration(days: daysUntilSat == 0 ? 7 : daysUntilSat));
                  setState(() => _selectedDate = nextSat);
                  _loadRealtimeSlots();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 10-Day Horizontal Date Capsule Strip
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 10,
              itemBuilder: (context, index) {
                final date = now.add(Duration(days: index));
                final isSelected = DateUtils.isSameDay(date, _selectedDate);
                final weekday = _weekdays[date.weekday - 1];
                final dayNum = date.day.toString();

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    _loadRealtimeSlots();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF154D36) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF154D36) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF154D36).withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekday,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dayNum,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : const Color(0xFF0F172A),
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
      ),
    );
  }

  Widget _buildQuickDatePresetPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF154D36).withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF154D36) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? const Color(0xFF154D36) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // --- 5. FILTER PILLS & ACTION BUTTONS ---
  Widget _buildFilterPillsSection({
    required int totalCount,
    required int availableCount,
    required int bookedCount,
    required int blockedCount,
    required int offerCount,
    required int passedCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterPill('All', totalCount, const Color(0xFF154D36)),
          const SizedBox(width: 8),
          _buildFilterPill('Available', availableCount, const Color(0xFF16A34A)),
          const SizedBox(width: 8),
          _buildFilterPill('Booked', bookedCount, const Color(0xFFDC2626)),
          const SizedBox(width: 8),
          _buildFilterPill('Blocked', blockedCount, const Color(0xFFEA580C)),
          const SizedBox(width: 8),
          _buildFilterPill('Offers', offerCount, const Color(0xFF0284C7)),
          const SizedBox(width: 8),
          _buildFilterPill('Passed', passedCount, const Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String title, int count, Color color) {
    final isSelected = _selectedSlotFilter == title;
    return InkWell(
      onTap: () => setState(() => _selectedSlotFilter = title),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsHeaderGuide(int total, int displayed) {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Slots Roster',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($displayed/$total)',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const Spacer(),
        const Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.touch_app_rounded, size: 12, color: Color(0xFF64748B)),
              SizedBox(width: 3),
              Flexible(
                child: Text(
                  'Tap to Block • Hold for Offer',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 6. 2-COLUMN SLOTS BENTO GRID ---
  Widget _buildSlotsGrid(
    BuildContext context, {
    required List<String> filteredSlots,
    required String dateKey,
    required Set<String> blockedSet,
    required Set<String> bookedSet,
    required Map<String, String> offerMap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: filteredSlots.map((slot) {
            final isBlocked = blockedSet.contains(slot);
            final isBooked = bookedSet.contains(slot);
            final isPast = AppConstants.isSlotPast(slot, _selectedDate);
            final offerTag = offerMap[slot];
            final matchingBooking = isBooked ? _findBookingForSlot(slot, _selectedDate) : null;

            return SizedBox(
              width: cardWidth,
              child: _buildSlotItemCard(
                context,
                slot: slot,
                dateKey: dateKey,
                isBlocked: isBlocked,
                isBooked: isBooked,
                isPast: isPast,
                offerTag: offerTag,
                booking: matchingBooking,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSlotItemCard(
    BuildContext context, {
    required String slot,
    required String dateKey,
    required bool isBlocked,
    required bool isBooked,
    required bool isPast,
    required String? offerTag,
    required TurfBookingHistoryItem? booking,
  }) {
    // Dynamic styling based on status
    Color cardBg;
    Color borderColor;
    Color titleColor;
    Color statusBadgeBg;
    Color statusBadgeText;
    String statusTitle;
    IconData statusIcon;

    if (isBooked) {
      if (isPast) {
        cardBg = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFCBD5E1);
        titleColor = const Color(0xFF1E293B);
        statusBadgeBg = const Color(0xFFE2E8F0);
        statusBadgeText = const Color(0xFF334155);
        statusTitle = booking != null ? '${booking.customerName} • Done' : 'Booked • Completed';
        statusIcon = Icons.task_alt_rounded;
      } else {
        cardBg = const Color(0xFFFFF1F2);
        borderColor = const Color(0xFFFECDD3);
        titleColor = const Color(0xFF9F1239);
        statusBadgeBg = const Color(0xFFFFE4E6);
        statusBadgeText = const Color(0xFFE11D48);
        statusTitle = booking != null ? booking.customerName : 'Booked Online';
        statusIcon = Icons.confirmation_number_rounded;
      }
    } else if (isPast) {
      cardBg = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFE2E8F0);
      titleColor = const Color(0xFF94A3B8);
      statusBadgeBg = const Color(0xFFF1F5F9);
      statusBadgeText = const Color(0xFF64748B);
      statusTitle = 'Time Passed';
      statusIcon = Icons.history_rounded;
    } else if (isBlocked) {
      cardBg = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      titleColor = const Color(0xFF92400E);
      statusBadgeBg = const Color(0xFFFEF3C7);
      statusBadgeText = const Color(0xFFD97706);
      statusTitle = 'Blocked / Maint.';
      statusIcon = Icons.lock_clock_rounded;
    } else if (offerTag != null && offerTag.isNotEmpty) {
      cardBg = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      titleColor = const Color(0xFF14532D);
      statusBadgeBg = const Color(0xFFDCFCE7);
      statusBadgeText = const Color(0xFF15803D);
      statusTitle = 'Special Offer';
      statusIcon = Icons.local_offer_rounded;
    } else {
      cardBg = Colors.white;
      borderColor = const Color(0xFFE2E8F0);
      titleColor = const Color(0xFF0F172A);
      statusBadgeBg = const Color(0xFFDCFCE7);
      statusBadgeText = const Color(0xFF15803D);
      statusTitle = 'Available';
      statusIcon = Icons.check_circle_rounded;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: isBooked
          ? () {
              if (booking != null) {
                _openBookingDetailsSheet(context, booking, slot);
              } else {
                ToastUtils.showInfo(context, "Slot $slot is reserved.");
              }
            }
          : isPast
              ? () {
                  ToastUtils.showWarning(context, "Slot $slot has already passed for today.");
                }
              : () async {
                  final profile = ref.read(turfProfileProvider);
                  final adminId = profile.verifiedAdminId ?? profile.adminUserId ?? 1;
                  final success = await ref.read(adminSlotProvider.notifier).toggleBlockSlotRealtime(adminId, slot, dateKey);
                  if (context.mounted) {
                    if (success) {
                      ToastUtils.showSuccess(
                        context,
                        isBlocked ? 'Slot $slot unblocked and ready for bookings!' : 'Slot $slot blocked for maintenance.',
                      );
                    } else {
                      ToastUtils.showError(context, "Cannot toggle slot $slot (already reserved).");
                    }
                  }
                },
      onLongPress: (isBooked || isPast) ? null : () => _showOfferActions(slot, offerTag),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: (isBlocked || offerTag != null || isBooked) ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Time Slot & Quick Action Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isPast && !isBooked)
                  GestureDetector(
                    onTap: () => _showOfferActions(slot, offerTag),
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        color: offerTag != null ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        offerTag != null ? Icons.discount_rounded : Icons.more_horiz_rounded,
                        size: 13,
                        color: offerTag != null ? const Color(0xFF15803D) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Offer Content or Status Chip
            if (offerTag != null && !isPast)
              _buildOfferContent(offerTag, statusBadgeText)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBadgeBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 10.5, color: statusBadgeText),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        statusTitle,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: statusBadgeText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 6),
            // Subtitle Guidance Hint
            Text(
              isBooked
                  ? (booking != null ? '₹${booking.amount.toInt()} • Tap for details' : 'Reserved • Tap details')
                  : isPast
                      ? 'Expired time'
                      : isBlocked
                          ? 'Tap to unblock'
                          : 'Tap to block',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: (isPast && !isBooked) ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferContent(String offerText, Color textColor) {
    if (offerText.startsWith('PERCENT|')) {
      final parts = offerText.split('|');
      final percent = parts[1];
      final label = parts.length > 2 ? parts[2] : '';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 11, color: Color(0xFF15803D)),
            const SizedBox(width: 3),
            Text(
              '$percent% OFF ${label.isNotEmpty ? "• $label" : ""}',
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else if (offerText.startsWith('PRICE|')) {
      final parts = offerText.split('|');
      final original = parts[1];
      final discounted = parts[2];
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹$original',
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                fontSize: 9,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '₹$discounted',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF15803D),
              ),
            ),
          ],
        ),
      );
    } else {
      return Text(
        offerText,
        style: TextStyle(fontSize: 9.5, color: textColor, fontWeight: FontWeight.w800),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget _buildEmptySlotsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_busy_rounded, size: 28, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Text(
            'No slots match "$_selectedSlotFilter"',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try selecting "All" or a different date to view scheduled slots.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- 7. BOOKING DETAILS QUICK SHEET ---
  void _openBookingDetailsSheet(BuildContext context, TurfBookingHistoryItem booking, String slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.confirmation_number_rounded, color: Color(0xFF15803D), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.id,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              '${booking.sport} • ${booking.courtName}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${booking.amount.toInt()} PAID',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildBookingDetailRow('Customer Name', booking.customerName, Icons.person_rounded),
                      const Divider(height: 16),
                      _buildBookingDetailRow('Phone Number', booking.customerPhone, Icons.phone_rounded),
                      const Divider(height: 16),
                      _buildBookingDetailRow('Reserved Slot', slot, Icons.access_time_rounded),
                      const Divider(height: 16),
                      _buildBookingDetailRow('Payment Mode', booking.paymentMethod, Icons.payment_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF154D36),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingDetailRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
      ],
    );
  }

  // --- 8. PRO OFFER ACTIONS SHEET ---
  void _showOfferActions(String slot, String? currentOffer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manage Slot Deal',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            slot,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Color(0xFF15803D), size: 18),
                  ),
                  title: const Text('Apply 20% Happy Hour Tag', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: const Text('Quick preset: 20% OFF Happy Hour deal tag', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    final dateKey = _getDateKey(_selectedDate);
                    final profile = ref.read(turfProfileProvider);
                    final adminId = profile.verifiedAdminId ?? profile.adminUserId ?? 1;
                    ref.read(adminSlotProvider.notifier).toggleSlotOfferRealtime(adminId, slot, 'PERCENT|20|Happy Hour', dateKey);
                    Navigator.pop(context);
                    ToastUtils.showSuccess(context, "Applied 20% Happy Hour deal tag to $slot.");
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 18),
                  ),
                  title: const Text('Configure Custom Offer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: const Text('Set custom percentage discount or fixed price cut', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    _showCustomOfferConfiguratorSheet(slot);
                  },
                ),
                if (currentOffer != null && currentOffer.isNotEmpty)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFDC2626), size: 18),
                    ),
                    title: const Text('Remove Offer Tag', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFDC2626))),
                    subtitle: const Text('Reset slot to normal turf rate', style: TextStyle(fontSize: 11)),
                    onTap: () {
                      final dateKey = _getDateKey(_selectedDate);
                      final profile = ref.read(turfProfileProvider);
                      final adminId = profile.verifiedAdminId ?? profile.adminUserId ?? 1;
                      ref.read(adminSlotProvider.notifier).toggleSlotOfferRealtime(adminId, slot, '', dateKey);
                      Navigator.pop(context);
                      ToastUtils.showSuccess(context, "Offer deal removed from $slot.");
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 9. CUSTOM OFFER CONFIGURATOR SHEET ---
  void _showCustomOfferConfiguratorSheet(String slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String sheetOfferType = 'percent';
        final TextEditingController sheetPercentController = TextEditingController(text: _discountPercentController.text);
        final TextEditingController sheetLabelController = TextEditingController(text: _offerLabelController.text);
        final TextEditingController sheetOriginalPriceController = TextEditingController(text: _originalPriceController.text);
        final TextEditingController sheetDiscountedPriceController = TextEditingController(text: _discountedPriceController.text);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            String buildOfferString() {
              if (sheetOfferType == 'percent') {
                final percentStr = sheetPercentController.text.trim();
                final label = sheetLabelController.text.trim();
                return 'PERCENT|${percentStr.isEmpty ? "0" : percentStr}|$label';
              } else {
                final origStr = sheetOriginalPriceController.text.trim();
                final discStr = sheetDiscountedPriceController.text.trim();
                return 'PRICE|${origStr.isEmpty ? "0" : origStr}|${discStr.isEmpty ? "0" : discStr}';
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Configure Deal - $slot',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Toggle Tabs: Percentage vs Price Cut
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => sheetOfferType = 'percent'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: sheetOfferType == 'percent' ? const Color(0xFF154D36) : const Color(0xFFF1F5F9),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Percentage (%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: sheetOfferType == 'percent' ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => sheetOfferType = 'price'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: sheetOfferType == 'price' ? const Color(0xFF154D36) : const Color(0xFFF1F5F9),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Price Cut (₹)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: sheetOfferType == 'price' ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (sheetOfferType == 'percent') ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: sheetPercentController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Discount %',
                                prefixIcon: Icon(Icons.percent_rounded, size: 18),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              controller: sheetLabelController,
                              decoration: const InputDecoration(
                                labelText: 'Tag Label',
                                prefixIcon: Icon(Icons.label_outline_rounded, size: 18),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Preset discount pills
                      Wrap(
                        spacing: 6,
                        children: ['10', '15', '20', '25', '30', '50'].map((pct) {
                          return ActionChip(
                            label: Text('$pct%'),
                            labelStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              sheetPercentController.text = pct;
                              setSheetState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: sheetOriginalPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Base Price (₹)',
                                prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: sheetDiscountedPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Offer Price (₹)',
                                prefixIcon: Icon(Icons.local_offer_rounded, size: 18),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 18),
                    // Live Card Preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Player App Preview:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          _buildOfferContent(buildOfferString(), const Color(0xFF15803D)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF154D36),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final newOffer = buildOfferString();
                          final dateKey = _getDateKey(_selectedDate);
                          final profile = ref.read(turfProfileProvider);
                          final adminId = profile.verifiedAdminId ?? profile.adminUserId ?? 1;
                          ref.read(adminSlotProvider.notifier).toggleSlotOfferRealtime(adminId, slot, newOffer, dateKey);
                          Navigator.pop(context);
                          ToastUtils.showSuccess(context, "Applied custom deal tag to $slot!");
                        },
                        child: const Text('Apply Deal Tag', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 10. EDIT OPERATING SCHEDULE MODAL ---
  void _openEditScheduleDialog(BuildContext context, String currentOpening, String currentClosing) {
    String selectedStart = _scheduleTimeOptions.contains(currentOpening) ? currentOpening : '05:00 AM';
    String selectedEnd = _scheduleTimeOptions.contains(currentClosing) ? currentClosing : '11:00 PM';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setSheetState) {
            final generatedSlots = AppConstants.generateTimeSlots(selectedStart, selectedEnd);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF154D36).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.schedule_rounded, color: Color(0xFF154D36), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Operating Hours',
                              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Auto-splits into 1-hour slots & syncs across platforms',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      // Starting Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Opening Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                color: const Color(0xFFF8FAFC),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedStart,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF154D36)),
                                  items: _scheduleTimeOptions.map((time) {
                                    return DropdownMenuItem<String>(
                                      value: time,
                                      child: Text(time, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setSheetState(() => selectedStart = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Ending Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Closing Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                color: const Color(0xFFF8FAFC),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedEnd,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF154D36)),
                                  items: _scheduleTimeOptions.map((time) {
                                    return DropdownMenuItem<String>(
                                      value: time,
                                      child: Text(time, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setSheetState(() => selectedEnd = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Auto-split preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF154D36), size: 15),
                            const SizedBox(width: 6),
                            Text(
                              'Auto-Generated Slots (${generatedSlots.length} Total)',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF154D36)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 100),
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: generatedSlots.map((slot) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Text(slot, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154D36),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() => isSaving = true);
                              try {
                                await ref.read(turfProfileProvider.notifier).updateOperatingSchedule(
                                  openingTime: selectedStart,
                                  closingTime: selectedEnd,
                                );
                                if (modalContext.mounted) {
                                  Navigator.pop(ctx);
                                  ToastUtils.showSuccess(
                                    context,
                                    'Operating schedule updated to $selectedStart - $selectedEnd! Slots re-split successfully.',
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => isSaving = false);
                                if (modalContext.mounted) {
                                  ToastUtils.showError(context, 'Failed to update schedule: $e');
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save & Update Operating Schedule', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getSportEmoji(String sport) {
    final lower = sport.toLowerCase();
    if (lower.contains('cricket')) return '🏏';
    if (lower.contains('foot') || lower.contains('soccer')) return '⚽';
    if (lower.contains('badminton')) return '🏸';
    if (lower.contains('pickle')) return '🏓';
    return '🎯';
  }
}
