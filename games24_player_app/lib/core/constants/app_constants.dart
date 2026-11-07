class AppConstants {
  AppConstants._();

  static const String appName = 'PlayHub Madurai';
  static const String appTagline = 'Sports & Celebration Venue Booking';
  static const String currencySymbol = '₹';
  
  static const List<String> skillLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Open to All',
  ];

  static const List<String> full24HourSlots = [
    '12:00 AM - 01:00 AM',
    '01:00 AM - 02:00 AM',
    '02:00 AM - 03:00 AM',
    '03:00 AM - 04:00 AM',
    '04:00 AM - 05:00 AM',
    '05:00 AM - 06:00 AM',
    '06:00 AM - 07:00 AM',
    '07:00 AM - 08:00 AM',
    '08:00 AM - 09:00 AM',
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '01:00 PM - 02:00 PM',
    '02:00 PM - 03:00 PM',
    '03:00 PM - 04:00 PM',
    '04:00 PM - 05:00 PM',
    '05:00 PM - 06:00 PM',
    '06:00 PM - 07:00 PM',
    '07:00 PM - 08:00 PM',
    '08:00 PM - 09:00 PM',
    '09:00 PM - 10:00 PM',
    '10:00 PM - 11:00 PM',
    '11:00 PM - 12:00 AM',
  ];

  static const List<String> timeSlots = full24HourSlots;

  static int _parseHour(String timeStr) {
    final cleaned = timeStr.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    if (cleaned == '24 Hours') return 0;

    final parts = cleaned.split(' ');
    if (parts.length < 2) return 0;

    final timeParts = parts[0].split(':');
    int hour = int.tryParse(timeParts[0]) ?? 0;
    final ampm = parts[1].toUpperCase();

    if (ampm == 'PM' && hour < 12) {
      hour += 12;
    } else if (ampm == 'AM' && hour == 12) {
      hour = 0;
    }
    return hour;
  }

  static List<String> generateTimeSlots(String openingTime, String closingTime) {
    if (openingTime == '24 Hours' || closingTime == '24 Hours') {
      return full24HourSlots;
    }

    int startHour = _parseHour(openingTime);
    int endHour = _parseHour(closingTime);

    if (endHour == 0 && closingTime.toUpperCase().contains('AM')) {
      endHour = 24;
    }

    if (endHour <= startHour) {
      endHour += 24;
    }

    List<String> result = [];
    for (int h = startHour; h < endHour; h++) {
      int index = h % 24;
      result.add(full24HourSlots[index]);
    }

    return result.isEmpty ? full24HourSlots : result;
  }

  static int parseSlotStartMinutes(String slot) {
    final startPart = slot.split('-').first.trim();
    final parts = startPart.split(' ');
    if (parts.isEmpty) return -1;
    final timeParts = parts[0].split(':');
    int hour = int.tryParse(timeParts[0]) ?? -1;
    int minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
    if (hour == -1) return -1;
    final ampm = parts.length > 1 ? parts[1].toUpperCase() : '';
    if (ampm == 'PM' && hour != 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  static bool isSlotPast(String slot, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target.isBefore(today)) return true;
    if (target.isAfter(today)) return false;

    final startMin = parseSlotStartMinutes(slot);
    if (startMin == -1) return false;
    final currentMinutes = now.hour * 60 + now.minute;
    return currentMinutes >= startMin;
  }
}
