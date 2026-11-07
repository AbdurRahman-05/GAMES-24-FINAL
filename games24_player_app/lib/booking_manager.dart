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

  List<Map<String, dynamic>> get activeBookings {
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return bookingsNotifier.value.where((b) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      if (status == 'cancelled') return false;

      // If server provided isActive flag
      if (b.containsKey('isActive') && b['isActive'] is bool) {
        return b['isActive'] == true;
      }

      final date = (b['date'] ?? '').toString();
      return date.isNotEmpty && date.compareTo(todayStr) >= 0;
    }).toList();
  }

  List<Map<String, dynamic>> get completedBookings {
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return bookingsNotifier.value.where((b) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      if (status == 'cancelled') return false;

      if (b.containsKey('isActive') && b['isActive'] is bool) {
        return b['isActive'] == false;
      }

      final date = (b['date'] ?? '').toString();
      return date.isNotEmpty && date.compareTo(todayStr) < 0;
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
      final phone = (prefs.getString('mobileNumber') ?? '+917010396731').trim();
      final name = (prefs.getString('fullName') ?? 'Vignesh').trim();

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
}
