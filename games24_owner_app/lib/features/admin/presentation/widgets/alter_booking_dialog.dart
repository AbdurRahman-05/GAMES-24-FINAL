import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../providers/admin_providers.dart';

class AlterBookingDialog extends ConsumerStatefulWidget {
  final String bookingId;
  final String playerName;
  final String originalTimeSlot;
  final String courtName;
  final VoidCallback onRescheduled;
  final VoidCallback onCancelled;
  final VoidCallback onCheckedIn;

  const AlterBookingDialog({
    super.key,
    required this.bookingId,
    required this.playerName,
    required this.originalTimeSlot,
    required this.courtName,
    required this.onRescheduled,
    required this.onCancelled,
    required this.onCheckedIn,
  });

  @override
  ConsumerState<AlterBookingDialog> createState() => _AlterBookingDialogState();
}

class _AlterBookingDialogState extends ConsumerState<AlterBookingDialog> {
  late String _selectedNewSlot;
  String _selectedDate = 'Today';

  @override
  void initState() {
    super.initState();
    _selectedNewSlot = widget.originalTimeSlot;
  }

  DateTime _getParsedDate() {
    DateTime now = DateTime.now();
    if (_selectedDate == 'Tomorrow') {
      return now.add(const Duration(days: 1));
    } else if (_selectedDate == 'Next Sat') {
      DateTime nextSat = now;
      while (nextSat.weekday != DateTime.saturday) {
        nextSat = nextSat.add(const Duration(days: 1));
      }
      return nextSat;
    }
    return now;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_calendar_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alter / Shift Booking',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.bookingId,
                              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Customer Booking Overview Card
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Customer Name:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.playerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Court Name:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.courtName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Time Slot:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.originalTimeSlot,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Select Reschedule Date & Time Slot', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedDate,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Today', child: Text('Today', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Tomorrow', child: Text('Tomorrow', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Next Sat', child: Text('Next Sat', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDate = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedNewSlot,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: ref.watch(adminSlotProvider).getUpcomingSlotsForDate(_getParsedDate()).map((slot) {
                      return DropdownMenuItem(value: slot, child: Text(slot, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedNewSlot = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            AppButton(
              text: 'Confirm Shift to $_selectedDate, $_selectedNewSlot',
              icon: Icons.published_with_changes_rounded,
              onPressed: () {
                widget.onRescheduled();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Cancel & Refund',
                    type: AppButtonType.outline,
                    icon: Icons.cancel_outlined,
                    height: 42,
                    onPressed: () {
                      widget.onCancelled();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    text: 'Confirm Check-in',
                    icon: Icons.check_circle_rounded,
                    height: 42,
                    onPressed: () {
                      widget.onCheckedIn();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}
