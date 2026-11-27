import 'package:flutter_test/flutter_test.dart';
import 'package:games24_player_app/booking_manager.dart';
import 'package:games24_player_app/core/utils/slot_time.dart';

void main() {
  group('SlotTime parsing', () {
    test('parses a normal slot', () {
      expect(SlotTime.startMinutes('06:00 PM - 07:00 PM'), 18 * 60);
      expect(SlotTime.endMinutes('06:00 PM - 07:00 PM'), 19 * 60);
    });

    test('a slot ending at midnight ends at 1440, not 0', () {
      expect(SlotTime.endMinutes('11:00 PM - 12:00 AM'), 24 * 60);
    });

    test('multi-slot bookings use first start and last end', () {
      const slots = '09:00 PM - 10:00 PM, 10:00 PM - 11:00 PM, 11:00 PM - 12:00 AM';
      expect(SlotTime.startMinutes(slots), 21 * 60);
      expect(SlotTime.endMinutes(slots), 24 * 60);
    });

    test('unparseable input returns -1', () {
      expect(SlotTime.startMinutes(''), -1);
      expect(SlotTime.endMinutes('soon'), -1);
    });
  });

  group('SlotTime.hasEnded', () {
    test('11 PM booking is still running at 11:30 PM the same day', () {
      final now = DateTime(2026, 11, 26, 23, 30);
      expect(SlotTime.hasEnded('2026-11-26', '11:00 PM - 12:00 AM', now: now), isFalse);
    });

    test('11 PM booking has ended just after midnight', () {
      final now = DateTime(2026, 11, 27, 0, 1);
      expect(SlotTime.hasEnded('2026-11-26', '11:00 PM - 12:00 AM', now: now), isTrue);
    });
  });

  group('cancellation window (3 hours, same as server)', () {
    test('allowed more than 3 hours before start', () {
      final now = DateTime(2026, 11, 26, 14, 59);
      expect(SlotTime.canCancel('2026-11-26', '06:00 PM - 07:00 PM', now: now), isTrue);
    });

    test('blocked within 3 hours of start', () {
      final now = DateTime(2026, 11, 26, 15, 1);
      expect(SlotTime.canCancel('2026-11-26', '06:00 PM - 07:00 PM', now: now), isFalse);
    });

    test('only confirmed bookings can be cancelled', () {
      final future = DateTime.now().add(const Duration(days: 3));
      final date = SlotTime.dateKey(future);
      expect(
        BookingManager.canCancelBooking({'status': 'Confirmed', 'date': date, 'timeSlot': '06:00 PM - 07:00 PM'}),
        isTrue,
      );
      expect(
        BookingManager.canCancelBooking({'status': 'Cancelled', 'date': date, 'timeSlot': '06:00 PM - 07:00 PM'}),
        isFalse,
      );
    });
  });

  group('BookingManager.isBookingActive', () {
    test('future confirmed booking is active', () {
      final date = SlotTime.dateKey(DateTime.now().add(const Duration(days: 2)));
      expect(BookingManager.isBookingActive({'status': 'Confirmed', 'date': date, 'timeSlot': '06:00 PM - 07:00 PM'}), isTrue);
    });

    test('past booking is not active', () {
      final date = SlotTime.dateKey(DateTime.now().subtract(const Duration(days: 2)));
      expect(BookingManager.isBookingActive({'status': 'Confirmed', 'date': date, 'timeSlot': '06:00 PM - 07:00 PM'}), isFalse);
    });

    test('cancelled and not-visited bookings are never active', () {
      final date = SlotTime.dateKey(DateTime.now().add(const Duration(days: 2)));
      expect(BookingManager.isBookingActive({'status': 'Cancelled', 'date': date, 'timeSlot': '06:00 PM - 07:00 PM'}), isFalse);
      expect(BookingManager.isBookingActive({'status': 'Not Visited', 'date': date, 'timeSlot': '06:00 PM - 07:00 PM'}), isFalse);
    });
  });
}
