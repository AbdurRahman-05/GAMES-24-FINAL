import 'package:flutter/material.dart';
import 'booking_manager.dart';
import 'challenge_manager.dart';
import 'match_score_manager.dart';
import 'match_scorecard_screen.dart';
import 'booking_qr_pass_modal.dart';
import 'teams_hub_screen.dart';
import 'tournaments_screen.dart';

class MatchScheduleScreen extends StatefulWidget {
  final int initialTab;

  const MatchScheduleScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<MatchScheduleScreen> createState() => _MatchScheduleScreenState();
}

class _MatchScheduleScreenState extends State<MatchScheduleScreen> {
  late int _selectedTab; // 0: Upcoming, 1: Live Now, 2: Completed
  String _selectedSport = 'All';

  final List<String> _sports = [
    'All',
    'Football',
    'Cricket',
    'Badminton',
    'Pickleball',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    BookingManager().fetchBookings();
    ChallengeManager().syncWithCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF166534), size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Match Schedule',
              style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Upcoming fixtures, booked slots & live games',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF166534)),
            onPressed: () {
              setState(() {
                BookingManager().fetchBookings();
                ChallengeManager().syncWithCurrentUser();
              });
            },
            tooltip: 'Refresh Schedule',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Material(
        color: const Color(0xFFF9FAFB),
        child: Column(
          children: [
            _buildTabSelector(),
            _buildSportFilter(),
            Expanded(
              child: _buildMatchList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    final activeBookings = BookingManager().activeBookings;
    final liveMatches = _getLiveMatches();
    final completedMatches = MatchScoreManager().matches;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildTabItem('Upcoming', 0, activeBookings.length),
            _buildTabItem('Live Now', 1, liveMatches.length, isLive: true),
            _buildTabItem('Completed', 2, completedMatches.length),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index, int count, {bool isLive = false}) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF166534) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF166534).withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLive) ...[
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.redAccent : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF374151),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSportFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _sports.map((sport) {
            final isSelected = _selectedSport == sport;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  _getSportLabelWithIcon(sport),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF166534),
                backgroundColor: const Color(0xFFF3F4F6),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF166534) : const Color(0xFFE5E7EB),
                  ),
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedSport = sport);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getSportLabelWithIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'football':
        return '⚽ Football';
      case 'cricket':
        return '🏏 Cricket';
      case 'badminton':
        return '🏸 Badminton';
      case 'pickleball':
        return '🏓 Pickleball';
      default:
        return '🏆 All Sports';
    }
  }

  List<Map<String, dynamic>> _getLiveMatches() {
    final allBookings = BookingManager().activeBookings;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return allBookings.where((b) {
      final date = (b['date'] ?? '').toString();
      final isToday = date.contains(todayStr) || date.toLowerCase().contains('today');
      return isToday;
    }).toList();
  }

  Widget _buildMatchList() {
    if (_selectedTab == 0) {
      // UPCOMING MATCHES
      final bookings = BookingManager().activeBookings.where((b) {
        if (_selectedSport == 'All') return true;
        final s = (b['sport'] ?? '').toString().toLowerCase();
        return s == _selectedSport.toLowerCase();
      }).toList();

      final challenges = ChallengeManager().activeChallenges.where((c) {
        if (!c.isJoined && !c.isCreator) return false;
        if (_selectedSport == 'All') return true;
        return c.sport.toLowerCase() == _selectedSport.toLowerCase();
      }).toList();

      if (bookings.isEmpty && challenges.isEmpty) {
        return _buildEmptyState(
          icon: Icons.calendar_month_outlined,
          title: 'No Upcoming Matches Scheduled',
          subtitle: 'Book a turf slot or join an open challenge to get your match on the schedule!',
          showBookAction: true,
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (bookings.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'YOUR BOOKED TURF MATCHES',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            ...bookings.map((b) => _buildBookingMatchCard(b)),
          ],
          if (challenges.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'OPEN CHALLENGE MATCHES',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            ...challenges.map((c) => _buildChallengeMatchCard(c)),
          ],
          const SizedBox(height: 40),
        ],
      );
    } else if (_selectedTab == 1) {
      // LIVE NOW MATCHES
      final liveBookings = _getLiveMatches().where((b) {
        if (_selectedSport == 'All') return true;
        final s = (b['sport'] ?? '').toString().toLowerCase();
        return s == _selectedSport.toLowerCase();
      }).toList();

      if (liveBookings.isEmpty) {
        return _buildEmptyState(
          icon: Icons.sensors_outlined,
          title: 'No Live Matches Ongoing Right Now',
          subtitle: 'Matches scheduled for today will automatically appear here with live digital scoring controls.',
          showBookAction: true,
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...liveBookings.map((b) => _buildLiveMatchCard(b)),
          const SizedBox(height: 40),
        ],
      );
    } else {
      // COMPLETED MATCHES
      final completedMatches = MatchScoreManager().matches.where((m) {
        if (_selectedSport == 'All') return true;
        return m.sport.toLowerCase() == _selectedSport.toLowerCase();
      }).toList();

      if (completedMatches.isEmpty) {
        return _buildEmptyState(
          icon: Icons.emoji_events_outlined,
          title: 'No Completed Matches Yet',
          subtitle: 'Finished matches and saved official scorecards will be archived here with detailed performance stats.',
          showBookAction: false,
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...completedMatches.map((m) => _buildCompletedMatchCard(m)),
          const SizedBox(height: 40),
        ],
      );
    }
  }

  Widget _buildBookingMatchCard(Map<String, dynamic> booking) {
    final bookingId = (booking['id'] ?? booking['bookingId'] ?? 'BK-G24').toString();
    final turfName = (booking['turfName'] ?? booking['courtName'] ?? 'Turf Arena').toString();
    final sport = (booking['sport'] ?? 'Football').toString();
    final date = (booking['date'] ?? 'Upcoming').toString();
    final timeSlot = (booking['timeSlot'] ?? '06:00 PM - 07:00 PM').toString();
    final courtName = (booking['courtName'] ?? 'Main Arena (Court A)').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                _getSportBadge(sport),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sport,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 11, color: Color(0xFF166534)),
                      SizedBox(width: 4),
                      Text(
                        'Confirmed & Booked',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turfName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        courtName,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date & Time Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF166534)),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF166534)),
                      const SizedBox(width: 6),
                      Text(
                        timeSlot,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF166534),
                          side: const BorderSide(color: Color(0xFF166534)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                        label: const Text('QR Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () => BookingQrPassModal.show(context, booking),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF166534),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.scoreboard_outlined, size: 16),
                        label: const Text('Scorecard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchScorecardScreen(
                                bookingId: bookingId,
                                turfName: turfName,
                                sport: sport,
                                date: date,
                                timeSlot: timeSlot,
                                isOpenMatch: booking['isOpenMatch'] == true ||
                                    booking['is_open_match'] == true,
                              ),
                            ),
                          );
                        },
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

  Widget _buildChallengeMatchCard(Challenge challenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                _getSportBadge(challenge.sport),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${challenge.sport} • ${challenge.teamSize}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Text(
                    'Open Match',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
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
                  challenge.turfName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: challenge.challengerColor.withValues(alpha: 0.2),
                      child: Text(
                        challenge.challengerTeamInitials,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: challenge.challengerColor),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Host: ${challenge.challengerName}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF166534)),
                      const SizedBox(width: 6),
                      Text(
                        challenge.date,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF166534)),
                      const SizedBox(width: 6),
                      Text(
                        challenge.time,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF166534),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.scoreboard_outlined, size: 16),
                    label: const Text('Open Scorecard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchScorecardScreen(
                            bookingId: challenge.id,
                            turfName: challenge.turfName,
                            sport: challenge.sport,
                            date: challenge.date,
                            timeSlot: challenge.time,
                            isOpenMatch: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMatchCard(Map<String, dynamic> booking) {
    final bookingId = (booking['id'] ?? booking['bookingId'] ?? 'BK-G24').toString();
    final turfName = (booking['turfName'] ?? booking['courtName'] ?? 'Turf Arena').toString();
    final sport = (booking['sport'] ?? 'Football').toString();
    final date = (booking['date'] ?? 'Today').toString();
    final timeSlot = (booking['timeSlot'] ?? 'Now Playing').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF166534).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                _getSportBadge(sport),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sport,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'LIVE TODAY',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
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
                  turfName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF166534)),
                    const SizedBox(width: 4),
                    Text(
                      '$date • $timeSlot',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF166534),
                          side: const BorderSide(color: Color(0xFF166534)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                        label: const Text('Gate QR Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () => BookingQrPassModal.show(context, booking),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF166534),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.sports_cricket, size: 16),
                        label: const Text('Live Scorecard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchScorecardScreen(
                                bookingId: bookingId,
                                turfName: turfName,
                                sport: sport,
                                date: date,
                                timeSlot: timeSlot,
                                isOpenMatch: booking['isOpenMatch'] == true ||
                                    booking['is_open_match'] == true,
                              ),
                            ),
                          );
                        },
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

  Widget _buildCompletedMatchCard(MatchResultItem match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                _getSportBadge(match.sport),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${match.sport} Match Results',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Finished',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
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
                  match.turfName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Match scores display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              match.teamAName,
                              style: TextStyle(
                                fontWeight: match.winner == match.teamAName ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            match.teamAScore,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: match.winner == match.teamAName ? const Color(0xFF166534) : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              match.teamBName,
                              style: TextStyle(
                                fontWeight: match.winner == match.teamBName ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            match.teamBScore,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: match.winner == match.teamBName ? const Color(0xFF166534) : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      if (match.winningMargin.isNotEmpty) ...[
                        const Divider(height: 16),
                        Text(
                          '🏆 ${match.winner} won ${match.winningMargin}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF166534),
                      side: const BorderSide(color: Color(0xFF166534)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text('View Match Summary & Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchScorecardScreen(
                            bookingId: match.bookingId,
                            turfName: match.turfName,
                            sport: match.sport,
                            date: match.date,
                            timeSlot: match.timeSlot,
                            initialTab: 3, // Result tab
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSportBadge(String sport) {
    IconData icon = Icons.sports_soccer_outlined;
    Color color = const Color(0xFF166534);

    switch (sport.toLowerCase()) {
      case 'cricket':
        icon = Icons.sports_cricket;
        color = const Color(0xFFB45309);
        break;
      case 'badminton':
        icon = Icons.sports_tennis;
        color = const Color(0xFF7C3AED);
        break;
      case 'pickleball':
        icon = Icons.sports_tennis;
        color = const Color(0xFF0284C7);
        break;
      default:
        icon = Icons.sports_soccer;
        color = const Color(0xFF166534);
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool showBookAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F5EB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
              ),
              child: Icon(icon, size: 36, color: const Color(0xFF166534)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                if (showBookAction)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF166534),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Book Turf Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF166534),
                    side: const BorderSide(color: Color(0xFF166534)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.groups_outlined, size: 16),
                  label: const Text('Join Open Match', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TeamsHubScreen()),
                    );
                  },
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.emoji_events_outlined, size: 16),
                  label: const Text('Tournaments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TournamentsScreen(isStandalone: true)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

