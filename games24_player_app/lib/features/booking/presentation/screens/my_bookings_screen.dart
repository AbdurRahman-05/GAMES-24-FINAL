import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/providers/app_providers.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(userBookingsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Upcoming Bookings Tab
            _buildBookingsList(
              context,
              ref,
              bookings.where((b) => b.status == BookingStatus.upcoming).toList(),
              isUpcoming: true,
            ),

            // History Tab
            _buildBookingsList(
              context,
              ref,
              bookings.where((b) => b.status != BookingStatus.upcoming).toList(),
              isUpcoming: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(
    BuildContext context,
    WidgetRef ref,
    List<BookingModel> list, {
    required bool isUpcoming,
  }) {
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.confirmation_number_outlined,
        title: isUpcoming ? 'No Upcoming Bookings' : 'No Booking History',
        description: isUpcoming
            ? 'Discover nearby turfs in Madurai and book your court now.'
            : 'Your past venue booking activity will appear here.',
        buttonText: isUpcoming ? 'Explore Venues' : null,
        onButtonPressed: isUpcoming ? () => context.go('/search') : null,
      );
    }

    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final booking = list[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AppCard(
            onTap: () => context.push('/booking-success', extra: booking),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(booking.id, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: booking.status == BookingStatus.upcoming
                            ? AppColors.success.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        booking.status == BookingStatus.upcoming ? 'CONFIRMED' : 'COMPLETED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: booking.status == BookingStatus.upcoming ? AppColors.success : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        booking.imageUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 64,
                          height: 64,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.stadium_rounded, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.venueName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('${booking.area} • ${booking.sportName}', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text('${booking.date} (${booking.timeSlot})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
