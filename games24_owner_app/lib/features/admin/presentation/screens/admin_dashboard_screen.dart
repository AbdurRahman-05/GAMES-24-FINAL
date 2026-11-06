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
