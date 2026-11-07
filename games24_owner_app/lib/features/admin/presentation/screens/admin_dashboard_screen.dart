import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:games24_owner_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_kpi_card.dart';
import '../widgets/alter_booking_dialog.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isRefreshing = false;

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
            ToastUtils.showSuccess(context, "Booking $bookingId rescheduled successfully! Shifted count updated in database.");
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
            ToastUtils.showSuccess(context, "Booking $bookingId cancelled. Cancellation recorded in database.");
          }
        },
        onCheckedIn: () async {
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
          if (context.mounted) {
            ToastUtils.showSuccess(context, "Gate check-in confirmed for $playerName! Metrics updated in database.");
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(turfProfileProvider);

    // If subscription has totally ended: owner side access is completely BLOCKED!
    if (profile.isSubscriptionBlocked) {
      return _buildBlockedAccessScaffold(context, profile);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 34,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.venueName.isNotEmpty ? profile.venueName : 'Turf Owner Hub',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Live Partner Dashboard',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A),
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
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF166534).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF166534), size: 18),
            ),
            onPressed: () => context.push('/admin/qr-scanner'),
            tooltip: 'Entry QR Scanner',
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 18),
            ),
            onPressed: () async {
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
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRealtimeData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monthly Platform Subscription Card (Live vs Expired / Turf Hidden)
              _buildSubscriptionBanner(context, profile),

              // KPI Grid
              Text('Today\'s & Monthly Venue Performance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  AdminKpiCard(
                    title: 'Today\'s Bookings',
                    value: '${profile.todayBookingsCount}',
                    subtitle: '${profile.todayPaidBookings} Paid • ${profile.todayCashBookings} Cash',
                    icon: Icons.confirmation_number_rounded,
                    color: AppColors.primary,
                    badgeText: profile.todayBookingsGrowth,
                  ),
                  AdminKpiCard(
                    title: 'This Month Revenue',
                    value: profile.monthRevenue > 0
                        ? '₹${NumberFormat('#,##,###').format(profile.monthRevenue.toInt())}'
                        : '₹0',
                    subtitle: '${profile.monthTotalBookings} Total Bookings',
                    icon: Icons.currency_rupee_rounded,
                    color: AppColors.secondary,
                    badgeText: profile.revenueBadge,
                  ),
                  AdminKpiCard(
                    title: 'Today\'s Slots Status',
                    value: '${profile.freeSlotsCount} Free',
                    subtitle: '${profile.bookedSlotsCount} Booked • ${profile.blockedSlotsCount} Blocked',
                    icon: Icons.pie_chart_rounded,
                    color: const Color(0xFF06B6D4),
                    badgeText: profile.slotsBadge,
                  ),
                  AdminKpiCard(
                    title: 'Cancelled / Shifted',
                    value: '${profile.cancelledTotal} Total',
                    subtitle: '${profile.cancelledCount} Cancelled • ${profile.shiftedCount} Shifted',
                    icon: Icons.published_with_changes_rounded,
                    color: AppColors.warning,
                    badgeText: profile.cancelledBadge,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Admin Tools Grid
              Text('Quick Court Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      onTap: () => context.push('/admin/slots'),
                      child: const Column(
                        children: [
                          Icon(Icons.edit_calendar_rounded, size: 28, color: AppColors.primary),
                          SizedBox(height: 6),
                          Text('Manage Slots & Offers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                          SizedBox(height: 2),
                          Text('Block / Discounts', style: TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppCard(
                      onTap: () => context.push('/admin/qr-scanner'),
                      child: const Column(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 28, color: AppColors.secondary),
                          SizedBox(height: 6),
                          Text('Gate Check-in', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                          SizedBox(height: 2),
                          Text('Scan Player QR', style: TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppCard(
                      onTap: () => context.go('/admin/tournaments'),
                      child: const Column(
                        children: [
                          Icon(Icons.emoji_events_rounded, size: 28, color: AppColors.primary),
                          SizedBox(height: 6),
                          Text('Tournaments Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                          SizedBox(height: 2),
                          Text('Manage & Sync', style: TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Live Incoming Bookings Stream with Reschedule/Alter Option
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Live Customer Bookings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.push('/admin/slots'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (profile.bookingHistory.isNotEmpty)
                ...profile.bookingHistory.take(2).map((b) => _AdminBookingFeedTile(
                      bookingId: b.id,
                      playerName: b.customerName,
                      time: b.dateTimeSlot.replaceFirst('Today, ', '').replaceFirst('Yesterday, ', ''),
                      courtName: b.courtName,
                      amount: '₹${b.amount.toInt()}',
                      status: b.paymentMethod.toUpperCase().contains('UPI') ? 'PAID VIA GPAY' : 'PAY AT VENUE',
                      statusColor: b.paymentMethod.toUpperCase().contains('UPI') ? AppColors.success : AppColors.warning,
                      onAlter: () => _openAlterModal(
                        context,
                        bookingId: b.id,
                        playerName: b.customerName,
                        time: b.dateTimeSlot.replaceFirst('Today, ', '').replaceFirst('Yesterday, ', ''),
                        courtName: b.courtName,
                      ),
                    ))
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No bookings scheduled for today yet.'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionBanner(BuildContext context, TurfProfileState profile) {
    // Only show reminder on Home page when 3 days or fewer left before subscription ends!
    // When healthy (> 3 days left), home page stays clean and starts with KPIs!
    if (!profile.isSubscriptionEndingSoon) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFCD34D),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
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
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Subscription Renews in ${profile.subscriptionDaysRemaining} Day(s)',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Renews on ${profile.subscriptionRenewDate}. Pay ₹1,180 to avoid turf deactivation.',
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Amount: ₹1,180 (Base ₹1,000 + GST)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () => _openSubscriptionDialog(context, profile),
                child: const Text(
                  'Renew Now (₹1,180)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedAccessScaffold(BuildContext context, TurfProfileState profile) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 30),
            const SizedBox(width: 8),
            const Text(
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
                'Your monthly platform subscription for "${profile.venueName.isNotEmpty ? profile.venueName : 'Your Turf'}" has ended.\n\nYour turf is currently HIDDEN from players on the Games24 Player App and owner hub access is locked until renewed.',
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
                color: const Color(0xFF166534).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF166534), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Owner Platform Subscription',
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
                      Text('₹1,180 / month', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
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
                  backgroundColor: const Color(0xFF166534),
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
}

class _AdminBookingFeedTile extends StatelessWidget {
  final String bookingId;
  final String playerName;
  final String time;
  final String courtName;
  final String amount;
  final String status;
  final Color statusColor;
  final VoidCallback onAlter;

  const _AdminBookingFeedTile({
    required this.bookingId,
    required this.playerName,
    required this.time,
    required this.courtName,
    required this.amount,
    required this.status,
    required this.statusColor,
    required this.onAlter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bookingId, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(playerName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('$courtName • $time', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Alter / Shift Slot 🔄',
                    type: AppButtonType.outline,
                    height: 38,
                    onPressed: onAlter,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
