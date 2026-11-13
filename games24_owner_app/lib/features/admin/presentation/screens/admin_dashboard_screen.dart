import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
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
  String _selectedFilter = 'Upcoming'; // Default to 'Upcoming' with exact time-aware filtering

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
        await ref.read(turfProfileProvider.notifier).fetchVerifiedAdminByPhone(
          profile.ownerPhone,
          turfId: profile.turfId > 0 ? profile.turfId : null,
        );
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
    final spotlightBanner = _buildMatchSpotlightBanner(context, profile);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildProAppBar(context, profile),
      body: RefreshIndicator(
        onRefresh: _refreshRealtimeData,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Operating Status & Quick Date Bar
              _buildVenueHeaderPulseBar(profile, nowFormatted),
              const SizedBox(height: 14),

              if (profile.isSubscriptionEndingSoon) ...[
                _buildSubscriptionCard(context, profile),
                const SizedBox(height: 14),
              ],

              // 2. Financial & Operational Overview
              _buildPerformanceBentoSection(profile),
              const SizedBox(height: 20),

              // 3. Live Matchday Spotlight (if active or upcoming match)
              ?spotlightBanner,

              // 4. Customer Bookings Stream & Filter Header
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
            child: InkWell(
              onTap: () => _showBranchSwitcherBottomSheet(context, profile),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.venueName.isNotEmpty ? profile.venueName : 'Turf Partner Hub',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_circle_outlined, size: 16, color: Color(0xFF154D36)),
                      ],
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
                            profile.area.isNotEmpty ? '${profile.area} • Tap to Switch Branch' : 'Tap to Switch Branch',
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
            ),
          ),
        ],
      ),
      actions: [
        // Fast Gate QR Scanner Shortcut (positioned at top right)
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
        const SizedBox(width: 6),
      ],
    );
  }

  void _showBranchSwitcherBottomSheet(BuildContext context, TurfProfileState profile) {
    final branches = profile.branches.isNotEmpty
        ? profile.branches
        : [
            OwnerTurfBranchItem(
              id: profile.verifiedAdminId ?? 1,
              venueName: profile.venueName,
              neighborhoodArea: profile.area,
              streetAddress: profile.address,
              ownerPhone: profile.ownerPhone,
              status: 'VERIFIED',
              todayBookingsCount: profile.todayBookingsCount,
              todayRevenue: profile.todayRevenue,
              monthRevenue: profile.monthRevenue,
              monthTotalBookings: profile.monthTotalBookings,
              isActive: true,
            ),
          ];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Turf Branches',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Select a location or register another branch',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...branches.map((b) {
                  final isCurrent = b.id == profile.verifiedAdminId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                        width: isCurrent ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFF154D36) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.stadium_rounded,
                          color: isCurrent ? Colors.white : const Color(0xFF475569),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        b.venueName,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${b.neighborhoodArea} • Today: ${b.todayBookingsCount} bookings (₹${b.todayRevenue.toInt()})',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isCurrent
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            )
                          : TextButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await ref.read(turfProfileProvider.notifier).switchBranch(b.id);
                                if (mounted && context.mounted) {
                                  ToastUtils.showSuccess(context, 'Switched to branch: ${b.venueName}');
                                }
                              },
                              child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddBranchDialog(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF154D36), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF154D36), size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '+ Register New Branch Location',
                        style: TextStyle(color: Color(0xFF154D36), fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddBranchDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '1200');

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Turf Branch', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Branch Venue Name *', hintText: 'e.g. Champions Turf - Anna Nagar'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: areaCtrl,
                decoration: const InputDecoration(labelText: 'Neighborhood / Area *', hintText: 'e.g. Anna Nagar'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Street Address', hintText: 'e.g. 12, Main Road'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: rateCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hourly Rate (₹)', hintText: '1200'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF154D36),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final vName = nameCtrl.text.trim();
              final vArea = areaCtrl.text.trim();
              if (vName.isEmpty || vArea.isEmpty) {
                ToastUtils.showError(context, 'Please enter branch name and area');
                return;
              }
              Navigator.pop(dlgCtx);
              final rate = double.tryParse(rateCtrl.text.trim()) ?? 1200.0;
              final ok = await ref.read(turfProfileProvider.notifier).addNewBranch(
                venueName: vName,
                neighborhoodArea: vArea,
                streetAddress: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : vArea,
                dayRate: rate,
                nightRate: rate + 200,
              );
              if (context.mounted) {
                if (ok) {
                  ToastUtils.showSuccess(context, 'New branch "$vName" added and verified! 🎉');
                } else {
                  ToastUtils.showError(context, 'Failed to add branch. Please try again.');
                }
              }
            },
            child: const Text('Create Branch'),
          ),
        ],
      ),
    );
  }

  // --- 2. OPERATING STATUS & DATE BAR ---
  Widget _buildVenueHeaderPulseBar(TurfProfileState profile, String formattedDate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Tactical Left Accent Ribbon
              Container(
                width: 4,
                color: const Color(0xFF154D36),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF154D36)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Hours: ${profile.weekdayOpeningTime} – ${profile.weekdayClosingTime} • Floodlights Active',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_manual_record_rounded, color: Color(0xFF16A34A), size: 8),
                            SizedBox(width: 4),
                            Text(
                              'Courts Open',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

  // --- 4. FINANCIAL & OPERATIONAL OVERVIEW (STADIUM BOX OFFICE) ---
  Widget _buildPerformanceBentoSection(TurfProfileState profile) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final allList = _getAllBookingsSource(profile);

    // Dynamic metrics based on actual bookings
    final cancelledList = allList.where((b) => b.isCancelled).toList();
    final dynamicCancelledCount = cancelledList.length > profile.cancelledCount
        ? cancelledList.length
        : profile.cancelledCount;
    final dynamicShiftedCount = profile.shiftedCount;
    final dynamicCancelledTotal = dynamicCancelledCount + dynamicShiftedCount;

    // Active (non-cancelled) bookings for today
    final activeTodayList = allList.where((b) {
      if (b.isCancelled) return false;
      final d = b.effectiveDate;
      return d == todayStr || d.toLowerCase() == 'today';
    }).toList();

    final dynamicTodayCount = activeTodayList.isNotEmpty
        ? activeTodayList.length
        : profile.todayBookingsCount;
    final dynamicTodayPaid = activeTodayList.isNotEmpty
        ? activeTodayList.where((b) => !b.paymentMethod.toLowerCase().contains('cash')).length
        : profile.todayPaidBookings;
    final dynamicTodayCash = (dynamicTodayCount - dynamicTodayPaid) > 0
        ? (dynamicTodayCount - dynamicTodayPaid)
        : 0;

    final activeMonthList = allList.where((b) => !b.isCancelled).toList();
    final dynamicTodayRev = profile.todayRevenue > 0
        ? profile.todayRevenue
        : activeTodayList.fold<double>(0.0, (sum, b) => sum + b.amount);
    final dynamicMonthRev = profile.monthRevenue > 0
        ? profile.monthRevenue
        : activeMonthList.fold<double>(0.0, (sum, b) => sum + b.amount);

    int dynamicBookedSlotsCount = 0;
    for (final b in activeTodayList) {
      final slotStr = b.effectiveTimeSlot;
      if (slotStr.isNotEmpty) {
        final slots = slotStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        dynamicBookedSlotsCount += slots.isNotEmpty ? slots.length : 1;
      } else {
        dynamicBookedSlotsCount += 1;
      }
    }
    if (dynamicBookedSlotsCount == 0 && activeTodayList.isNotEmpty) {
      dynamicBookedSlotsCount = activeTodayList.length;
    }

    final operatingSlots = AppConstants.generateTimeSlots(
      profile.openingTime.isNotEmpty ? profile.openingTime : '05:00 AM',
      profile.closingTime.isNotEmpty ? profile.closingTime : '11:00 PM',
    );
    final totalDailySlots = operatingSlots.isNotEmpty ? operatingSlots.length : 18;

    // Time-aware slot availability: total slots - passed slots - upcoming booked slots = remaining
    final currentMinutes = now.hour * 60 + now.minute;
    int passedSlotsCount = 0;
    for (final s in operatingSlots) {
      final startMin = AppConstants.parseSlotStartMinutes(s);
      if (startMin != -1 && currentMinutes >= startMin) {
        passedSlotsCount++;
      }
    }

    int upcomingBookedSlots = 0;
    for (final b in activeTodayList) {
      final startMin = TurfBookingHistoryItem.parseSlotStartMinutes(b.effectiveTimeSlot);
      if (startMin == -1 || currentMinutes < startMin) {
        final slotStr = b.effectiveTimeSlot;
        if (slotStr.isNotEmpty) {
          final slots = slotStr.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
          upcomingBookedSlots += slots.isNotEmpty ? slots.length : 1;
        } else {
          upcomingBookedSlots += 1;
        }
      }
    }

    final dynamicRemainingSlots = (totalDailySlots - passedSlotsCount - upcomingBookedSlots - profile.blockedSlotsCount) > 0
        ? (totalDailySlots - passedSlotsCount - upcomingBookedSlots - profile.blockedSlotsCount)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (clean, authoritative)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Turf Command Centre',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF154D36).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Live Overview',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF154D36),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Hero Metric Card: Monthly Revenue GMV (Stadium Box Office Pass)
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF072115), Color(0xFF0C2E1F), Color(0xFF154D36)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFF34D399).withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF154D36).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Subtle Athletic Pitch Markings Watermark
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TurfPitchMarkingsPainter(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.currency_rupee_rounded, color: Color(0xFFFBBF24), size: 15),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'MONTHLY REVENUE (GMV)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFCBD5E1),
                                letterSpacing: 0.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Text(
                              DateFormat('MMM yyyy').format(now),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          dynamicMonthRev > 0
                              ? '₹${NumberFormat('#,##,###').format(dynamicMonthRev.toInt())}'
                              : '₹0',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activeMonthList.length} total bookings • ₹1,100 / hr avg rate',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: dynamicMonthRev > 0 ? (dynamicMonthRev / 50000.0).clamp(0.05, 1.0) : 0.05,
                          minHeight: 5.5,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${((dynamicMonthRev / 50000.0).clamp(0.0, 1.0) * 100).toInt()}% of Monthly Target Met',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            'Target ₹50k 🎯',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.85),
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
        const SizedBox(height: 12),

        // 2 High-Utility Human-Designed Operational Cards (Themed Sports Pods)
        Row(
          children: [
            // 1. Today's Revenue & Collections Pod
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF154D36).withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF154D36), Color(0xFF22C55E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 7),
                        const Expanded(
                          child: Text(
                            "Today's Revenue",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₹${NumberFormat('#,##,###').format(dynamicTodayRev.toInt())}',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Micro Collections Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 10),
                          const SizedBox(width: 4),
                          Text(
                            '$dynamicTodayPaid Online • $dynamicTodayCash Cash',
                            style: const TextStyle(
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
              ),
            ),
            const SizedBox(width: 12),
            // 2. Court Availability & Radar Pod
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0369A1), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.stadium_rounded, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 7),
                        const Expanded(
                          child: Text(
                            "Court Radar",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$dynamicRemainingSlots Free',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Micro Capacity Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE0F2FE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pie_chart_rounded, color: Color(0xFF0284C7), size: 10),
                          const SizedBox(width: 4),
                          Text(
                            '$dynamicBookedSlotsCount / $totalDailySlots Booked',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Operational Shifts & Cancellations Banner
        if (dynamicCancelledTotal > 0)
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
                  child: const Icon(Icons.published_with_changes_rounded, color: Color(0xFFEA580C), size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cancellations & Slot Reschedules',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                      Text(
                        '$dynamicCancelledCount cancelled • $dynamicShiftedCount rescheduled',
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
                    '$dynamicCancelledTotal Total',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- 5. BROADCAST MATCHDAY SPOTLIGHT ---
  Widget? _buildMatchSpotlightBanner(BuildContext context, TurfProfileState profile) {
    if (_selectedFilter != 'Upcoming' && _selectedFilter != 'All' && _selectedFilter != 'Live Now') {
      return null;
    }

    final now = DateTime.now();
    final allList = _getAllBookingsSource(profile);
    final liveMatches = allList.where((b) => !b.isCancelled && b.isLiveNow(now)).toList();
    final upcomingMatches = allList.where((b) => !b.isCancelled && b.isUpcoming(now)).toList();

    final spotlight = liveMatches.isNotEmpty
        ? liveMatches.first
        : (upcomingMatches.isNotEmpty ? upcomingMatches.first : null);

    if (spotlight == null) return null;

    final isLive = spotlight.isLiveNow(now);
    final sportColor = _getSportColor(spotlight.sport);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLive ? const Color(0xFF16A34A) : const Color(0xFF154D36).withValues(alpha: 0.2),
          width: isLive ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                : const Color(0xFF154D36).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Broadcast Banner Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLive
                      ? [const Color(0xFF0F3825), const Color(0xFF16A34A)]
                      : [const Color(0xFF0F2E22), const Color(0xFF154D36)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isLive ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLive ? 'LIVE MATCH IN PROGRESS' : 'NEXT UP ON COURT',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      spotlight.effectiveTimeSlot,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Spotlight Match Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: sportColor.withValues(alpha: 0.12),
                        child: Text(
                          spotlight.customerName.isNotEmpty ? spotlight.customerName[0].toUpperCase() : 'P',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: sportColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spotlight.customerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(_getSportEmoji(spotlight.sport), style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${spotlight.sport} • ${spotlight.courtName}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
                          Text(
                            '₹${spotlight.amount.toInt()}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF154D36),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            spotlight.paymentMethod.toUpperCase().contains('CASH') ? 'Pay at Venue' : 'Paid Online',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: spotlight.paymentMethod.toUpperCase().contains('CASH')
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154D36),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 16),
                      label: const Text(
                        'View Match Pass & Check-In',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _openBookingDetailsSheet(context, spotlight),
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

  // --- 4. LIVE CUSTOMER BOOKINGS STREAM & FILTERS ---
  Widget _buildBookingsStreamSection(
    BuildContext context,
    TurfProfileState profile,
    List<TurfBookingHistoryItem> bookings,
  ) {
    final now = DateTime.now();
    final allList = _getAllBookingsSource(profile);
    final allCount = allList.length;
    final upcomingCount = allList.where((b) => b.isUpcoming(now)).length;
    final liveNowCount = allList.where((b) => b.isLiveNow(now)).length;
    final completedCount = allList.where((b) => b.isCompleted(now)).length;
    final cancelledCount = allList.where((b) => b.status.toLowerCase() == 'cancelled').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Customer Bookings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
        const SizedBox(height: 10),

        // Filter Pills with Real Dynamic Counts
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterPill('Upcoming', upcomingCount),
              const SizedBox(width: 8),
              _buildFilterPill('All', allCount),
              const SizedBox(width: 8),
              _buildFilterPill('Live Now', liveNowCount),
              const SizedBox(width: 8),
              _buildFilterPill('Completed', completedCount),
              if (cancelledCount > 0) ...[
                const SizedBox(width: 8),
                _buildFilterPill('Cancelled', cancelledCount),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Booking Cards List
        if (bookings.isNotEmpty)
          ...bookings.map((b) => _buildProBookingCard(context, b))
        else
          _buildEmptyBookingsState(),
      ],
    );
  }

  Widget _buildFilterPill(String title, int count) {
    final isSelected = _selectedFilter == title;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = title),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF154D36) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF154D36) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF154D36).withValues(alpha: 0.2),
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

  Widget _buildBookingScheduleDisplay(TurfBookingHistoryItem booking) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

    String dateLabel = booking.effectiveDate;
    if (dateLabel == todayStr || dateLabel.toLowerCase() == 'today') {
      dateLabel = 'Today';
    } else if (dateLabel == tomorrowStr || dateLabel.toLowerCase() == 'tomorrow') {
      dateLabel = 'Tomorrow';
    } else if (dateLabel.isNotEmpty) {
      try {
        final parsed = DateTime.tryParse(dateLabel);
        if (parsed != null) {
          dateLabel = DateFormat('d MMM yyyy').format(parsed);
        }
      } catch (_) {}
    }

    final slotStr = booking.effectiveTimeSlot;
    final slotList = slotStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              dateLabel.isNotEmpty ? dateLabel : 'Today',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            if (slotList.length > 1) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF154D36).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${slotList.length} Slots (${slotList.length} hrs)',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF154D36),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        if (slotList.length <= 1)
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 11.5, color: Color(0xFF154D36)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  slotStr.isNotEmpty ? slotStr : 'Time slot confirmed',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF154D36),
                  ),
                ),
              ),
            ],
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: slotList.map((slot) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 10, color: Color(0xFF334155)),
                  const SizedBox(width: 3),
                  Text(
                    slot,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildProBookingCard(BuildContext context, TurfBookingHistoryItem booking) {
    final now = DateTime.now();
    final isCompleted = booking.isCompleted(now);
    final isLiveNow = booking.isLiveNow(now);
    final isCancelled = booking.status.toLowerCase() == 'cancelled';
    final isUpi = booking.paymentMethod.toUpperCase().contains('UPI') || booking.paymentMethod.toUpperCase().contains('GPAY');
    final sportColor = _getSportColor(booking.sport);

    // Dynamic Pill Badge Styling
    Color badgeBg;
    Color badgeTextColor;
    String badgeLabel;

    if (isCancelled) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeTextColor = const Color(0xFFDC2626);
      badgeLabel = 'CANCELLED';
    } else if (isCompleted) {
      badgeBg = const Color(0xFFF1F5F9);
      badgeTextColor = const Color(0xFF475569);
      badgeLabel = 'COMPLETED ✓';
    } else if (isLiveNow) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF15803D);
      badgeLabel = 'LIVE NOW 🟢';
    } else {
      badgeBg = isUpi ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
      badgeTextColor = isUpi ? const Color(0xFF15803D) : const Color(0xFFB45309);
      badgeLabel = isUpi ? 'PAID ONLINE' : 'PAY AT VENUE';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLiveNow
              ? const Color(0xFF16A34A)
              : (isCompleted ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
          width: isLiveNow ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLiveNow
                ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openBookingDetailsSheet(context, booking),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Match Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: sportColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_getSportEmoji(booking.sport), style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                booking.sport,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: sportColor,
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (booking.isOpenMatch)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECDD3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sports_mma_rounded, size: 10, color: Color(0xFFBE123C)),
                                const SizedBox(width: 3),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 120),
                                  child: Text(
                                    booking.teamName != null && booking.teamName!.isNotEmpty
                                        ? '⚔️ ${booking.teamName}'
                                        : '⚔️ Open Challenge',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFBE123C),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: badgeBg,
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
                                badgeLabel,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: badgeTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Player Info & Schedule Breakdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: isCompleted ? const Color(0xFFE2E8F0) : sportColor.withValues(alpha: 0.12),
                      child: Text(
                        booking.customerName.isNotEmpty ? booking.customerName[0].toUpperCase() : 'P',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isCompleted ? const Color(0xFF475569) : sportColor,
                        ),
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
                          const SizedBox(height: 4),
                          _buildBookingScheduleDisplay(booking),
                          const SizedBox(height: 3),
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
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: isCompleted ? const Color(0xFF475569) : const Color(0xFF154D36),
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
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
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
              ),
              const SizedBox(height: 10),

              // 3. Stadium Match Pass Perforation Line with Cut-outs
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(7)),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const dashWidth = 4.0;
                        const dashSpace = 4.0;
                        final dashCount = (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
                        return Flex(
                          direction: Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            dashCount,
                            (_) => const SizedBox(
                              width: dashWidth,
                              height: 1.2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(7)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 4. Operational Action
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: isCompleted
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF16A34A)),
                                SizedBox(width: 6),
                                Text(
                                  'Match Completed & Closed',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                                ),
                              ],
                            ),
                            Text(
                              '₹${booking.amount.toInt()} Settled',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF154D36)),
                            ),
                          ],
                        ),
                      )
                    : isCancelled
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                                SizedBox(width: 6),
                                Text(
                                  'Slot Cancelled & Released',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF154D36),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.confirmation_number_outlined, size: 15),
                              label: const Text(
                                'View Match Pass & Actions',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _openBookingDetailsSheet(context, booking),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBookingDetailsSheet(BuildContext context, TurfBookingHistoryItem booking) {
    final now = DateTime.now();
    final isCompleted = booking.isCompleted(now);
    final isCancelled = booking.status.toLowerCase() == 'cancelled';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFF154D36).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.confirmation_number_rounded,
                              color: Color(0xFF154D36),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.id,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${booking.sport} • ${booking.courtName}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Details Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildModalDetailRow(
                        'Customer Name',
                        booking.customerName,
                        Icons.person_rounded,
                      ),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildModalDetailRow(
                        'Phone Number',
                        booking.customerPhone.isNotEmpty ? booking.customerPhone : 'Not Provided',
                        Icons.phone_rounded,
                        trailing: booking.customerPhone.isNotEmpty
                            ? InkWell(
                                onTap: () => ToastUtils.showSuccess(
                                  context,
                                  'Calling ${booking.customerName}: ${booking.customerPhone}',
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF154D36).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.call_rounded, size: 10.5, color: Color(0xFF154D36)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Call',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF154D36),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildModalDetailRow(
                        'Date',
                        booking.effectiveDate.isNotEmpty ? booking.effectiveDate : (booking.date.isNotEmpty ? booking.date : 'Today'),
                        Icons.calendar_today_rounded,
                      ),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildModalDetailRow(
                        'Time Slot',
                        booking.effectiveTimeSlot,
                        Icons.access_time_rounded,
                      ),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildModalDetailRow(
                        'Court / Venue',
                        booking.courtName,
                        Icons.stadium_rounded,
                      ),
                      if (booking.teamName != null && booking.teamName!.isNotEmpty) ...[
                        const Divider(height: 16, color: Color(0xFFE2E8F0)),
                        _buildModalDetailRow(
                          'Team / Match',
                          booking.teamName!,
                          Icons.sports_soccer_rounded,
                        ),
                      ],
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildModalDetailRow(
                        'Payment Mode',
                        booking.paymentMethod,
                        Icons.payment_rounded,
                      ),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildModalDetailRow(
                        'Amount',
                        '₹${booking.amount.toInt()}',
                        Icons.currency_rupee_rounded,
                        valueColor: const Color(0xFF154D36),
                      ),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildModalDetailRow(
                        'Status',
                        booking.status,
                        Icons.verified_rounded,
                        valueColor: isCancelled
                            ? const Color(0xFFDC2626)
                            : (isCompleted ? const Color(0xFF475569) : const Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Operational Action Buttons
                if (!isCancelled && !isCompleted) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154D36),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Gate Check-in (Open Scanner)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/admin/qr-scanner');
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.published_with_changes_rounded, size: 16),
                      label: const Text(
                        'Alter / Shift Slot',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openAlterModal(
                          context,
                          bookingId: booking.id,
                          playerName: booking.customerName,
                          time: booking.effectiveTimeSlot,
                          courtName: booking.courtName,
                        );
                      },
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154D36),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text(
                        'Open Gate Scanner',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/admin/qr-scanner');
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalDetailRow(
    String label,
    String value,
    IconData icon, {
    Widget? trailing,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Flexible(
          child: trailing ??
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
        ),
      ],
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
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_rounded, size: 28, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedFilter == 'Upcoming'
                ? 'No more upcoming bookings today'
                : 'No matching bookings in "$_selectedFilter"',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedFilter == 'Upcoming'
                ? 'All earlier scheduled matches for today are completed. Courts are ready for fresh walk-ins!'
                : 'All courts are open for reservations. You can create offline walk-in bookings anytime.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<TurfBookingHistoryItem> _getAllBookingsSource(TurfProfileState profile) {
    return profile.bookingHistory;
  }

  List<TurfBookingHistoryItem> _getFilteredBookings(TurfProfileState profile) {
    final source = _getAllBookingsSource(profile);
    final now = DateTime.now();

    if (_selectedFilter == 'Live Now') {
      return source.where((b) => b.isLiveNow(now)).toList();
    } else if (_selectedFilter == 'Upcoming') {
      return source.where((b) => b.isUpcoming(now)).toList();
    } else if (_selectedFilter == 'Completed') {
      return source.where((b) => b.isCompleted(now)).toList();
    } else if (_selectedFilter == 'Cancelled') {
      return source.where((b) => b.status.toLowerCase() == 'cancelled').toList();
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

  Color _getSportColor(String sport) {
    final lower = sport.toLowerCase();
    if (lower.contains('cricket')) return const Color(0xFFD97706); // Warm Amber
    if (lower.contains('foot') || lower.contains('soccer')) return const Color(0xFF15803D); // Grass Emerald
    if (lower.contains('badminton')) return const Color(0xFF4338CA); // Court Indigo
    if (lower.contains('pickle')) return const Color(0xFF0284C7); // Cyan
    if (lower.contains('tennis')) return const Color(0xFF65A30D); // Tennis Lime
    if (lower.contains('basket')) return const Color(0xFFEA580C); // Warm Orange
    return const Color(0xFF154D36);
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                      Expanded(
                        child: Text(
                          'Monthly Listing Fee',
                          style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                        ),
                      ),
                      Text('₹1,000.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        child: Text(
                          'GST (18% Applicable)',
                          style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                        ),
                      ),
                      Text('₹180.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        child: Text(
                          'Total Subscription Due',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '₹1,180 / mo',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF154D36)),
                      ),
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

/// Custom tactical pitch markings painter creating an authentic floodlit turf geometry
class _TurfPitchMarkingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Pitch perimeter line
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      const Radius.circular(14),
    );
    canvas.drawRRect(rrect, paint);

    // Halfway line
    final midX = size.width / 2;
    canvas.drawLine(Offset(midX, 8), Offset(midX, size.height - 8), paint);

    // Center circle
    final center = Offset(midX, size.height / 2);
    canvas.drawCircle(center, 28, paint);

    // Center spot
    final spotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, spotPaint);

    // Left penalty area box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, (size.height - 48) / 2, 28, 48),
        const Radius.circular(4),
      ),
      paint,
    );

    // Right penalty area box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 36, (size.height - 48) / 2, 28, 48),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
