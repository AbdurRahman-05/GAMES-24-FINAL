import 'package:flutter/material.dart';
import 'package:games24_player_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_kpi_card.dart';
import '../widgets/alter_booking_dialog.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

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
        onRescheduled: () {
          ToastUtils.showSuccess(context, "Booking $bookingId rescheduled successfully! Notification sent to $playerName.");
        },
        onCancelled: () {
          ToastUtils.showSuccess(context, "Booking $bookingId cancelled. Full refund initiated for $playerName.");
        },
        onCheckedIn: () {
          ToastUtils.showSuccess(context, "Gate check-in confirmed for $playerName!");
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final adminSlotState = ref.watch(adminSlotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Madurai Turf Partner Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            onPressed: () => context.push('/admin/qr-scanner'),
            tooltip: 'Entry QR Scanner',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () => context.go('/login'),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue Owner Profile Banner with Operating Hours
            AppCard(
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.stadium_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Madurai Turf Arena (KK Nagar)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hours: ${adminSlotState.weekdayOpeningTime} - ${adminSlotState.weekdayClosingTime} • Verified Partner ✅',
                              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/admin/slots'),
                        child: const Text('Edit Hours'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
              children: const [
                AdminKpiCard(
                  title: 'Today\'s Bookings',
                  value: '18',
                  subtitle: '15 Paid • 3 Cash',
                  icon: Icons.confirmation_number_rounded,
                  color: AppColors.primary,
                  badgeText: '+22% Today',
                ),
                AdminKpiCard(
                  title: 'This Month Revenue',
                  value: '₹2,48,500',
                  subtitle: '248 Total Bookings',
                  icon: Icons.currency_rupee_rounded,
                  color: AppColors.secondary,
                  badgeText: 'Highest GMV',
                ),
                AdminKpiCard(
                  title: 'Today\'s Slots Status',
                  value: '7 Free',
                  subtitle: '15 Booked • 3 Blocked',
                  icon: Icons.pie_chart_rounded,
                  color: Color(0xFF06B6D4),
                  badgeText: '88% Full',
                ),
                AdminKpiCard(
                  title: 'Cancelled / Shifted',
                  value: '3 Total',
                  subtitle: '2 Cancelled • 1 Shifted',
                  icon: Icons.published_with_changes_rounded,
                  color: AppColors.warning,
                  badgeText: 'Tracked',
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
            _AdminBookingFeedTile(
              bookingId: 'BK-99214',
              playerName: 'Vijay Sethu (7v7 Match)',
              time: '08:00 PM - 09:00 PM',
              courtName: 'Artificial Grass Turf A',
              amount: '₹1,200',
              status: 'PAID VIA GPAY',
              statusColor: AppColors.success,
              onAlter: () => _openAlterModal(
                context,
                bookingId: 'BK-99214',
                playerName: 'Vijay Sethu',
                time: '08:00 PM - 09:00 PM',
                courtName: 'Artificial Grass Turf A',
              ),
            ),
            _AdminBookingFeedTile(
              bookingId: 'BK-99215',
              playerName: 'Manojh Kumar (Box Cricket)',
              time: '09:00 PM - 10:00 PM',
              courtName: 'Box Cricket Arena B',
              amount: '₹1,500',
              status: 'PAY AT VENUE',
              statusColor: AppColors.warning,
              onAlter: () => _openAlterModal(
                context,
                bookingId: 'BK-99215',
                playerName: 'Manojh Kumar',
                time: '09:00 PM - 10:00 PM',
                courtName: 'Box Cricket Arena B',
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
