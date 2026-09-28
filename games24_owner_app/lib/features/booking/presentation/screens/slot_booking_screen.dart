import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/venue_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/repositories/mock_venues.dart';
import '../../../admin/providers/admin_providers.dart';
import '../widgets/slot_chip.dart';

class SlotBookingScreen extends ConsumerStatefulWidget {
  final String venueId;

  const SlotBookingScreen({
    super.key,
    required this.venueId,
  });

  @override
  ConsumerState<SlotBookingScreen> createState() => _SlotBookingScreenState();
}

class _SlotBookingScreenState extends ConsumerState<SlotBookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedSlot;
  String _selectedSport = 'Football';
  String _selectedPaymentMethod = 'UPI (GPay / PhonePe)';

  void confirmBooking(VenueModel venue, double totalPrice) {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available time slot.')),
      );
      return;
    }

    final booking = BookingModel(
      id: 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      venueId: venue.id,
      venueName: venue.name,
      area: venue.area,
      sportName: _selectedSport,
      date: '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
      timeSlot: _selectedSlot!,
      totalPrice: totalPrice,
      status: BookingStatus.upcoming,
      qrCodeData: 'GAMES24-OWNER-BK${DateTime.now().millisecondsSinceEpoch}',
      imageUrl: venue.imageUrls.first,
    );

    ref.read(userBookingsProvider.notifier).addBooking(booking);
    context.go('/booking-success', extra: booking);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final venue = MockVenuesRepository.venues.firstWhere(
      (v) => v.id == widget.venueId,
      orElse: () => MockVenuesRepository.venues.first,
    );

    final double courtPrice = venue.pricePerHour;
    final double serviceFee = 35.0;
    final double totalPrice = courtPrice + serviceFee;

    final availableSlots = ref.watch(adminSlotProvider).getAvailableSlotsForDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Slot'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue Header summary
            AppCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      venue.imageUrls.first,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(venue.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${venue.area}, Madurai', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Select Sport
            Text('Select Sport', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: venue.sports.map((s) {
                final isSelected = _selectedSport == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedSport = s);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Date Picker Card
            Text('Select Date', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            AppCard(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Time Slots Grid
            Text('Available Slots', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: availableSlots.map((slot) {
                final isSelected = _selectedSlot == slot;
                return SlotChip(
                  slotTime: slot,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedSlot = slot),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Payment Options
            Text('Payment Method', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Column(
              children: ['UPI (GPay / PhonePe / Paytm)', 'Credit / Debit Card', 'Pay at Venue'].map((method) {
                final isSelected = _selectedPaymentMethod == method;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: () => setState(() => _selectedPaymentMethod = method),
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Text(method, style: theme.textTheme.titleSmall),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Price Breakdown Card
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Slot Booking Fee'),
                      Text('₹${courtPrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Convenience & Lights Fee'),
                      Text('₹${serviceFee.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount', style: theme.textTheme.titleMedium),
                      Text(
                        '₹${totalPrice.toInt()}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            AppButton(
              text: 'Confirm & Pay ₹${totalPrice.toInt()}',
              icon: Icons.lock_rounded,
              onPressed: () => confirmBooking(venue, totalPrice),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
