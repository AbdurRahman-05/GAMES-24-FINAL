import 'api_config.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BookingManager {
  static final BookingManager _instance = BookingManager._internal();
  factory BookingManager() => _instance;

  BookingManager._internal() {
    _loadFromCache();
  }

  final ValueNotifier<List<Map<String, dynamic>>> bookingsNotifier = ValueNotifier([]);
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  static const String _cacheKey = 'cached_user_bookings';

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List list = jsonDecode(cachedJson);
        bookingsNotifier.value = list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading cached bookings: $e');
    }
  }

  Future<void> _saveToCache(List<Map<String, dynamic>> bookings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(bookings));
    } catch (e) {
      debugPrint('Error saving cached bookings: $e');
    }
  }

  List<Map<String, dynamic>> get allBookings => bookingsNotifier.value;

  static int parseSlotEndMinutes(String timeSlotStr) {
    if (timeSlotStr.trim().isEmpty) return -1;
    final slotList = timeSlotStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final lastSlot = slotList.isNotEmpty ? slotList.last : timeSlotStr;
    final parts = lastSlot.split('-');
    final endPart = (parts.length > 1 ? parts[1] : parts[0]).trim();

    final reg = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false);
    final match = reg.firstMatch(endPart);
    if (match == null) return -1;
    int hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final min = int.tryParse(match.group(2) ?? '') ?? 0;
    final period = (match.group(3) ?? '').toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + min;
  }

  static int parseSlotStartMinutes(String timeSlotStr) {
    if (timeSlotStr.trim().isEmpty) return -1;
    final slotList = timeSlotStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final firstSlot = slotList.isNotEmpty ? slotList.first : timeSlotStr;
    final parts = firstSlot.split('-');
    final startPart = parts[0].trim();

    final reg = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false);
    final match = reg.firstMatch(startPart);
    if (match == null) return -1;
    int hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final min = int.tryParse(match.group(2) ?? '') ?? 0;
    final period = (match.group(3) ?? '').toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + min;
  }

  static bool isBookingActive(Map<String, dynamic> b) {
    final status = (b['status'] ?? '').toString().toLowerCase();
    if (status == 'cancelled' || status == 'completed') return false;

    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final date = (b['date'] ?? '').toString().trim();
    if (date.isEmpty) return false;

    if (date.compareTo(todayStr) < 0) {
      return false; // In the past
    }
    if (date.compareTo(todayStr) > 0) {
      return true; // Future date
    }

    // Today: check slot end time
    final timeSlot = (b['timeSlot'] ?? '').toString();
    final endMin = parseSlotEndMinutes(timeSlot);
    if (endMin == -1) {
      if (b.containsKey('isActive') && b['isActive'] is bool) {
        return b['isActive'] == true;
      }
      return true;
    }

    final currentMin = now.hour * 60 + now.minute;
    return currentMin < endMin;
  }

  static bool isMatchStarted({String? dateStr, required String timeSlot}) {
    if (timeSlot.trim().isEmpty) return true;
    final now = DateTime.now();

    if (dateStr != null && dateStr.trim().isNotEmpty) {
      final d = dateStr.trim().toLowerCase();
      if (d == 'tomorrow') return false;
      if (d == 'yesterday') return true;
      if (d != 'today') {
        final parsed = DateTime.tryParse(dateStr.trim());
        if (parsed != null) {
          final today = DateTime(now.year, now.month, now.day);
          final matchDate = DateTime(parsed.year, parsed.month, parsed.day);
          if (matchDate.isAfter(today)) return false; // future date -> not started
          if (matchDate.isBefore(today)) return true; // past date -> already past start
        }
      }
    }

    // Date is today:
    final startMin = parseSlotStartMinutes(timeSlot);
    if (startMin == -1) return true; // fallback
    final currentMin = now.hour * 60 + now.minute;
    return currentMin >= startMin;
  }

  static int getMinutesUntilMatchStart({String? dateStr, required String timeSlot}) {
    final startMin = parseSlotStartMinutes(timeSlot);
    if (startMin == -1) return 0;
    final now = DateTime.now();
    final currentMin = now.hour * 60 + now.minute;
    final diff = startMin - currentMin;
    return diff > 0 ? diff : 0;
  }

  static String getFormattedSlotStart({required String timeSlot}) {
    if (timeSlot.trim().isEmpty) return '';
    final slotList = timeSlot.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final firstSlot = slotList.isNotEmpty ? slotList.first : timeSlot;
    final parts = firstSlot.split('-');
    return parts[0].trim();
  }

  static bool canCancelBooking(Map<String, dynamic> booking) {
    final status = (booking['status'] ?? '').toString().toLowerCase();
    if (status == 'cancelled') return false;

    final dateStr = (booking['date'] ?? '').toString().trim();
    final timeSlot = (booking['timeSlot'] ?? '').toString().trim();
    if (dateStr.isEmpty) return false;

    try {
      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) return false;
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final startMin = parseSlotStartMinutes(timeSlot);
      if (startMin == -1) return false;

      final slotHour = startMin ~/ 60;
      final slotMinute = startMin % 60;
      final slotStartTime = DateTime(year, month, day, slotHour, slotMinute);
      final cutoffTime = slotStartTime.subtract(const Duration(hours: 3));

      final now = DateTime.now();
      // Allowed only if strictly before 3 hours prior to start time
      return now.isBefore(cutoffTime);
    } catch (e) {
      return false;
    }
  }

  List<Map<String, dynamic>> get activeBookings {
    return bookingsNotifier.value.where((b) => isBookingActive(b)).toList();
  }

  List<Map<String, dynamic>> get completedBookings {
    return bookingsNotifier.value.where((b) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      if (status == 'cancelled') return false;
      return !isBookingActive(b);
    }).toList();
  }

  List<Map<String, dynamic>> get cancelledBookings {
    return bookingsNotifier.value.where((b) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      return status == 'cancelled';
    }).toList();
  }

  Future<void> fetchBookings() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = (prefs.getString('mobileNumber') ?? '').trim();
      final name = (prefs.getString('fullName') ?? '').trim();

      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/turfs/user-bookings?phone=${Uri.encodeComponent(phone)}&name=${Uri.encodeComponent(name)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        final parsed = list.map((e) => Map<String, dynamic>.from(e)).toList();
        bookingsNotifier.value = parsed;
        await _saveToCache(parsed);
      }
    } catch (e) {
      debugPrint('Error fetching user bookings: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> addBooking(Map<String, dynamic> booking) async {
    final current = List<Map<String, dynamic>>.from(bookingsNotifier.value);
    current.removeWhere((b) => b['id'] != null && b['id'] == booking['id']);
    current.insert(0, booking);
    bookingsNotifier.value = current;
    await _saveToCache(current);
  }

  Future<bool> cancelBooking(int bookingId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/turfs/bookings/$bookingId/cancel');
      final res = await http.post(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchBookings();
        return true;
      }
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
    }
    return false;
  }

  Future<void> markBookingCompleted(dynamic bookingId) async {
    final strId = bookingId?.toString() ?? '';
    if (strId.isEmpty) return;

    final current = List<Map<String, dynamic>>.from(bookingsNotifier.value);
    bool found = false;
    for (int i = 0; i < current.length; i++) {
      final b = Map<String, dynamic>.from(current[i]);
      final bId = (b['id'] ?? b['bookingId'] ?? b['booking_code'])?.toString();
      final bCode = b['bookingCode']?.toString();
      if (bId == strId || bCode == strId) {
        b['status'] = 'Completed';
        b['isActive'] = false;
        if (b['isOpenMatch'] == true) {
          b['openMatchStatus'] = 'COMPLETED';
        } else {
          b['openMatchStatus'] = null;
        }
        current[i] = b;
        found = true;
        break;
      }
    }

    if (found) {
      bookingsNotifier.value = current;
      await _saveToCache(current);
    }

    final intId = int.tryParse(strId.replaceAll(RegExp(r'[^0-9]'), ''));
    if (intId != null) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/turfs/bookings/$intId/complete');
        await http.post(uri).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
  }
}
