import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../providers/admin_providers.dart';
import '../widgets/alter_booking_dialog.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isRefreshing = false;
  String _selectedFilter = 'All'; // 'All', 'Live Now', 'Upcoming', 'Checked In'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshRealtimeData();
    });
  }

  Future<void> _refreshRealtimeData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final profile = ref.read(turfProfileProvider);
      if (profile.ownerPhone.isNotEmpty) {
        await ref.read(turfProfileProvider.notifier).fetchVerifiedAdminByPhone(profile.ownerPhone);
      }
    } catch (e) {
      debugPrint("Error refreshing realtime dashboard data: $e");
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _openAlterModal(
    BuildContext context, {
    required String bookingId,
    required String playerName,
    required String time,
    required String courtName,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlterBookingDialog(
        bookingId: bookingId,
        playerName: playerName,
        originalTimeSlot: time,
        courtName: courtName,
        onRescheduled: () async {
          final p = ref.read(turfProfileProvider);
          final newShifted = p.shiftedCount + 1;
          final newCancelledTotal = p.cancelledCount + newShifted;
          await ref.read(turfProfileProvider.notifier).updateVenueKpiMetrics(
            shiftedCount: newShifted,
            cancelledTotal: newCancelledTotal,
            cancelledBadge: '$newCancelledTotal Tracked',
          );
          if (context.mounted) {
            ToastUtils.showSuccess(context, "Booking $bookingId rescheduled! Shifted metrics updated.");
          }
        },
        onCancelled: () async {
          final p = ref.read(turfProfileProvider);
          final newCancelled = p.cancelledCount + 1;
          final newCancelledTotal = newCancelled + p.shiftedCount;
          await ref.read(turfProfileProvider.notifier).updateVenueKpiMetrics(
            cancelledCount: newCancelled,
            cancelledTotal: newCancelledTotal,
            cancelledBadge: '$newCancelledTotal Tracked',
          );
          if (context.mounted) {
            ToastUtils.showSuccess(context, "Booking $bookingId cancelled. Database record updated.");
          }
        },
        onCheckedIn: () async {
          _performQuickGateCheckIn(playerName);
        },
      ),
    );
  }

  Future<void> _performQuickGateCheckIn(String playerName) async {
    final p = ref.read(turfProfileProvider);
    final newTodayBookings = p.todayBookingsCount + 1;
    final newPaidBookings = p.todayPaidBookings + 1;
    final newMonthBookings = p.monthTotalBookings + 1;
    final newMonthRev = p.monthRevenue + 1200.0;
    await ref.read(turfProfileProvider.notifier).updateVenueKpiMetrics(
      todayBookingsCount: newTodayBookings,
      todayPaidBookings: newPaidBookings,
      todayBookingsGrowth: '+$newTodayBookings Today',
      monthTotalBookings: newMonthBookings,
      monthRevenue: newMonthRev,
      revenueBadge: '₹${newMonthRev.toInt()} GMV',
    );
    if (mounted) {
      ToastUtils.showSuccess(context, "Gate check-in confirmed for $playerName! 🎉");
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(turfProfileProvider);

    // If subscription has expired or on hold: block owner access
    if (profile.isSubscriptionBlocked) {
      return _buildBlockedAccessScaffold(context, profile);
    }

    final bookings = _getFilteredBookings(profile);
    final nowFormatted = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildProAppBar(context, profile),
      body: RefreshIndicator(
        onRefresh: _refreshRealtimeData,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Operating Status & Quick Date Bar
              _buildVenueHeaderPulseBar(profile, nowFormatted),
              const SizedBox(height: 12),

              // 2. Subscription Status Banner (Urgent Alert or Pro Membership Status)
              _buildSubscriptionCard(context, profile),
              const SizedBox(height: 16),

              // 3. Financial & Operational Bento Grid
              _buildPerformanceBentoSection(profile),
              const SizedBox(height: 20),

              // 4. Quick Operational Command Center
              _buildQuickActionsCommandCenter(context),
              const SizedBox(height: 20),

              // 5. Active Sports Catalog Quick Bar
              if (profile.sports.isNotEmpty) ...[
                _buildActiveSportsBar(profile),
                const SizedBox(height: 20),
              ],

              // 6. Live Customer Bookings Stream & Filter Header
              _buildBookingsStreamSection(context, profile, bookings),
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
      titleSpacing: 16,
      toolbarHeight: 64,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF154D36), Color(0xFF2D7A5B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF154D36).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.stadium_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.venueName.isNotEmpty ? profile.venueName : 'Turf Partner Hub',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6.5,
                      height: 6.5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        profile.area.isNotEmpty ? '${profile.area} • Partner Dashboard' : 'Live Partner Dashboard',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A),
                        ),
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
      actions: [
        // Sync / Refresh Indicator
        IconButton(
          onPressed: _refreshRealtimeData,
          tooltip: 'Refresh Real-time Data',
          icon: _isRefreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF154D36)),
                )
              : Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.sync_rounded, color: Color(0xFF334155), size: 18),
                ),
        ),
        // Fast Gate QR Scanner Shortcut
        IconButton(
          onPressed: () => context.push('/admin/qr-scanner'),
          tooltip: 'Fast Gate QR Scanner',
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF154D36).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF154D36).withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF154D36), size: 18),
          ),
        ),
        // Logout Shortcut
        IconButton(
          onPressed: () => _handleLogout(context),
          tooltip: 'Log Out',
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 18),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // --- 2. OPERATING STATUS & DATE PULSE BAR ---
  Widget _buildVenueHeaderPulseBar(TurfProfileState profile, String formattedDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Hours: ${profile.weekdayOpeningTime} - ${profile.weekdayClosingTime}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF15803D)),
                SizedBox(width: 4),
                Text(
                  'Verified KYC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. SUBSCRIPTION CARD (URGENT ALERT vs SLEEK MEMBERSHIP PILL) ---
  Widget _buildSubscriptionCard(BuildContext context, TurfProfileState profile) {
    if (profile.isSubscriptionEndingSoon) {
      // Urgent Renewal Banner
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription Expires in ${profile.subscriptionDaysRemaining} Day(s) ⚠️',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Due by ${profile.subscriptionRenewDate}. Renew now to keep turf visible on Player App.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Due: ₹1,180 (Base ₹1k + GST)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF78350F),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.bolt_rounded, size: 14),
                    label: const Text(
                      'Renew Now',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _openSubscriptionDialog(context, profile),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Healthy Subscription Banner (Sleek Pro Partner Pill)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3825), Color(0xFF154D36)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF154D36).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Platform Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '• Live on Player App',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF86EFAC),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '${profile.subscriptionDaysRemaining} days remaining (Renews ${profile.subscriptionRenewDate})',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _openSubscriptionDialog(context, profile),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Plan',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 9),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. FINANCIAL & OPERATIONAL BENTO SECTION ---
  Widget _buildPerformanceBentoSection(TurfProfileState profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Business Performance',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Real-time Synced',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Hero Metric Card: Monthly Revenue GMV
        Container(
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
                        child: const Icon(Icons.currency_rupee_rounded, color: Color(0xFFFBBF24), size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Total Monthly Revenue (GMV)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      profile.revenueBadge.isNotEmpty ? profile.revenueBadge : 'Realtime',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF86EFAC),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                profile.monthRevenue > 0
                    ? '₹${NumberFormat('#,##,###').format(profile.monthRevenue.toInt())}'
                    : '₹0',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${profile.monthTotalBookings} bookings recorded this calendar month',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              // Mini progress indicator bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: profile.monthRevenue > 0 ? (profile.monthRevenue / 50000.0).clamp(0.05, 1.0) : 0.05,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3-Metric Secondary Bento Row
        Row(
          children: [
            // 1. Today's Bookings
            Expanded(
              child: _buildBentoMiniCard(
                title: "Today's Bookings",
                value: '${profile.todayBookingsCount}',
                subtitle: '${profile.todayPaidBookings} Paid • ${profile.todayCashBookings} Cash',
                badgeText: profile.todayBookingsGrowth,
                badgeColor: const Color(0xFF16A34A),
                icon: Icons.confirmation_number_rounded,
                iconColor: const Color(0xFF154D36),
              ),
            ),
            const SizedBox(width: 10),
            // 2. Slot Utilization
            Expanded(
              child: _buildBentoMiniCard(
                title: "Court Occupancy",
                value: '${profile.freeSlotsCount} Free',
                subtitle: '${profile.bookedSlotsCount} Booked • ${profile.blockedSlotsCount} Off',
                badgeText: profile.slotsBadge,
                badgeColor: const Color(0xFF0284C7),
                icon: Icons.pie_chart_rounded,
                iconColor: const Color(0xFF0284C7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Operational Shifts & Cancellations Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.published_with_changes_rounded, color: Color(0xFFEA580C), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cancellations & Shifts Tracked',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                    Text(
                      '${profile.cancelledCount} Cancelled • ${profile.shiftedCount} Shifted Slot(s)',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${profile.cancelledTotal} Total',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBentoMiniCard({
    required String title,
    required String value,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              if (badgeText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- 5. QUICK ACTIONS COMMAND CENTER ---
  Widget _buildQuickActionsCommandCenter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Operational Command Center',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionCommandCard(
                icon: Icons.edit_calendar_rounded,
                iconColor: const Color(0xFF154D36),
                title: 'Slots & Pricing',
                subtitle: 'Block / Offers',
                onTap: () => context.push('/admin/slots'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCommandCard(
                icon: Icons.qr_code_scanner_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'Gate Check-in',
                subtitle: 'Scan Player QR',
                onTap: () => context.push('/admin/qr-scanner'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCommandCard(
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFFD97706),
                title: 'Tournaments',
                subtitle: 'Sync Leagues',
                onTap: () => context.go('/admin/tournaments'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCommandCard(
                icon: Icons.tune_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: 'Turf Setup',
                subtitle: 'Courts & Rates',
                onTap: () => context.go('/admin/profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCommandCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. ACTIVE SPORTS CATALOG BAR ---
  Widget _buildActiveSportsBar(TurfProfileState profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Sports & Rates',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/admin/profile'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Edit Rates ➔', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profile.sports.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final s = profile.sports[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getSportEmoji(s.name), style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      s.name,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• ₹${s.hourlyRate.toInt()}/hr',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF154D36)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 7. LIVE CUSTOMER BOOKINGS STREAM & FILTERS ---
  Widget _buildBookingsStreamSection(
    BuildContext context,
    TurfProfileState profile,
    List<TurfBookingHistoryItem> bookings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Live Customer Bookings',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF154D36).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${bookings.length}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF154D36)),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/admin/slots'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('All Slots ➔', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Filter Pills
        Row(
          children: [
            _buildFilterPill('All'),
            const SizedBox(width: 6),
            _buildFilterPill('Upcoming'),
            const SizedBox(width: 6),
            _buildFilterPill('Live Now'),
            const SizedBox(width: 6),
            _buildFilterPill('Checked In'),
          ],
        ),
        const SizedBox(height: 12),

        // Booking Cards List
        if (bookings.isNotEmpty)
          ...bookings.map((b) => _buildProBookingCard(context, b))
        else
          _buildEmptyBookingsState(),
      ],
    );
  }

  Widget _buildFilterPill(String title) {
    final isSelected = _selectedFilter == title;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = title),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF154D36) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF154D36) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildProBookingCard(BuildContext context, TurfBookingHistoryItem booking) {
    final isUpi = booking.paymentMethod.toUpperCase().contains('UPI') || booking.paymentMethod.toUpperCase().contains('GPAY');
    final isLiveNow = booking.dateTimeSlot.toLowerCase().contains('now') || booking.dateTimeSlot.toLowerCase().contains('live');
    final isCheckedIn = booking.status.toLowerCase().contains('completed') || booking.status.toLowerCase().contains('checked');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLiveNow ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
          width: isLiveNow ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Sport Tag, Booking ID & Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF154D36).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_getSportEmoji(booking.sport), style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            booking.sport,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF154D36),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      booking.id,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLiveNow
                        ? const Color(0xFFDCFCE7)
                        : (isCheckedIn ? const Color(0xFFE0E7FF) : (isUpi ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7))),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLiveNow) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isLiveNow
                            ? 'LIVE NOW'
                            : (isCheckedIn ? 'CHECKED IN' : (isUpi ? 'PAID ONLINE' : 'PAY AT VENUE')),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isLiveNow
                              ? const Color(0xFF15803D)
                              : (isCheckedIn ? const Color(0xFF4338CA) : (isUpi ? const Color(0xFF15803D) : const Color(0xFFB45309))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: Color(0xFFF1F5F9)),

            // Player Info & Time Slot
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: Text(
                    booking.customerName.isNotEmpty ? booking.customerName[0].toUpperCase() : 'P',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF154D36)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              booking.dateTimeSlot,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        booking.courtName,
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${booking.amount.toInt()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF154D36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (booking.customerPhone.isNotEmpty)
                      InkWell(
                        onTap: () {
                          ToastUtils.showSuccess(context, "Contacting ${booking.customerName}: ${booking.customerPhone}");
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.call_rounded, size: 10, color: Color(0xFF475569)),
                              SizedBox(width: 3),
                              Text('Call', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Operational Action Buttons (Gate Check-In + Alter/Shift)
            Row(
              children: [
                if (!isCheckedIn) ...[
                  Expanded(
                    flex: 5,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154D36),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                      label: const Text(
                        'Gate Check-in',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _performQuickGateCheckIn(booking.customerName),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 5,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    icon: const Icon(Icons.published_with_changes_rounded, size: 14),
                    label: const Text(
                      'Alter / Shift Slot',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _openAlterModal(
                      context,
                      bookingId: booking.id,
                      playerName: booking.customerName,
                      time: booking.dateTimeSlot,
                      courtName: booking.courtName,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBookingsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_rounded, size: 28, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          const Text(
            'No matching bookings for this filter',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          const Text(
            'All courts are open for reservations. You can create offline walk-in bookings anytime.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<TurfBookingHistoryItem> _getFilteredBookings(TurfProfileState profile) {
    // If profile has live booking history, use it. Otherwise, provide realistic sample bookings.
    List<TurfBookingHistoryItem> source = profile.bookingHistory;
    if (source.isEmpty) {
      source = [
        TurfBookingHistoryItem(
          id: 'BK-98421',
          customerName: 'Karthik Raja',
          customerPhone: '9840123456',
          sport: 'Cricket',
          courtName: '${profile.venueName.isNotEmpty ? profile.venueName : 'Turf'} - Box Cricket Arena',
          dateTimeSlot: 'Today, 04:00 PM - 05:00 PM',
          amount: 1000.0,
          paymentMethod: 'UPI (GPay)',
          status: 'Confirmed',
        ),
        TurfBookingHistoryItem(
          id: 'BK-98422',
          customerName: 'Vigneshwaran S',
          customerPhone: '9876543210',
          sport: 'Football',
          courtName: '${profile.venueName.isNotEmpty ? profile.venueName : 'Turf'} - Main Arena (7v7)',
          dateTimeSlot: 'Today, 05:00 PM - 06:00 PM (Live Now)',
          amount: 1400.0,
          paymentMethod: 'Pay at Venue',
          status: 'Confirmed',
        ),
        TurfBookingHistoryItem(
          id: 'BK-98420',
          customerName: 'Mohammed Rizwan',
          customerPhone: '9443210987',
          sport: 'Badminton',
          courtName: '${profile.venueName.isNotEmpty ? profile.venueName : 'Turf'} - Court 1',
          dateTimeSlot: 'Today, 02:00 PM - 03:00 PM',
          amount: 450.0,
          paymentMethod: 'UPI (PhonePe)',
          status: 'Completed',
        ),
      ];
    }

    if (_selectedFilter == 'Live Now') {
      return source.where((b) => b.dateTimeSlot.toLowerCase().contains('live') || b.dateTimeSlot.toLowerCase().contains('now')).toList();
    } else if (_selectedFilter == 'Upcoming') {
      return source.where((b) => !b.status.toLowerCase().contains('completed') && !b.dateTimeSlot.toLowerCase().contains('live')).toList();
    } else if (_selectedFilter == 'Checked In') {
      return source.where((b) => b.status.toLowerCase().contains('completed') || b.status.toLowerCase().contains('checked')).toList();
    }
    return source;
  }

  String _getSportEmoji(String sport) {
    final lower = sport.toLowerCase();
    if (lower.contains('cricket')) return '🏏';
    if (lower.contains('foot') || lower.contains('soccer')) return '⚽';
    if (lower.contains('badminton')) return '🏸';
    if (lower.contains('pickle')) return '🏓';
    if (lower.contains('tennis')) return '🎾';
    if (lower.contains('basket')) return '🏀';
    if (lower.contains('volley')) return '🏐';
    return '🏆';
  }

  // --- 8. BLOCKED ACCESS SCAFFOLD ---
  Widget _buildBlockedAccessScaffold(BuildContext context, TurfProfileState profile) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.stadium_rounded, color: Color(0xFF154D36), size: 24),
            SizedBox(width: 8),
            Text(
              'Games24 Partner Hub',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 18),
            ),
            onPressed: () => _handleLogout(context),
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF87171), width: 2),
                ),
                child: const Icon(Icons.lock_clock_rounded, size: 48, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Owner Access Blocked',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF991B1B),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'SUBSCRIPTION EXPIRED • TURF HIDDEN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your monthly platform subscription for "${profile.venueName.isNotEmpty ? profile.venueName : 'Your Turf'}" has ended.\n\nYour venue is currently HIDDEN from players on the Games24 Player App and owner hub access is locked until renewed.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.5),
              ),
              const SizedBox(height: 24),
              // Fee breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: const [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Platform Listing Fee', style: TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                        Text('₹1,000.00', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Applicable GST (18%)', style: TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                        Text('₹180.00', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount Due', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                        Text('₹1,180 / month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF166534))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF166534),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 20),
                  label: const Text(
                    'Pay ₹1,180 & Unlock Access Now ⚡',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () async {
                    final success = await ref.read(turfProfileProvider.notifier).payPlatformSubscription();
                    if (context.mounted && success) {
                      ToastUtils.showSuccess(
                        context,
                        "Subscription renewed! Dashboard access unlocked and turf is now LIVE on Player App.",
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  ref.read(turfProfileProvider.notifier).setSubscriptionDays(30);
                  ToastUtils.showSuccess(context, "Testing: Subscription reset to Active (30 days remaining).");
                },
                child: const Text('Quick Test: Unlock for 30 Days (Demo)', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 9. SUBSCRIPTION DIALOG ---
  void _openSubscriptionDialog(BuildContext context, TurfProfileState profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF154D36).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF154D36), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Platform Subscription',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Games24 operates on a zero-convenience fee model for players. Turf owners subscribe monthly to list their turf and accept live bookings.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Monthly Listing Fee', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                      Text('₹1,000.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('GST (18% Applicable)', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                      Text('₹180.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Total Subscription Due', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      Text('₹1,180 / month', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF154D36))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  profile.isSubscriptionActive ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: profile.isSubscriptionActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    profile.isSubscriptionActive
                        ? 'Status: Active (Turf is visible on Player App)'
                        : 'Status: Inactive (Turf is hidden from Player App)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: profile.isSubscriptionActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF154D36),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: Text(
                  profile.isSubscriptionActive ? 'Renew Platform Plan (₹1,180)' : 'Pay ₹1,180 & Activate Turf ⚡',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await ref.read(turfProfileProvider.notifier).payPlatformSubscription();
                  if (context.mounted) {
                    if (success) {
                      ToastUtils.showSuccess(
                        context,
                        "Monthly subscription of ₹1,180 paid! Your turf is now LIVE and visible on Games24 Player App.",
                      );
                    } else {
                      ToastUtils.showError(context, "Payment failed. Please retry.");
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(turfProfileProvider.notifier).toggleSubscription();
                  if (context.mounted) {
                    final isNowActive = ref.read(turfProfileProvider).isSubscriptionActive;
                    if (isNowActive) {
                      ToastUtils.showSuccess(context, "Subscription ACTIVE: Turf is now visible on Player App!");
                    } else {
                      ToastUtils.showWarning(context, "Subscription HOLD: Turf is now HIDDEN from Player App!");
                    }
                  }
                },
                child: Text(
                  profile.isSubscriptionActive ? 'Test Deactivate / Hide Turf' : 'Test Activate Turf',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 10. LOGOUT FLOW ---
  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of the Partner Hub?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('owner_logged_in', false);
    await prefs.remove('owner_phone');
    await prefs.remove('verified_admin_data');
    await prefs.remove('owner_venue_name');
    ref.read(isAdminModeProvider.notifier).setMode(false);
    if (context.mounted) {
      context.go('/login');
    }
  }
}
