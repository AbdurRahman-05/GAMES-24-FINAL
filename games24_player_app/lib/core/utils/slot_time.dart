/// Shared helpers for slot strings such as "06:00 PM - 07:00 PM" or
/// "10:00 PM - 11:00 PM, 11:00 PM - 12:00 AM" (multi-slot bookings).
///
/// All minute values are measured from the start of the booking's date. A slot that ends at or
/// before it starts (e.g. "11:00 PM - 12:00 AM") ends on the next day, so its end is >= 1440.
class SlotTime {
  SlotTime._();

  static final RegExp _time = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false);

  static List<String> split(String timeSlot) =>
      timeSlot.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  static int _toMinutes(String text) {
    final m = _time.firstMatch(text);
    if (m == null) return -1;
    var hour = int.tryParse(m.group(1) ?? '') ?? 0;
    final min = int.tryParse(m.group(2) ?? '') ?? 0;
    final period = (m.group(3) ?? '').toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + min;
  }

  /// Start of the first sub-slot, or -1 if it cannot be parsed.
  static int startMinutes(String timeSlot) {
    if (timeSlot.trim().isEmpty) return -1;
    final parts = split(timeSlot);
    final first = parts.isNotEmpty ? parts.first : timeSlot;
    return _toMinutes(first.split('-').first);
  }

  /// End of the last sub-slot (>= 1440 when it ends at/after midnight), or -1.
  static int endMinutes(String timeSlot) {
    if (timeSlot.trim().isEmpty) return -1;
    final parts = split(timeSlot);
    final last = parts.isNotEmpty ? parts.last : timeSlot;
    final pieces = last.split('-');
    final end = _toMinutes(pieces.length > 1 ? pieces[1] : pieces[0]);
    if (end == -1) return -1;
    final lastStart = _toMinutes(pieces.first);
    if (pieces.length > 1 && lastStart != -1 && end <= lastStart) return end + 24 * 60;
    return end;
  }

  /// "YYYY-MM-DD" for a date.
  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? parseDate(String date) {
    final parts = date.trim().split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]), m = int.tryParse(parts[1]), d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Absolute start time of a booking, or null when it cannot be parsed.
  static DateTime? startDateTime(String date, String timeSlot) {
    final day = parseDate(date);
    final start = startMinutes(timeSlot);
    if (day == null || start < 0) return null;
    return day.add(Duration(minutes: start));
  }

  /// Absolute end time of a booking (handles slots that end at midnight).
  static DateTime? endDateTime(String date, String timeSlot) {
    final day = parseDate(date);
    final end = endMinutes(timeSlot);
    if (day == null || end < 0) return null;
    return day.add(Duration(minutes: end));
  }

  /// True once the booking's last slot has finished.
  static bool hasEnded(String date, String timeSlot, {DateTime? now}) {
    final end = endDateTime(date, timeSlot);
    if (end == null) return false;
    return !(now ?? DateTime.now()).isBefore(end);
  }

  /// Players may cancel up to this long before the first slot starts (matches the server rule).
  static const Duration cancellationWindow = Duration(hours: 3);

  static bool canCancel(String date, String timeSlot, {DateTime? now}) {
    final start = startDateTime(date, timeSlot);
    if (start == null) return false;
    return (now ?? DateTime.now()).isBefore(start.subtract(cancellationWindow));
  }
}
