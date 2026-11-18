import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../api_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/phone_dialer.dart';
import '../../providers/admin_providers.dart';
import '../widgets/alter_booking_dialog.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isRefreshing = false;
  String _selectedFilter =
      'Upcoming'; // Default to 'Upcoming' with exact time-aware filtering

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
      if (profile.ownerPhone.isNotEmpty && !profile.isPendingApproval) {
        await ref
            .read(turfProfileProvider.notifier)
            .fetchVerifiedAdminByPhone(
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
          await ref
              .read(turfProfileProvider.notifier)
              .updateVenueKpiMetrics(
                shiftedCount: newShifted,
                cancelledTotal: newCancelledTotal,
                cancelledBadge: '$newCancelledTotal Tracked',
              );
          if (context.mounted) {
            ToastUtils.showSuccess(
              context,
              "Booking $bookingId rescheduled! Shifted metrics updated.",
            );
          }
        },
        onCancelled: () async {
          final p = ref.read(turfProfileProvider);
          final newCancelled = p.cancelledCount + 1;
          final newCancelledTotal = newCancelled + p.shiftedCount;
          await ref
              .read(turfProfileProvider.notifier)
              .updateVenueKpiMetrics(
                cancelledCount: newCancelled,
                cancelledTotal: newCancelledTotal,
                cancelledBadge: '$newCancelledTotal Tracked',
              );
          if (context.mounted) {
            ToastUtils.showSuccess(
              context,
              "Booking $bookingId cancelled. Database record updated.",
            );
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
    await ref
        .read(turfProfileProvider.notifier)
        .updateVenueKpiMetrics(
          todayBookingsCount: newTodayBookings,
          todayPaidBookings: newPaidBookings,
          todayBookingsGrowth: '+$newTodayBookings Today',
          monthTotalBookings: newMonthBookings,
          monthRevenue: newMonthRev,
          revenueBadge: '₹${newMonthRev.toInt()} GMV',
        );
    if (mounted) {
      ToastUtils.showSuccess(
        context,
        "Gate check-in confirmed for $playerName!",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final profile = ref.watch(turfProfileProvider);

    // If subscription has expired or on hold: block owner access
    if (profile.isSubscriptionBlocked) {
      return _buildBlockedAccessScaffold(context, profile);
    }

    final bookings = _getFilteredBookings(profile);
    final spotlightBanner = _buildMatchSpotlightBanner(context, profile);

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: _buildProAppBar(context, profile),
      body: RefreshIndicator(
        onRefresh: _refreshRealtimeData,
        color: AppColors.primary,
        backgroundColor: const Color(0xFF0D0D0D),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0. Notice when active branch is pending Super Admin approval
              if (profile.isPendingApproval) ...[
                _buildPendingAdminApprovalNotice(context, profile),
                const SizedBox(height: 14),
              ],

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

  // --- 1. PRO LUXURY APP BAR ---
  PreferredSizeWidget _buildProAppBar(
    BuildContext context,
    TurfProfileState profile,
  ) {
    final branchCount = profile.branches.length;
    final areaText = profile.area.isNotEmpty ? profile.area : 'Main Turf';

    return AppBar(
      backgroundColor: const Color(0xFF090909),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      toolbarHeight: 60,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFF1A1A1A), width: 1),
      ),
      title: Row(
        children: [
          // Sleek Brand Emblem
          InkWell(
            onTap: () => _showBranchSwitcherBottomSheet(context, profile),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF262626), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(5),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/image.png',
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Turf Identity & Modern Branch Switcher
          Expanded(
            child: InkWell(
              onTap: () => _showBranchSwitcherBottomSheet(context, profile),
              borderRadius: BorderRadius.circular(10),
              splashColor: Colors.white.withValues(alpha: 0.05),
              highlightColor: Colors.white.withValues(alpha: 0.03),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            profile.venueName.isNotEmpty
                                ? profile.venueName
                                : 'Turf Partner Hub',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 19,
                          color: Color(0xFFA1A1AA),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 11.5,
                          color: Color(0xFF71717A),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            areaText,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFA1A1AA),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (branchCount > 1) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF162312),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: const Color(0xFF2B4420),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '$branchCount Venues',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF86EFAC),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
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
        // Fast Gate QR Scanner Button (Precision Luxury Style)
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/admin/qr-scanner');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF262626), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFFD4FF00),
                    size: 19,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingAdminApprovalNotice(
    BuildContext context,
    TurfProfileState profile,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF261906), Color(0xFF181005)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Color(0xFFFBBF24),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Branch Pending Super Admin Verification',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Application for "${profile.venueName}" has been submitted to the Super Admin queue. You can configure courts and preview operations. Public player bookings will unlock automatically once verified.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE4E4E7),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showBranchSwitcherBottomSheet(context, profile),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 14,
                          color: Color(0xFFFBBF24),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Switch to Another Branch',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFBBF24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBranchSwitcherBottomSheet(
    BuildContext context,
    TurfProfileState profile,
  ) {
    final cleanPhone = profile.ownerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final ownerLast10 = cleanPhone.length >= 10
        ? cleanPhone.substring(cleanPhone.length - 10)
        : cleanPhone;

    // Deduplicate branches and filter to ensure only this owner's venues are shown
    final Map<String, OwnerTurfBranchItem> deduplicated = {};
    for (final b in profile.branches) {
      if (ownerLast10.isNotEmpty && b.ownerPhone.isNotEmpty) {
        final bClean = b.ownerPhone.replaceAll(RegExp(r'[^0-9]'), '');
        final bLast10 = bClean.length >= 10
            ? bClean.substring(bClean.length - 10)
            : bClean;
        if (bLast10 != ownerLast10 && b.id != profile.verifiedAdminId) {
          continue; // Filter out foreign account branches
        }
      }
      final key = b.venueName.trim().toLowerCase();
      if (!deduplicated.containsKey(key) ||
          (!b.isPending && deduplicated[key]!.isPending)) {
        deduplicated[key] = b;
      }
    }

    final branches = deduplicated.values.isNotEmpty
        ? deduplicated.values.toList()
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
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF262626), width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(ctx).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instagram-style Drag Handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F3F46),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Sheet Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFF22C55E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Turf Branches & Venues',
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E291E),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF2E452E),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '${branches.length} Location${branches.length > 1 ? "s" : ""}',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF86EFAC),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Switch active venue or register a new branch',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFA1A1AA),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF262626),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFA1A1AA),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Connected Branches List (Instagram-Style Cards)
                ...branches.map((b) {
                  final isCurrent = b.id == profile.verifiedAdminId;
                  final isPending =
                      b.isPending || b.status == 'PENDING_APPROVAL';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: isCurrent
                          ? const Color(0xFF142414)
                          : const Color(0xFF18181B),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isCurrent
                              ? const Color(0xFF22C55E)
                              : isPending
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                              : const Color(0xFF27272A),
                          width: isCurrent ? 1.5 : 1.0,
                        ),
                      ),
                      child: InkWell(
                        onTap: () async {
                          if (isCurrent) {
                            Navigator.pop(ctx);
                            return;
                          }
                          HapticFeedback.mediumImpact();
                          Navigator.pop(ctx);
                          await ref
                              .read(turfProfileProvider.notifier)
                              .switchBranch(b.id);
                          if (mounted && context.mounted) {
                            if (isPending) {
                              ToastUtils.showInfo(
                                context,
                                'Switched view to "${b.venueName}" (Under Super Admin Verification)',
                              );
                            } else {
                              ToastUtils.showSuccess(
                                context,
                                'Switched active branch to "${b.venueName}"!',
                              );
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Avatar / Turf Emblem
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? const Color(
                                          0xFF16A34A,
                                        ).withValues(alpha: 0.2)
                                      : const Color(0xFF27272A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCurrent
                                        ? const Color(0xFF22C55E)
                                        : Colors.transparent,
                                    width: 1.2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        Icons.stadium_rounded,
                                        color: isCurrent
                                            ? const Color(0xFF86EFAC)
                                            : const Color(0xFFA1A1AA),
                                        size: 22,
                                      ),
                                    ),
                                    if (isPending)
                                      Positioned(
                                        top: 3,
                                        right: 3,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF59E0B),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                    else if (isCurrent)
                                      Positioned(
                                        top: 3,
                                        right: 3,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF22C55E),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Branch Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            b.venueName,
                                            style: TextStyle(
                                              fontWeight: isCurrent
                                                  ? FontWeight.w900
                                                  : FontWeight.w700,
                                              color: Colors.white,
                                              fontSize: 14.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (isPending)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF382305),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFF784A0A),
                                                width: 0.6,
                                              ),
                                            ),
                                            child: const Text(
                                              'PENDING APPROVAL',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFFFBBF24),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          )
                                        else if (isCurrent)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E3A1E),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFF22C55E),
                                                width: 0.6,
                                              ),
                                            ),
                                            child: const Text(
                                              'ACTIVE',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF86EFAC),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isPending
                                          ? '${b.neighborhoodArea} • Super Admin verification in progress'
                                          : '${b.neighborhoodArea} • Today: ${b.todayBookingsCount} bookings (₹${b.todayRevenue.toInt()})',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isPending
                                            ? const Color(
                                                0xFFFBBF24,
                                              ).withValues(alpha: 0.8)
                                            : const Color(0xFFA1A1AA),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Trailing Indicator (Instagram Checkmark or Switch Pill)
                              if (isCurrent)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF22C55E),
                                  size: 22,
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF27272A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Switch',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE4E4E7),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 10),
                const Divider(color: Color(0xFF27272A), height: 1),
                const SizedBox(height: 14),

                // Action 1: Register New Branch Location (Instagram-style Row)
                Material(
                  color: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFF27272A)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      _showBranchSetupModeDialog(context, profile);
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.add_location_alt_rounded,
                        color: Color(0xFF22C55E),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Register New Branch Location',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: const Text(
                      'Clone current specs or configure a new arena • Admin Approval',
                      style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFA1A1AA),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Action 2: Add Court / Pitch (Same Place)
                Material(
                  color: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFF27272A)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      _showAddCourtSamePlaceDialog(context, profile);
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.sports_soccer_rounded,
                        color: Color(0xFF38BDF8),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Add Court / Pitch to ${profile.venueName}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: const Text(
                      'Multi-sport pricing (Cricket, Football, Pickleball & more)',
                      style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFA1A1AA),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- STEP 1: CHOOSE BRANCH SETUP MODE (CLONE VS NEW) ---
  void _showBranchSetupModeDialog(
    BuildContext context,
    TurfProfileState profile,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF262626), width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.of(ctx).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F3F46),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.hub_rounded,
                        color: Color(0xFF22C55E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Setup New Branch Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Choose how to initialize specifications for this branch',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFA1A1AA),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF262626),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFA1A1AA),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Option A: Use Details from Current Branch (Clone)
                Material(
                  color: const Color(0xFF142414),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(
                      color: Color(0xFF22C55E),
                      width: 1.2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      _showAddBranchFormDialog(context, profile, isClone: true);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF16A34A,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.copy_all_rounded,
                              color: Color(0xFF86EFAC),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Clone Current Branch Details',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13.0,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'RECOMMENDED',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Copies timings (${profile.openingTime} – ${profile.closingTime}), amenities, sports (${profile.sports.map((s) => s.name).join(", ")}), and sport rates from "${profile.venueName}". You only need to enter the new location address & branch name.',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFCBD5E1),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Option B: Enter Brand New Details (Custom Setup)
                Material(
                  color: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(
                      color: Color(0xFF27272A),
                      width: 1.0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      _showAddBranchFormDialog(
                        context,
                        profile,
                        isClone: false,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27272A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_business_rounded,
                              color: Color(0xFFA1A1AA),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enter Brand New Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Start fresh with a clean slate: choose custom sports, independent per-game pricing, different operating schedule, and venue amenities.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFA1A1AA),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- STEP 2: ADD BRANCH FORM WITH PER-GAME PRICING & ADMIN APPROVAL ---
  void _showAddBranchFormDialog(
    BuildContext context,
    TurfProfileState profile, {
    required bool isClone,
  }) {
    final nextBranchNum = profile.branches.length + 1;
    final nameCtrl = TextEditingController(
      text: isClone ? '${profile.venueName} - Branch $nextBranchNum' : '',
    );
    final areaCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final altPhoneCtrl = TextEditingController();

    final allSports = [
      'Cricket',
      'Football',
      'Pickle ball',
      'Badminton',
      'Tennis',
      'Volleyball',
    ];

    final Set<String> selectedSports = isClone
        ? profile.sports.map((s) => s.name).toSet()
        : {'Cricket', 'Football'};
    if (selectedSports.isEmpty) {
      selectedSports.addAll(['Cricket', 'Football']);
    }

    final Map<String, TextEditingController> sportPriceControllers = {};
    for (final sport in allSports) {
      double rate = 1200.0;
      if (sport == 'Cricket') rate = 1000.0;
      if (sport == 'Football') rate = 1200.0;
      if (sport == 'Badminton') rate = 600.0;
      if (sport == 'Pickle ball') rate = 700.0;
      if (sport == 'Tennis') rate = 900.0;
      if (sport == 'Volleyball') rate = 800.0;

      if (isClone) {
        final existing = profile.sports.where((s) => s.name == sport);
        if (existing.isNotEmpty) {
          rate = existing.first.hourlyRate;
        }
      }
      sportPriceControllers[sport] = TextEditingController(
        text: rate.toInt().toString(),
      );
    }

    final List<String> branchPhotos = [];
    bool isUploadingPhoto = false;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          Future<void> pickAndUploadPhoto() async {
            final ImagePicker picker = ImagePicker();
            final List<XFile> images = [];
            try {
              final picked = await picker.pickMultiImage(imageQuality: 85);
              if (picked.isNotEmpty) {
                images.addAll(picked);
              } else {
                final single = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (single != null) images.add(single);
              }
            } catch (e) {
              debugPrint('Image picker error: $e');
            }

            if (images.isEmpty) return;

            setDlgState(() => isUploadingPhoto = true);
            try {
              for (final img in images) {
                final uri = Uri.parse('${ApiConfig.baseUrl}/upload/photo');
                final request = http.MultipartRequest('POST', uri);
                final bytes = await img.readAsBytes();
                final ext = img.name.split('.').last.toLowerCase();
                final mimeSubtype = ext == 'png'
                    ? 'png'
                    : (ext == 'webp' ? 'webp' : 'jpeg');

                request.files.add(
                  http.MultipartFile.fromBytes(
                    'file',
                    bytes,
                    filename: img.name,
                    contentType: MediaType('image', mimeSubtype),
                  ),
                );

                final streamedRes = await request.send();
                final response = await http.Response.fromStream(streamedRes);
                if (response.statusCode == 200 || response.statusCode == 201) {
                  final data = jsonDecode(response.body);
                  final fileUrl = data['url'];
                  if (fileUrl != null &&
                      !branchPhotos.contains(fileUrl.toString())) {
                    setDlgState(() {
                      branchPhotos.add(fileUrl.toString());
                    });
                  }
                }
              }
            } catch (e) {
              debugPrint('Upload photo error: $e');
            } finally {
              setDlgState(() => isUploadingPhoto = false);
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF141414),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF27272A), width: 1),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isClone
                        ? Icons.copy_all_rounded
                        : Icons.add_business_rounded,
                    color: const Color(0xFF22C55E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isClone ? 'Clone to New Branch' : 'Register New Branch',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16.5,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isClone
                            ? 'Pre-filled from ${profile.venueName}'
                            : 'Enter branch location & game pricing',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFA1A1AA),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Mode Indicator Chip
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isClone
                            ? const Color(0xFF162A16)
                            : const Color(0xFF202024),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isClone
                              ? const Color(0xFF2E4D2E)
                              : const Color(0xFF333338),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isClone
                                ? Icons.check_circle_outline_rounded
                                : Icons.info_outline_rounded,
                            size: 14,
                            color: isClone
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFA1A1AA),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isClone
                                  ? 'Timings, surface & specs copied from current venue'
                                  : 'Primary Owner Account: ${profile.ownerPhone}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: isClone
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFD4D4D8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'New Branch Name *',
                        hintText: 'e.g. Vicky Turf - Anna Nagar',
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: areaCtrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Neighborhood / Area *',
                        hintText: 'e.g. Anna Nagar / KK Nagar',
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: addressCtrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Full Street Address *',
                        hintText: 'e.g. 14, 2nd Main Road, Madurai',
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: altPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Manager Mobile Number * (Mandatory)',
                        hintText: '10-digit number for this branch',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Supported Sports Multi-Select
                    const Text(
                      'Supported Sports (Multi-Select) *',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select the sports offered at this branch. Each sport can have its own hourly rate.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: allSports.map((sport) {
                        final isChecked = selectedSports.contains(sport);
                        return FilterChip(
                          label: Text(sport),
                          selected: isChecked,
                          selectedColor: const Color(0xFFD4FF00),
                          checkmarkColor: Colors.black,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isChecked
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: isChecked
                                ? Colors.black
                                : const Color(0xFFE4E4E7),
                          ),
                          side: BorderSide(
                            color: isChecked
                                ? const Color(0xFFD4FF00)
                                : const Color(0xFF333333),
                            width: 1,
                          ),
                          backgroundColor: const Color(0xFF1C1C1C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (selected) {
                            setDlgState(() {
                              if (selected) {
                                selectedSports.add(sport);
                              } else {
                                if (selectedSports.length > 1) {
                                  selectedSports.remove(sport);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // PER-GAME / SPORT SPECIFIC PRICING (User Request!)
                    const Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 15,
                          color: Color(0xFF86EFAC),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Per-Game Hourly Rates (₹)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Set individual rates for each selected sport:',
                      style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                    ),
                    const SizedBox(height: 8),

                    // Individual rate inputs for each selected sport
                    ...selectedSports.map((sport) {
                      final ctrl = sportPriceControllers[sport]!;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2A2A30),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getSportIcon(sport),
                              size: 18,
                              color: const Color(0xFF86EFAC),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                sport,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              height: 38,
                              child: TextField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  prefixStyle: const TextStyle(
                                    color: Color(0xFF86EFAC),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF101014),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF33333A),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF33333A),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF22C55E),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '/hr',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFA1A1AA),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 14),

                    // Branch Venue Photos (Images)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 15,
                              color: Color(0xFF86EFAC),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Branch Venue Photos',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (branchPhotos.isNotEmpty)
                          Text(
                            '${branchPhotos.length} uploaded',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF86EFAC),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Upload photos of your courts, turf pitch, and amenities for player app listing:',
                      style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                    ),
                    const SizedBox(height: 8),

                    // Upload Button / Progress
                    InkWell(
                      onTap: isUploadingPhoto ? null : pickAndUploadPhoto,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161E14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2E4D2E),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isUploadingPhoto) ...[
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF86EFAC),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Uploading Photos...',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF86EFAC),
                                ),
                              ),
                            ] else ...[
                              const Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 18,
                                color: Color(0xFF86EFAC),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                branchPhotos.isEmpty
                                    ? 'Select & Upload Venue Photos'
                                    : 'Add More Photos',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF86EFAC),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Thumbnails row
                    if (branchPhotos.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: branchPhotos.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final photoUrl = branchPhotos[idx];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    photoUrl,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 72,
                                      height: 72,
                                      color: const Color(0xFF202024),
                                      child: const Icon(
                                        Icons.broken_image_rounded,
                                        size: 24,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setDlgState(() {
                                        branchPhotos.removeAt(idx);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Super Admin Approval Requirement Notice
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF281C08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 16,
                            color: Color(0xFFFBBF24),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Super Admin Approval Required: After submission, this branch will be verified by Super Admin for safety & KYC standards before opening player bookings.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFFFDE68A),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgCtx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFFA1A1AA)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4FF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final vName = nameCtrl.text.trim();
                  final vArea = areaCtrl.text.trim();
                  final altPhone = altPhoneCtrl.text.trim().replaceAll(
                    RegExp(r'\D'),
                    '',
                  );

                  if (vName.isEmpty || vArea.isEmpty) {
                    ToastUtils.showError(
                      context,
                      'Please enter branch name and area',
                    );
                    return;
                  }

                  if (altPhone.length < 10) {
                    ToastUtils.showError(
                      context,
                      'Manager mobile number is mandatory (10 digits)',
                    );
                    return;
                  }

                  final primaryDigits = profile.ownerPhone.replaceAll(
                    RegExp(r'\D'),
                    '',
                  );
                  if (primaryDigits.isNotEmpty &&
                      primaryDigits.endsWith(
                        altPhone.length >= 10
                            ? altPhone.substring(altPhone.length - 10)
                            : altPhone,
                      )) {
                    ToastUtils.showError(
                      context,
                      'Manager phone must be different from primary owner phone',
                    );
                    return;
                  }

                  Navigator.pop(dlgCtx);

                  // Collect per-sport prices
                  final Map<String, double> perSportRates = {};
                  for (final sport in selectedSports) {
                    final text =
                        sportPriceControllers[sport]?.text.trim() ?? '';
                    final rate = double.tryParse(text) ?? 1000.0;
                    perSportRates[sport] = rate;
                  }

                  final baseDayRate = perSportRates.values.isNotEmpty
                      ? perSportRates.values.first
                      : 1000.0;

                  final success = await ref
                      .read(turfProfileProvider.notifier)
                      .addNewBranch(
                        venueName: vName,
                        neighborhoodArea: vArea,
                        streetAddress: addressCtrl.text.trim().isNotEmpty
                            ? addressCtrl.text.trim()
                            : vArea,
                        alternativePhone: altPhone,
                        dayRate: baseDayRate,
                        nightRate: baseDayRate + 200,
                        photoUrls: branchPhotos,
                        sports: selectedSports.toList(),
                        sportRates: perSportRates,
                        isCloned: isClone,
                        clonedFromVenue: isClone ? profile.venueName : null,
                      );

                  if (context.mounted) {
                    if (success) {
                      ToastUtils.showSuccess(
                        context,
                        'Branch "$vName" submitted for Super Admin verification!',
                      );
                    } else {
                      ToastUtils.showError(
                        context,
                        'Failed to submit branch application. Please try again.',
                      );
                    }
                  }
                },
                child: const Text(
                  'Submit for Admin Approval',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- ADD COURT / PITCH (SAME PLACE) WITH PER-SPORT PRICING ---
  void _showAddCourtSamePlaceDialog(
    BuildContext context,
    TurfProfileState profile,
  ) {
    final nextNum = profile.courts.length + 1;
    final nameCtrl = TextEditingController(
      text: '${profile.venueName} - Pitch $nextNum',
    );
    final Set<String> selectedSports = {'Cricket', 'Football'};
    final surfaceCtrl = TextEditingController(text: 'Synthetic Grass Turf');

    final sportsOptions = [
      'Cricket',
      'Football',
      'Pickle ball',
      'Badminton',
      'Tennis',
      'Volleyball',
    ];

    // Dynamic per-game pricing controllers
    final Map<String, TextEditingController> sportPriceControllers = {
      'Cricket': TextEditingController(text: '1000'),
      'Football': TextEditingController(text: '1200'),
      'Pickle ball': TextEditingController(text: '700'),
      'Badminton': TextEditingController(text: '600'),
      'Tennis': TextEditingController(text: '900'),
      'Volleyball': TextEditingController(text: '800'),
    };

    // Pre-populate if profile has sports rates
    for (final s in profile.sports) {
      if (sportPriceControllers.containsKey(s.name)) {
        sportPriceControllers[s.name]!.text = s.hourlyRate.toInt().toString();
      }
    }

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF27272A), width: 1),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sports_soccer_rounded,
                  color: Color(0xFF22C55E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Court / Pitch to ${profile.venueName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Add additional courts or pitches in the same venue ground.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: const InputDecoration(
                      labelText: 'Court / Pitch Name *',
                      hintText: 'e.g. Box Arena, Pitch 2, Court B',
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Supported Sports (Multi-Select) *',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Football & Cricket can share the same ground. Badminton & Pickleball require separate court types.',
                    style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sportsOptions.map((sport) {
                      final isChecked = selectedSports.contains(sport);
                      return FilterChip(
                        label: Text(sport),
                        selected: isChecked,
                        selectedColor: const Color(0xFFD4FF00),
                        checkmarkColor: Colors.black,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isChecked
                              ? FontWeight.w900
                              : FontWeight.w600,
                          color: isChecked
                              ? Colors.black
                              : const Color(0xFFE4E4E7),
                        ),
                        side: BorderSide(
                          color: isChecked
                              ? const Color(0xFFD4FF00)
                              : const Color(0xFF333333),
                          width: 1,
                        ),
                        backgroundColor: const Color(0xFF1C1C1C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (selected) {
                          setDlgState(() {
                            if (selected) {
                              selectedSports.add(sport);
                            } else {
                              if (selectedSports.length > 1) {
                                selectedSports.remove(sport);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: surfaceCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: const InputDecoration(
                      labelText: 'Surface Type',
                      hintText:
                          'e.g. Synthetic Grass Turf, Astro Turf, Hard Court',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // DYNAMIC PER-GAME PRICING SECTION
                  const Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 15,
                        color: Color(0xFF86EFAC),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Per-Game Hourly Rates (₹) *',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Configure specific pricing for each game played on this court:',
                    style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                  ),
                  const SizedBox(height: 8),

                  ...selectedSports.map((sport) {
                    final ctrl = sportPriceControllers[sport]!;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF2A2A30),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getSportIcon(sport),
                            size: 18,
                            color: const Color(0xFF86EFAC),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              sport,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            height: 38,
                            child: TextField(
                              controller: ctrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                prefixStyle: const TextStyle(
                                  color: Color(0xFF86EFAC),
                                  fontWeight: FontWeight.bold,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF101014),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF33333A),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF33333A),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '/hr',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFA1A1AA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFA1A1AA)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4FF00),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final cName = nameCtrl.text.trim();
                if (cName.isEmpty) {
                  ToastUtils.showError(context, 'Please enter a court name');
                  return;
                }
                if (selectedSports.isEmpty) {
                  ToastUtils.showError(
                    context,
                    'Please select at least one sport',
                  );
                  return;
                }
                Navigator.pop(dlgCtx);

                // Collect per-sport rates
                final Map<String, double> perSportRates = {};
                for (final sport in selectedSports) {
                  final text = sportPriceControllers[sport]?.text.trim() ?? '';
                  final rate = double.tryParse(text) ?? 1000.0;
                  perSportRates[sport] = rate;
                }

                final sportsList = selectedSports.toList();
                final baseRate = perSportRates.values.isNotEmpty
                    ? perSportRates.values.first
                    : 1200.0;

                final newCourt = TurfCourtVenueItem(
                  id: 'CRT-${profile.turfId}-${DateTime.now().millisecondsSinceEpoch % 100000}',
                  name: cName,
                  sport: sportsList.join(' • '),
                  sports: sportsList,
                  surface: surfaceCtrl.text.trim().isNotEmpty
                      ? surfaceCtrl.text.trim()
                      : 'Turf Surface',
                  hourlyRate: baseRate,
                  sportRates: perSportRates,
                  timings: '06:00 AM - 11:00 PM',
                  description: 'Court at ${profile.venueName}',
                );

                ref.read(turfProfileProvider.notifier).addCourtVenue(newCourt);
                if (context.mounted) {
                  ToastUtils.showSuccess(
                    context,
                    'Court "$cName" added with sport-specific rates!',
                  );
                }
              },
              child: const Text(
                'Add Court',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. SUBSCRIPTION CARD (URGENT ALERT vs SLEEK MEMBERSHIP PILL) ---
  Widget _buildSubscriptionCard(
    BuildContext context,
    TurfProfileState profile,
  ) {
    if (profile.isSubscriptionEndingSoon) {
      // Urgent Renewal Banner
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF241A04), Color(0xFF2D2005)],
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
                  child: const Icon(
                    Icons.timer_outlined,
                    color: Color(0xFF141414),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription Expires in ${profile.subscriptionDaysRemaining} Day(s)',
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
                      color: Color(0xFFFDE68A),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.bolt_rounded, size: 14),
                    label: const Text(
                      'Renew Now',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
          colors: [
            Color(0xFF131710),
            Color(0xFF192215),
            Color(0xFF22321C),
            Color(0xFF2D4224),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B522E), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFBBF24),
              size: 18,
            ),
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
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD4FF00),
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
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 9,
                  ),
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
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final isPending =
        profile.branchStatus == 'PENDING_APPROVAL' ||
        (profile.verifiedAdminId ?? 0) < 0;
    final allList = isPending
        ? <TurfBookingHistoryItem>[]
        : _getAllBookingsSource(profile);

    // Dynamic metrics strictly based on actual bookings for this selected branch
    final cancelledList = allList.where((b) => b.isCancelled).toList();
    final dynamicCancelledCount = cancelledList.length > profile.cancelledCount
        ? cancelledList.length
        : profile.cancelledCount;
    final dynamicShiftedCount = isPending ? 0 : profile.shiftedCount;
    final dynamicCancelledTotal = isPending
        ? 0
        : (dynamicCancelledCount + dynamicShiftedCount);

    // Active (non-cancelled) bookings for today for this branch
    final activeTodayList = allList.where((b) {
      if (b.isCancelled) return false;
      final d = b.effectiveDate;
      return d == todayStr || d.toLowerCase() == 'today';
    }).toList();

    final activeMonthList = allList.where((b) => !b.isCancelled).toList();
    final dynamicTodayRev = isPending
        ? 0.0
        : (profile.todayRevenue > 0
              ? profile.todayRevenue
              : activeTodayList.fold<double>(0.0, (sum, b) => sum + b.amount));
    final dynamicMonthRev = isPending
        ? 0.0
        : (profile.monthRevenue > 0
              ? profile.monthRevenue
              : activeMonthList.fold<double>(0.0, (sum, b) => sum + b.amount));
    final monthTarget = profile.monthlyRevenueTarget > 0
        ? profile.monthlyRevenueTarget
        : 50000.0;
    final targetPct = isPending
        ? 0
        : ((dynamicMonthRev / monthTarget).clamp(0.0, 1.0) * 100).toInt();

    final operatingSlots = isPending
        ? <String>[]
        : AppConstants.generateTimeSlots(
            profile.openingTime.isNotEmpty ? profile.openingTime : '05:00 AM',
            profile.closingTime.isNotEmpty ? profile.closingTime : '11:00 PM',
          );
    final totalDailySlots = operatingSlots.length;

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
      final startMin = TurfBookingHistoryItem.parseSlotStartMinutes(
        b.effectiveTimeSlot,
      );
      if (startMin == -1 || currentMinutes < startMin) {
        final slotStr = b.effectiveTimeSlot;
        if (slotStr.isNotEmpty) {
          final slots = slotStr
              .split(',')
              .map((x) => x.trim())
              .where((x) => x.isNotEmpty)
              .toList();
          upcomingBookedSlots += slots.isNotEmpty ? slots.length : 1;
        } else {
          upcomingBookedSlots += 1;
        }
      }
    }

    final dynamicRemainingSlots = isPending
        ? 0
        : ((totalDailySlots -
                      passedSlotsCount -
                      upcomingBookedSlots -
                      profile.blockedSlotsCount) >
                  0
              ? (totalDailySlots -
                    passedSlotsCount -
                    upcomingBookedSlots -
                    profile.blockedSlotsCount)
              : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Metric Card: Monthly Revenue GMV (Stadium Box Office Pass)
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF141414), Color(0xFF181818), Color(0xFF1D2808)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFFD4FF00).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4FF00).withValues(alpha: 0.12),
                blurRadius: 16,
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
                  child: CustomPaint(painter: _TurfPitchMarkingsPainter()),
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
                              color: const Color(
                                0xFFD4FF00,
                              ).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.currency_rupee_rounded,
                              color: Color(0xFFD4FF00),
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'MONTHLY REVENUE (GMV)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD4FF00),
                                letterSpacing: 0.6,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF333333),
                              ),
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
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: dynamicMonthRev > 0
                              ? (dynamicMonthRev / monthTarget).clamp(0.05, 1.0)
                              : 0.05,
                          minHeight: 5.5,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFD4FF00),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$targetPct% of Monthly Target Met',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _showEditMonthlyTargetDialog(profile),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Target ${_formatTargetLabel(monthTarget)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.edit_rounded,
                                    size: 10,
                                    color: Color(0xFFD4FF00),
                                  ),
                                ],
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
          ),
        ),
        const SizedBox(height: 12),

        // 2x2 Operational Metric Pods (Today's Collection, Available Slots, Upcoming Bookings, Cancellations)
        Row(
          children: [
            // 1. Today's Collection
            _buildDashboardMetricTile(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFFD4FF00),
              title: "Today's Collection",
              valueWidget: Text(
                '₹${NumberFormat('#,##,###').format(dynamicTodayRev.toInt())}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD4FF00),
                  letterSpacing: -0.5,
                ),
              ),
              arrowColor: const Color(0xFFD4FF00),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedFilter = 'All';
                });
              },
            ),
            const SizedBox(width: 10),

            // 2. Available Slots
            _buildDashboardMetricTile(
              icon: Icons.calendar_month_rounded,
              iconColor: const Color(0xFF38BDF8),
              title: "Available Slots",
              valueWidget: Text(
                '$dynamicRemainingSlots',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              arrowColor: const Color(0xFF38BDF8),
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/admin/slots');
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            // 3. Upcoming Bookings
            _buildDashboardMetricTile(
              icon: Icons.event_available_rounded,
              iconColor: const Color(0xFFFBBF24),
              title: "Upcoming Bookings",
              valueWidget: Text(
                '${isPending ? 0 : allList.where((b) => b.isUpcoming(now)).length}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              arrowColor: const Color(0xFFFBBF24),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedFilter = 'Upcoming';
                });
              },
            ),
            const SizedBox(width: 10),

            // 4. Cancellations
            _buildDashboardMetricTile(
              icon: Icons.cancel_outlined,
              iconColor: const Color(0xFFEF4444),
              title: "Cancellations",
              valueWidget: Text(
                '${isPending ? 0 : dynamicCancelledTotal}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              arrowColor: const Color(0xFFEF4444),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedFilter = 'Cancelled';
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Compact, modern operational metric pod for the 2x2 Command Centre grid
  Widget _buildDashboardMetricTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget valueWidget,
    required Color arrowColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: iconColor.withValues(alpha: 0.12),
          highlightColor: iconColor.withValues(alpha: 0.06),
          child: Ink(
            height: 96,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141415),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF262626), width: 1.0),
              gradient: RadialGradient(
                center: const Alignment(-0.8, -0.8),
                radius: 1.4,
                colors: [
                  iconColor.withValues(alpha: 0.08),
                  const Color(0xFF141415),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD4D4D8),
                          letterSpacing: -0.2,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    valueWidget,
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: arrowColor,
                      size: 17,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 5. BROADCAST MATCHDAY SPOTLIGHT ---
  Widget? _buildMatchSpotlightBanner(
    BuildContext context,
    TurfProfileState profile,
  ) {
    // Do NOT show upcoming matches in this spotlight banner
    // Do NOT show when 'Upcoming' tab is selected
    if (_selectedFilter == 'Upcoming' ||
        (_selectedFilter != 'All' && _selectedFilter != 'Live Now')) {
      return null;
    }

    final now = DateTime.now();
    final allList = _getAllBookingsSource(profile);
    final liveMatches = allList
        .where((b) => !b.isCancelled && b.isLiveNow(now))
        .toList();

    // Upcoming matches must not show here; only an active live match currently in progress
    if (liveMatches.isEmpty) return null;

    final spotlight = liveMatches.first;

    final isLive = spotlight.isLiveNow(now);
    final sportColor = _getSportColor(spotlight.sport);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLive
              ? const Color(0xFF16A34A)
              : const Color(0xFFD4FF00).withValues(alpha: 0.2),
          width: isLive ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                : const Color(0xFFD4FF00).withValues(alpha: 0.06),
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
                      ? [const Color(0xFF141414), const Color(0xFF16A34A)]
                      : [const Color(0xFF111E13), const Color(0xFF1C381F)],
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
                          color: isLive
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLive ? 'LIVE MATCH IN PROGRESS' : 'NEXT UP ON COURT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isLive
                              ? const Color(0xFF86EFAC)
                              : Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
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
                          spotlight.customerName.isNotEmpty
                              ? spotlight.customerName[0].toUpperCase()
                              : 'P',
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
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  _getSportIcon(spotlight.sport),
                                  size: 13,
                                  color: _getSportColor(spotlight.sport),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${spotlight.sport} • ${spotlight.courtName}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFA1A1AA),
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
                              color: Color(0xFFD4FF00),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            spotlight.paymentMethod.toUpperCase().contains(
                                  'CASH',
                                )
                                ? 'Pay at Venue'
                                : 'Paid Online',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color:
                                  spotlight.paymentMethod
                                      .toUpperCase()
                                      .contains('CASH')
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFFD4FF00),
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
                        backgroundColor: const Color(0xFFD4FF00),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'View Match Pass & Check-In',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      onPressed: () =>
                          _openBookingDetailsSheet(context, spotlight),
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
    final notVisitedCount = allList.where((b) => b.isNotVisited(now)).length;
    final cancelledCount = allList
        .where((b) => b.status.toLowerCase() == 'cancelled')
        .length;

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
                  color: Colors.white,
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'All Slots',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14),
                ],
              ),
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
              if (notVisitedCount > 0) ...[
                const SizedBox(width: 8),
                _buildFilterPill('Not Visited', notVisitedCount),
              ],
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
          color: isSelected ? const Color(0xFFD4FF00) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4FF00)
                : const Color(0xFF262626),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4FF00).withValues(alpha: 0.3),
                    blurRadius: 6,
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
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Colors.black : const Color(0xFFA1A1AA),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.black.withValues(alpha: 0.18)
                    : const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? Colors.black : const Color(0xFFA1A1AA),
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
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr =
        "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

    String dateLabel = booking.effectiveDate;
    if (dateLabel == todayStr || dateLabel.toLowerCase() == 'today') {
      dateLabel = 'Today';
    } else if (dateLabel == tomorrowStr ||
        dateLabel.toLowerCase() == 'tomorrow') {
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
    final slotList = slotStr
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 3,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 11,
                  color: Color(0xFFA1A1AA),
                ),
                const SizedBox(width: 4),
                Text(
                  dateLabel.isNotEmpty ? dateLabel : 'Today',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (slotList.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4FF00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${slotList.length} Slots (${slotList.length} hrs)',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD4FF00),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        if (slotList.length <= 1)
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 11.5,
                color: Color(0xFFD4FF00),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  slotStr.isNotEmpty ? slotStr : 'Time slot confirmed',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD4FF00),
                  ),
                ),
              ),
            ],
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: slotList
                .map(
                  (slot) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF262626)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 9.5,
                          color: Color(0xFFE4E4E7),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            slot,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildProBookingCard(
    BuildContext context,
    TurfBookingHistoryItem booking,
  ) {
    return _TearableBookingCard(
      booking: booking,
      sportColor: _getSportColor(booking.sport),
      sportIcon: _getSportIcon(booking.sport),
      scheduleWidget: _buildBookingScheduleDisplay(booking),
      onOpenDetails: () => _openBookingDetailsSheet(context, booking),
      onCall: () {
        if (booking.customerPhone.isNotEmpty) {
          PhoneDialer.call(
            context,
            booking.customerPhone,
            customerName: booking.customerName,
          );
        } else {
          ToastUtils.showError(
            context,
            'No contact number available for this player',
          );
        }
      },
    );
  }

  void _openBookingDetailsSheet(
    BuildContext context,
    TurfBookingHistoryItem booking,
  ) {
    final now = DateTime.now();
    final isCompleted = booking.isCompleted(now);
    final isNotVisited = booking.isNotVisited(now);
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
          color: Color(0xFF141414),
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
                      color: const Color(0xFF262626),
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
                              color: const Color(
                                0xFFD4FF00,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.confirmation_number_rounded,
                              color: Color(0xFFD4FF00),
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
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${booking.sport} • ${booking.courtName}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFFA1A1AA),
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
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFA1A1AA),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Matchday Ticket Pass Structure
                _buildTicketDetailsBox(
                  context,
                  booking,
                  isCompleted: isCompleted,
                  isNotVisited: isNotVisited,
                  isCancelled: isCancelled,
                ),
                const SizedBox(height: 20),

                // Operational Action Buttons
                if (!isCancelled && !isCompleted && !isNotVisited) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4FF00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 18,
                        color: Colors.black,
                      ),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Gate Check-in (Open Scanner)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
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
                        foregroundColor: const Color(0xFFE4E4E7),
                        side: const BorderSide(color: Color(0xFF262626)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.published_with_changes_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Alter / Shift Slot',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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
                        backgroundColor: const Color(0xFFD4FF00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 18,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Open Gate Scanner',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
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

  Widget _buildTicketDetailsBox(
    BuildContext context,
    TurfBookingHistoryItem booking, {
    required bool isCompleted,
    required bool isNotVisited,
    required bool isCancelled,
  }) {
    final sportColor = _getSportColor(booking.sport);
    final isCheckedIn =
        booking.status.toLowerCase().contains('check') ||
        booking.status.toLowerCase() == 'checked in';
    final isLiveNow = booking.isLiveNow(DateTime.now());

    // Status Pill
    Color statusBgColor;
    Color statusTextColor;
    String statusDisplay;
    IconData statusIcon;

    if (isCancelled) {
      statusBgColor = const Color(0xFF2A0D12);
      statusTextColor = const Color(0xFFF87171);
      statusDisplay = 'CANCELLED';
      statusIcon = Icons.cancel_outlined;
    } else if (isNotVisited) {
      statusBgColor = const Color(0xFF2A0D12);
      statusTextColor = const Color(0xFFFB7185);
      statusDisplay = 'THEY NOT VISIT THE TURF';
      statusIcon = Icons.person_off_rounded;
    } else if (isCompleted) {
      statusBgColor = const Color(0xFF1C1C1C);
      statusTextColor = const Color(0xFFA1A1AA);
      statusDisplay = 'COMPLETED';
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (isCheckedIn) {
      statusBgColor = const Color(0xFF1A2A04);
      statusTextColor = const Color(0xFFD4FF00);
      statusDisplay = 'CHECKED IN';
      statusIcon = Icons.verified_rounded;
    } else if (isLiveNow) {
      statusBgColor = const Color(0xFF1A2A04);
      statusTextColor = const Color(0xFFD4FF00);
      statusDisplay = 'LIVE NOW';
      statusIcon = Icons.sensors_rounded;
    } else {
      statusBgColor = const Color(0xFF0C2040);
      statusTextColor = const Color(0xFF60A5FA);
      statusDisplay = 'CONFIRMED';
      statusIcon = Icons.check_circle_rounded;
    }

    final dateStr = booking.effectiveDate.isNotEmpty
        ? booking.effectiveDate
        : (booking.date.isNotEmpty ? booking.date : 'Today');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF262626), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4FF00).withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. TICKET HEADER STUB (Emerald Sports Pass Banner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF141414), Color(0xFF1D2808)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getSportIcon(booking.sport),
                      size: 18,
                      color: _getSportColor(booking.sport),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OFFICIAL MATCH PASS',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Color(0xFFD4FF00),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${booking.sport} • ${booking.courtName}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFD4FF00).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      booking.id,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD4FF00),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. TICKET BODY: ATTENDEE & FIXTURE
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer & Contact Row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: sportColor.withValues(alpha: 0.12),
                        child: Text(
                          booking.customerName.isNotEmpty
                              ? booking.customerName[0].toUpperCase()
                              : 'P',
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
                              booking.customerName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.customerPhone.isNotEmpty
                                  ? booking.customerPhone
                                  : 'Contact not provided',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFA1A1AA),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (booking.customerPhone.isNotEmpty)
                        InkWell(
                          onTap: () {
                            PhoneDialer.call(
                              context,
                              booking.customerPhone,
                              customerName: booking.customerName,
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF132204),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF262626),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.call_rounded,
                                  size: 13,
                                  color: Color(0xFFD4FF00),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD4FF00),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Prominent Fixture Card (Date & Time Ticket Stub)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF262626)),
                    ),
                    child: Row(
                      children: [
                        // Date column
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFD4FF00,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 15,
                                  color: Color(0xFFD4FF00),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'DATE',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: Color(0xFF71717A),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
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
                        // Vertical dividing line
                        Container(
                          width: 1,
                          height: 32,
                          color: const Color(0xFF262626),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        // Time column
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFD4FF00,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.access_time_rounded,
                                  size: 15,
                                  color: Color(0xFFD4FF00),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TIME SLOT',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: Color(0xFF71717A),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      booking.effectiveTimeSlot,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFD4FF00),
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
                      ],
                    ),
                  ),

                  // Team / Open Match challenge pill if applicable
                  if (booking.teamName != null &&
                      booking.teamName!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF241014),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF5C1D24)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sports_mma_rounded,
                            size: 14,
                            color: Color(0xFFF87171),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'TEAM MATCH: ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF87171),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              booking.teamName!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 3. AUTHENTIC TICKET PERFORATION LINE WITH SIDE NOTCHES
            SizedBox(
              height: 22,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dashed tear line across the middle
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const dashWidth = 5.0;
                            const dashSpace = 4.0;
                            final dashCount =
                                (constraints.constrainWidth() /
                                        (dashWidth + dashSpace))
                                    .floor();
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                dashCount,
                                (_) => const SizedBox(
                                  width: dashWidth,
                                  height: 1.5,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // Left semicircular punch notch
                  Positioned(
                    left: -1,
                    child: Container(
                      width: 12,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(11),
                        ),
                      ),
                    ),
                  ),
                  // Right semicircular punch notch
                  Positioned(
                    right: -1,
                    child: Container(
                      width: 12,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. TICKET LOWER STUB: PAYMENT, AMOUNT & BARCODE
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              color: const Color(0xFF101010),
              child: Column(
                children: [
                  // Payment mode & Amount Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PAYMENT MODE',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Color(0xFFA1A1AA),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                booking.paymentMethod.toUpperCase().contains(
                                      'CASH',
                                    )
                                    ? Icons.payments_rounded
                                    : Icons.account_balance_wallet_rounded,
                                size: 14,
                                color: const Color(0xFFD4FF00),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                booking.paymentMethod,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'TOTAL FARE',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Color(0xFFA1A1AA),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${booking.amount.toInt()}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD4FF00),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status Pill & Verification Barcode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusTextColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 13, color: statusTextColor),
                            const SizedBox(width: 5),
                            Text(
                              statusDisplay,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: statusTextColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Decorative Optical Barcode Graphic
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildDecorativeBarcode(height: 18),
                          const SizedBox(height: 3),
                          Text(
                            '* ${booking.id} *',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              letterSpacing: 1.5,
                              color: Color(0xFFA1A1AA),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeBarcode({double height = 18}) {
    const barWidths = [
      2.0,
      1.0,
      3.0,
      1.5,
      4.0,
      1.0,
      2.5,
      1.5,
      3.5,
      1.0,
      2.0,
      4.0,
      1.5,
      2.5,
      1.0,
      3.0,
      1.5,
      2.0,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: barWidths.map((w) {
        return Container(
          width: w,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1.0),
          decoration: BoxDecoration(
            color: const Color(0xFF71717A),
            borderRadius: BorderRadius.circular(0.5),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyBookingsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1C),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 28,
              color: Color(0xFFA1A1AA),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedFilter == 'Upcoming'
                ? 'No more upcoming bookings today'
                : 'No matching bookings in "$_selectedFilter"',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedFilter == 'Upcoming'
                ? 'All earlier scheduled matches for today are completed. Courts are ready for fresh walk-ins!'
                : 'All courts are open for reservations. You can create offline walk-in bookings anytime.',
            style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<TurfBookingHistoryItem> _getAllBookingsSource(TurfProfileState profile) {
    if (profile.branchStatus == 'PENDING_APPROVAL' ||
        (profile.verifiedAdminId ?? 0) < 0) {
      return const [];
    }
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
    } else if (_selectedFilter == 'Not Visited') {
      return source.where((b) => b.isNotVisited(now)).toList();
    } else if (_selectedFilter == 'Cancelled') {
      return source
          .where((b) => b.status.toLowerCase() == 'cancelled')
          .toList();
    }
    return source;
  }

  IconData _getSportIcon(String sport) {
    final lower = sport.toLowerCase();
    if (lower.contains('cricket')) return Icons.sports_cricket_rounded;
    if (lower.contains('foot') || lower.contains('soccer')) {
      return Icons.sports_soccer_rounded;
    }
    if (lower.contains('badminton')) return Icons.sports_tennis_rounded;
    if (lower.contains('pickle')) return Icons.sports_tennis_rounded;
    if (lower.contains('tennis')) return Icons.sports_tennis_rounded;
    if (lower.contains('basket')) return Icons.sports_basketball_rounded;
    if (lower.contains('volley')) return Icons.sports_volleyball_rounded;
    return Icons.sports_rounded;
  }

  Color _getSportColor(String sport) {
    final lower = sport.toLowerCase();
    if (lower.contains('cricket')) return const Color(0xFFD97706); // Warm Amber
    if (lower.contains('foot') || lower.contains('soccer')) {
      return const Color(0xFFD4FF00); // Grass Emerald
    }
    if (lower.contains('badminton')) {
      return const Color(0xFF4338CA); // Court Indigo
    }
    if (lower.contains('pickle')) return const Color(0xFF0284C7); // Cyan
    if (lower.contains('tennis')) return const Color(0xFF65A30D); // Tennis Lime
    if (lower.contains('basket')) return const Color(0xFFEA580C); // Warm Orange
    return const Color(0xFFD4FF00);
  }

  // --- 8. BLOCKED ACCESS SCAFFOLD ---
  Widget _buildBlockedAccessScaffold(
    BuildContext context,
    TurfProfileState profile,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.stadium_rounded, color: Color(0xFFD4FF00), size: 24),
            SizedBox(width: 8),
            Text(
              'Gamez24 Partner Hub',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
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
              child: Icon(
                Icons.logout_rounded,
                color: Colors.red.shade700,
                size: 18,
              ),
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
                child: const Icon(
                  Icons.lock_clock_rounded,
                  size: 48,
                  color: Color(0xFFDC2626),
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
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
                'Your monthly platform subscription for "${profile.venueName.isNotEmpty ? profile.venueName : 'Your Turf'}" has ended.\n\nYour venue is currently HIDDEN from players on the Gamez24 Player App and owner hub access is locked until renewed.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Fee breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF262626)),
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
                        Text(
                          'Platform Listing Fee',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        Text(
                          '₹1,000.00',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Applicable GST (18%)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        Text(
                          '₹180.00',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount Due',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '₹1,180 / month',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD4FF00),
                          ),
                        ),
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
                    backgroundColor: const Color(0xFFD4FF00),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 20),
                  label: const Text(
                    'Pay ₹1,180 & Unlock Access Now',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () async {
                    final success = await ref
                        .read(turfProfileProvider.notifier)
                        .payPlatformSubscription();
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  ref
                      .read(turfProfileProvider.notifier)
                      .setSubscriptionDays(30);
                  ToastUtils.showSuccess(
                    context,
                    "Testing: Subscription reset to Active (30 days remaining).",
                  );
                },
                child: const Text(
                  'Quick Test: Unlock for 30 Days (Demo)',
                  style: TextStyle(fontSize: 12),
                ),
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
                color: const Color(0xFFD4FF00).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFD4FF00),
                size: 22,
              ),
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
              'Gamez24 operates on a zero-convenience fee model for players. Turf owners subscribe monthly to list their turf and accept live bookings.',
              style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        child: Text(
                          'Monthly Listing Fee',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                      Text(
                        '₹1,000.00',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        child: Text(
                          'GST (18% Applicable)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                      Text(
                        '₹180.00',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        child: Text(
                          'Total Subscription Due',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '₹1,180 / mo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD4FF00),
                        ),
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
                  profile.isSubscriptionActive
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: profile.isSubscriptionActive
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
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
                      color: profile.isSubscriptionActive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
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
                  backgroundColor: const Color(0xFFD4FF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: Text(
                  profile.isSubscriptionActive
                      ? 'Renew Platform Plan (₹1,180)'
                      : 'Pay ₹1,180 & Activate Turf',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await ref
                      .read(turfProfileProvider.notifier)
                      .payPlatformSubscription();
                  if (context.mounted) {
                    if (success) {
                      ToastUtils.showSuccess(
                        context,
                        "Monthly subscription of ₹1,180 paid! Your turf is now LIVE and visible on Gamez24 Player App.",
                      );
                    } else {
                      ToastUtils.showError(
                        context,
                        "Payment failed. Please retry.",
                      );
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
                  await ref
                      .read(turfProfileProvider.notifier)
                      .toggleSubscription();
                  if (context.mounted) {
                    final isNowActive = ref
                        .read(turfProfileProvider)
                        .isSubscriptionActive;
                    if (isNowActive) {
                      ToastUtils.showSuccess(
                        context,
                        "Subscription ACTIVE: Turf is now visible on Player App!",
                      );
                    } else {
                      ToastUtils.showWarning(
                        context,
                        "Subscription HOLD: Turf is now HIDDEN from Player App!",
                      );
                    }
                  }
                },
                child: Text(
                  profile.isSubscriptionActive
                      ? 'Test Deactivate / Hide Turf'
                      : 'Test Activate Turf',
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
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of the Partner Hub?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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

  void _showEditMonthlyTargetDialog(TurfProfileState profile) {
    final currentTarget = profile.monthlyRevenueTarget > 0
        ? profile.monthlyRevenueTarget
        : 50000.0;
    final controller = TextEditingController(
      text: currentTarget.toInt().toString(),
    );
    final quickPresets = [25000, 50000, 75000, 100000, 150000, 200000];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.track_changes_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Set Monthly Target',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set your monthly revenue milestone to track your venue performance and occupancy goals.',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Monthly Revenue Target',
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                      helperText: 'E.g., 50000 for ₹50k, 100000 for ₹1 Lakh',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quick Presets:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickPresets.map((preset) {
                      final isSelected =
                          controller.text.trim() == preset.toString();
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            controller.text = preset.toString();
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.text.length),
                            );
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            _formatTargetLabel(preset.toDouble()),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? Colors.black
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                onPressed: () {
                  final text = controller.text
                      .trim()
                      .replaceAll(',', '')
                      .replaceAll('₹', '');
                  final val = double.tryParse(text);
                  if (val == null || val <= 0) {
                    ToastUtils.showError(
                      context,
                      'Please enter a valid target amount',
                    );
                    return;
                  }
                  ref
                      .read(turfProfileProvider.notifier)
                      .updateMonthlyRevenueTarget(val);
                  Navigator.pop(ctx);
                  ToastUtils.showSuccess(
                    context,
                    'Monthly target updated to ${_formatTargetLabel(val)}!',
                  );
                },
                child: const Text('Save Target'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTargetLabel(double target) {
    if (target >= 100000) {
      final lakhs = target / 100000.0;
      return lakhs == lakhs.roundToDouble()
          ? '₹${lakhs.toInt()}L'
          : '₹${lakhs.toStringAsFixed(1)}L';
    } else if (target >= 1000) {
      final k = target / 1000.0;
      return k == k.roundToDouble()
          ? '₹${k.toInt()}k'
          : '₹${k.toStringAsFixed(1)}k';
    }
    return '₹${target.toInt()}';
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

/// Interactive stadium match pass ticket card featuring a physical tear animation
/// along the perforated tear zone when tapping "Pass & Actions" or the card.
class _TearableBookingCard extends StatefulWidget {
  final TurfBookingHistoryItem booking;
  final Color sportColor;
  final IconData sportIcon;
  final Widget scheduleWidget;
  final VoidCallback onOpenDetails;
  final VoidCallback onCall;

  const _TearableBookingCard({
    required this.booking,
    required this.sportColor,
    required this.sportIcon,
    required this.scheduleWidget,
    required this.onOpenDetails,
    required this.onCall,
  });

  @override
  State<_TearableBookingCard> createState() => _TearableBookingCardState();
}

class _TearableBookingCardState extends State<_TearableBookingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tearController;
  late final Animation<double> _tearAnimation;
  bool _isTearing = false;

  @override
  void initState() {
    super.initState();
    _tearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _tearAnimation = CurvedAnimation(
      parent: _tearController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _tearController.dispose();
    super.dispose();
  }

  void _triggerTear() {
    if (_isTearing) return;

    final now = DateTime.now();
    final isCompleted = widget.booking.isCompleted(now);
    final isNotVisited = widget.booking.isNotVisited(now);
    final isCancelled = widget.booking.status.toLowerCase() == 'cancelled';

    // If match is already closed, cancelled, or player did not visit, open modal directly without tear
    if (isCompleted || isCancelled || isNotVisited) {
      widget.onOpenDetails();
      return;
    }

    setState(() => _isTearing = true);

    // Haptic Phase 1: initial paper-edge snip
    HapticFeedback.lightImpact();

    _tearController.forward(from: 0.0);

    // Haptic Phase 2: mid-tear perforation click
    Future.delayed(const Duration(milliseconds: 130), () {
      if (mounted) HapticFeedback.selectionClick();
    });

    // Haptic Phase 3: paper-tear separation snap
    Future.delayed(const Duration(milliseconds: 270), () {
      if (mounted) HapticFeedback.mediumImpact();
    });

    // Launch Match Pass bottom sheet after tear completes
    Future.delayed(const Duration(milliseconds: 360), () {
      if (!mounted) return;
      widget.onOpenDetails();

      // Reset card after modal is open
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _tearController.reset();
          setState(() => _isTearing = false);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCompleted = widget.booking.isCompleted(now);
    final isNotVisited = widget.booking.isNotVisited(now);
    final isLiveNow = widget.booking.isLiveNow(now);
    final isCancelled = widget.booking.status.toLowerCase() == 'cancelled';
    final isUpi =
        widget.booking.paymentMethod.toUpperCase().contains('UPI') ||
        widget.booking.paymentMethod.toUpperCase().contains('GPAY');

    // Dynamic Pill Badge Styling
    Color badgeTextColor;
    String badgeLabel;

    if (isCancelled) {
      badgeTextColor = const Color(0xFFFB7185);
      badgeLabel = 'CANCELLED';
    } else if (isNotVisited) {
      badgeTextColor = const Color(0xFFFB7185);
      badgeLabel = 'THEY NOT VISIT THE TURF';
    } else if (isCompleted) {
      badgeTextColor = const Color(0xFFA1A1AA);
      badgeLabel = 'COMPLETED';
    } else if (isLiveNow) {
      badgeTextColor = const Color(0xFFD4FF00);
      badgeLabel = widget.booking.status.toLowerCase() == 'checked in'
          ? 'CHECKED IN (LIVE)'
          : 'LIVE NOW';
    } else {
      badgeTextColor = isUpi
          ? const Color(0xFFD4FF00)
          : const Color(0xFFFBBF24);
      badgeLabel = isUpi ? 'PAID ONLINE' : 'PAY AT VENUE';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLiveNow
              ? const [Color(0xFF172412), Color(0xFF10160D), Color(0xFF0C100A)]
              : const [Color(0xFF181A15), Color(0xFF12140F), Color(0xFF0E0F0C)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLiveNow
              ? const Color(0xFF22C55E).withValues(alpha: 0.8)
              : const Color(0xFF262C20),
          width: isLiveNow ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLiveNow
                ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: isLiveNow ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            // Background sport watermark
            Positioned(
              right: 14,
              top: 24,
              child: IgnorePointer(
                child: Icon(
                  widget.sportIcon,
                  size: 64,
                  color: widget.sportColor.withValues(alpha: 0.04),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(19),
                onTap: _triggerTear,
                child: AnimatedBuilder(
                  animation: _tearAnimation,
                  builder: (context, _) {
                    final progress = _tearAnimation.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Top Section (Match Header & Player Info)
                        _buildTopStub(
                          isCompleted,
                          isLiveNow,
                          isUpi,
                          badgeTextColor,
                          badgeLabel,
                        ),

                        // 2. Perforated Tear Line with Dynamic Rip Effect & Spark
                        _buildPerforationDivider(progress),

                        // 3. Bottom Stub (Actions & Buttons) with Tear Physics
                        Transform.translate(
                          offset: Offset(0, progress * 8.0),
                          child: Transform.rotate(
                            angle: progress * 0.02,
                            alignment: Alignment.topLeft,
                            child: Opacity(
                              opacity: (1.0 - (progress * 0.15)).clamp(
                                0.0,
                                1.0,
                              ),
                              child: _buildBottomStub(
                                isCompleted,
                                isCancelled,
                                isNotVisited,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStub(
    bool isCompleted,
    bool isLiveNow,
    bool isUpi,
    Color badgeTextColor,
    String badgeLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Match Header Row
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF161814),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF262C20), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.sportIcon, size: 13, color: widget.sportColor),
                    const SizedBox(width: 5),
                    Text(
                      widget.booking.sport,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: widget.sportColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF161814),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF262C20), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: badgeTextColor,
                        shape: BoxShape.circle,
                        boxShadow: isLiveNow || isUpi
                            ? [
                                BoxShadow(
                                  color: badgeTextColor.withValues(alpha: 0.6),
                                  blurRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: badgeTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Player Info & Match Fixture
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Squircle Player Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.sportColor.withValues(alpha: 0.22),
                      widget.sportColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: widget.sportColor.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.booking.customerName.isNotEmpty
                        ? widget.booking.customerName[0].toUpperCase()
                        : 'P',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: isCompleted
                          ? const Color(0xFFA1A1AA)
                          : widget.sportColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.booking.customerName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    widget.scheduleWidget,
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.stadium_outlined,
                          size: 11,
                          color: Color(0xFF71717A),
                        ),
                        const SizedBox(width: 3.5),
                        Expanded(
                          child: Text(
                            widget.booking.courtName,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFA1A1AA),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Fare Box Office Stub
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'FARE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Color(0xFF71717A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${widget.booking.amount.toInt()}',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isCompleted
                          ? const Color(0xFFA1A1AA)
                          : const Color(0xFFD4FF00),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerforationDivider(double progress) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const dashWidth = 4.0;
        const dashSpace = 4.0;
        final availableWidth = totalWidth - 18.0; // 9px each side for notches
        final dashCount = (availableWidth / (dashWidth + dashSpace)).floor();

        return SizedBox(
          height: 18,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Left White Notch
              Positioned(
                left: 0,
                child: Container(
                  width: 9.0 + (progress * 2.0),
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(9),
                    ),
                  ),
                ),
              ),

              // 2. Dashed Tear Line with Perforation Jitter
              Positioned(
                left: 9,
                right: 9,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(dashCount, (index) {
                    final dashFraction = (index + 1) / dashCount;
                    final isTorn = progress > 0.0 && dashFraction <= progress;
                    final verticalJitter = isTorn
                        ? (index.isEven ? 1.0 : -1.0) * progress * 2.5
                        : 0.0;

                    return Transform.translate(
                      offset: Offset(0, verticalJitter),
                      child: Container(
                        width: dashWidth,
                        height: isTorn ? 2.0 : 1.5,
                        decoration: BoxDecoration(
                          color: isTorn
                              ? const Color(0xFFD4FF00)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(0.8),
                          boxShadow: isTorn
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFD4FF00,
                                    ).withValues(alpha: 0.6),
                                    blurRadius: 3,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // 3. Right White Notch
              const Positioned(
                right: 0,
                child: SizedBox(
                  width: 9,
                  height: 18,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(9),
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Glowing Tear Spark Rip Head
              if (progress > 0.02 && progress < 0.98)
                Positioned(
                  left: 9.0 + (availableWidth * progress) - 8.0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFD4FF00),
                          const Color(0xFFD4FF00).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFD4FF00),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
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

  Widget _buildBottomStub(
    bool isCompleted,
    bool isCancelled,
    bool isNotVisited,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: isNotVisited
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF201214),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF421C22)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_off_rounded,
                          size: 15,
                          color: Color(0xFFFB7185),
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'They Not Visit The Turf',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFB7185),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${widget.booking.amount.toInt()} Unattended',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD4FF00),
                    ),
                  ),
                ],
              ),
            )
          : isCompleted
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF121411),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF22261E)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: Color(0xFF16A34A),
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Match Completed & Closed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE4E4E7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${widget.booking.amount.toInt()} Settled',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD4FF00),
                    ),
                  ),
                ],
              ),
            )
          : isCancelled
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1215),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4A1A20)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Color(0xFFDC2626),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Slot Cancelled & Released',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFB7185),
                    ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                // Primary Action: View Match Pass & Actions (Triggers Tear)
                Expanded(
                  flex: 3,
                  child: Material(
                    color: const Color(0xFFD4FF00),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _triggerTear,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.confirmation_number_rounded,
                              size: 15,
                              color: Colors.black,
                            ),
                            SizedBox(width: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Pass & Actions',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Secondary Action: Call Customer
                Expanded(
                  flex: 2,
                  child: Material(
                    color: const Color(0xFF141A0A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: const Color(0xFFD4FF00).withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: widget.onCall,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.call_rounded,
                              size: 15,
                              color: Color(0xFFD4FF00),
                            ),
                            SizedBox(width: 5),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Call',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD4FF00),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
