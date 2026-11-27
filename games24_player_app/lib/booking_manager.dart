import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/api_client.dart';
import 'core/utils/slot_time.dart';

/// Outcome of a booking action, with the server's message for the UI.
class BookingActionResult {
  final bool ok;
  final String message;
  final Map<String, dynamic> data;

  const BookingActionResult(this.ok, this.message, [this.data = const {}]);
}

/// Player bookings. The server is the source of truth; SharedPreferences only caches the last
/// server response so the list renders instantly (it is per-user and cleared on logout).
class BookingManager {
  static final BookingManager _instance = BookingManager._internal();
  factory BookingManager() => _instance;

  BookingManager._internal() {
    _loadFromCache();
  }

  final ValueNotifier<List<Map<String, dynamic>>> bookingsNotifier = ValueNotifier([]);
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  Future<void>? _inFlight;

  static const String _cacheKey = 'cached_user_bookings';

  /// Clears in-memory bookings (logout / account switch) and reloads for the current user.
  Future<void> reset() async {
    bookingsNotifier.value = [];
    _inFlight = null;
    _isLoading = false;
    await _loadFromCache();
  }

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

  // ---------------------------------------------------------------------------
  // Time helpers (kept as statics because many screens call them directly)
  // ---------------------------------------------------------------------------

  static int parseSlotEndMinutes(String timeSlotStr) => SlotTime.endMinutes(timeSlotStr);

  static int parseSlotStartMinutes(String timeSlotStr) => SlotTime.startMinutes(timeSlotStr);

  /// Minutes until the booking's last slot ends (0 when over). Future dates return 60 as before.
  static int getRemainingSlotMinutes({String? dateStr, required String timeSlot}) {
    final date = (dateStr ?? '').trim();
    final now = DateTime.now();
    if (date.isNotEmpty) {
      final end = SlotTime.endDateTime(date, timeSlot);
      if (end == null) return 0;
      final start = SlotTime.startDateTime(date, timeSlot);
      if (start != null && now.isBefore(start)) return 60; // not started yet
      final diff = end.difference(now).inMinutes;
      return diff > 0 ? diff : 0;
    }
    final endMin = SlotTime.endMinutes(timeSlot);
    if (endMin == -1) return 0;
    final diff = endMin - (now.hour * 60 + now.minute);
    return diff > 0 ? diff : 0;
  }

  static bool isBookingActive(Map<String, dynamic> b) {
    final status = (b['status'] ?? '').toString().toLowerCase();
    if (status == 'cancelled' || status == 'completed' || status == 'not visited') return false;
    final date = (b['date'] ?? '').toString().trim();
    if (date.isEmpty) return false;
    final timeSlot = (b['timeSlot'] ?? '').toString();
    if (SlotTime.endMinutes(timeSlot) == -1) {
      final today = SlotTime.dateKey(DateTime.now());
      if (date.compareTo(today) != 0) return date.compareTo(today) > 0;
      return b['isActive'] is bool ? b['isActive'] == true : true;
    }
    return !SlotTime.hasEnded(date, timeSlot);
  }

  static bool isMatchStarted({String? dateStr, required String timeSlot}) {
    if (timeSlot.trim().isEmpty) return true;
    final now = DateTime.now();
    final d = (dateStr ?? '').trim().toLowerCase();
    if (d == 'tomorrow') return false;
    if (d == 'yesterday') return true;
    if (d.isNotEmpty && d != 'today') {
      final start = SlotTime.startDateTime(dateStr!.trim(), timeSlot);
      if (start != null) return !now.isBefore(start);
    }
    final startMin = SlotTime.startMinutes(timeSlot);
    if (startMin == -1) return true;
    return now.hour * 60 + now.minute >= startMin;
  }

  static int getMinutesUntilMatchStart({String? dateStr, required String timeSlot}) {
    final date = (dateStr ?? '').trim();
    if (date.isNotEmpty) {
      final start = SlotTime.startDateTime(date, timeSlot);
      if (start != null) {
        final diff = start.difference(DateTime.now()).inMinutes;
        return diff > 0 ? diff : 0;
      }
    }
    final startMin = SlotTime.startMinutes(timeSlot);
    if (startMin == -1) return 0;
    final now = DateTime.now();
    final diff = startMin - (now.hour * 60 + now.minute);
    return diff > 0 ? diff : 0;
  }

  static String getFormattedSlotStart({required String timeSlot}) {
    if (timeSlot.trim().isEmpty) return '';
    final parts = SlotTime.split(timeSlot);
    final first = parts.isNotEmpty ? parts.first : timeSlot;
    return first.split('-').first.trim();
  }

  /// Same 3-hour rule the server enforces.
  static bool canCancelBooking(Map<String, dynamic> booking) {
    final status = (booking['status'] ?? '').toString().toLowerCase();
    if (status != 'confirmed') return false;
    return SlotTime.canCancel(
      (booking['date'] ?? '').toString(),
      (booking['timeSlot'] ?? '').toString(),
    );
  }

  List<Map<String, dynamic>> get activeBookings =>
      bookingsNotifier.value.where((b) => isBookingActive(b)).toList();

  List<Map<String, dynamic>> get completedBookings => bookingsNotifier.value.where((b) {
        final status = (b['status'] ?? '').toString().toLowerCase();
        if (status == 'cancelled') return false;
        return !isBookingActive(b);
      }).toList();

  List<Map<String, dynamic>> get cancelledBookings => bookingsNotifier.value.where((b) {
        final status = (b['status'] ?? '').toString().toLowerCase();
        return status == 'cancelled';
      }).toList();

  // ---------------------------------------------------------------------------
  // Server sync
  // ---------------------------------------------------------------------------

  /// Fetches the player's bookings by phone number. Concurrent callers share one request, so
  /// awaiting this always yields fresh data (it used to return early with stale data).
  Future<void> fetchBookings() {
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  Future<void> _fetch() async {
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = (prefs.getString('mobileNumber') ?? '').trim();
      if (phone.replaceAll(RegExp(r'\D'), '').length < 10) return;

      final res = await ApiClient.get('/turfs/user-bookings', query: {'phone': phone});
      if (res.ok && res.data is List) {
        final parsed = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        bookingsNotifier.value = parsed;
        await _saveToCache(parsed);
      }
    } catch (e) {
      debugPrint('Error fetching user bookings: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Shows a just-confirmed booking immediately; the next fetch replaces it with server data.
  Future<void> addBooking(Map<String, dynamic> booking) async {
    final current = List<Map<String, dynamic>>.from(bookingsNotifier.value);
    current.removeWhere((b) => b['id'] != null && b['id'] == booking['id']);
    current.insert(0, booking);
    bookingsNotifier.value = current;
    await _saveToCache(current);
  }

  static int? _numericId(dynamic bookingId) =>
      int.tryParse((bookingId?.toString() ?? '').replaceAll(RegExp(r'[^0-9]'), ''));

  Future<BookingActionResult> cancelBooking(int bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = (prefs.getString('mobileNumber') ?? '').trim();
    final res = await ApiClient.post('/turfs/bookings/$bookingId/cancel', body: {'callerPhone': phone});
    if (!res.ok) return BookingActionResult(false, res.message);

    await fetchBookings();
    final refund = res.map['refund'];
    String message = 'Booking cancelled successfully.';
    if (refund is Map) {
      final amount = refund['amount'];
      message = refund['initiated'] == true
          ? 'Booking cancelled. Refund of ₹$amount initiated to your original payment method.'
          : 'Booking cancelled. ${refund['message'] ?? 'Our team will process your refund.'}';
    }
    return BookingActionResult(true, message, res.map);
  }

  /// Marks a booking completed after a match. The server only accepts this once the slot has
  /// ended; while the slot is still running the court stays active for another match.
  Future<void> markBookingCompleted(dynamic bookingId, {bool force = false}) async {
    final strId = bookingId?.toString() ?? '';
    if (strId.isEmpty) return;

    final current = List<Map<String, dynamic>>.from(bookingsNotifier.value);
    Map<String, dynamic>? target;
    for (int i = 0; i < current.length; i++) {
      final b = Map<String, dynamic>.from(current[i]);
      final bId = (b['id'] ?? b['bookingId'] ?? b['booking_code'])?.toString();
      if (bId == strId || b['bookingCode']?.toString() == strId) {
        final ended = SlotTime.hasEnded((b['date'] ?? '').toString(), (b['timeSlot'] ?? '').toString());
        if (force || ended) {
          b['status'] = 'Completed';
          b['isActive'] = false;
          b['openMatchStatus'] = b['isOpenMatch'] == true ? 'COMPLETED' : null;
        } else {
          b['lastMatchCompleted'] = true;
          b['isActive'] = true;
        }
        current[i] = b;
        target = b;
        break;
      }
    }

    if (target != null) {
      bookingsNotifier.value = current;
      await _saveToCache(current);
    }

    final ended = target == null ||
        SlotTime.hasEnded((target['date'] ?? '').toString(), (target['timeSlot'] ?? '').toString());
    final intId = _numericId(bookingId);
    if (intId != null && ended) {
      await ApiClient.post('/turfs/bookings/$intId/complete');
    }
  }

  Future<BookingActionResult> updateBookingOpponent(
    dynamic bookingId,
    String opponentName, {
    String opponentPhone = '',
  }) async {
    final intId = _numericId(bookingId);
    if (intId == null) {
      return const BookingActionResult(false, 'This booking could not be identified.');
    }
    final res = await ApiClient.post('/turfs/bookings/$intId/set-opponent', body: {
      'opponentName': opponentName,
      'opponentPhone': opponentPhone,
    });
    if (!res.ok) return BookingActionResult(false, res.message);

    _patchLocal(bookingId, {
      'opponentName': opponentName,
      'opponentPhone': opponentPhone,
      'openMatchStatus': 'OPPONENT_JOINED',
    });
    return BookingActionResult(true, res.message);
  }

  Future<BookingActionResult> convertBookingToPrivate(dynamic bookingId) async {
    final intId = _numericId(bookingId);
    if (intId == null) {
      return const BookingActionResult(false, 'This booking could not be identified.');
    }
    final res = await ApiClient.post('/turfs/bookings/$intId/convert-to-private');
    if (!res.ok) return BookingActionResult(false, res.message);

    _patchLocal(bookingId, {'isOpenMatch': false, 'openMatchStatus': null});
    return BookingActionResult(true, res.message);
  }

  void _patchLocal(dynamic bookingId, Map<String, dynamic> changes) {
    final strId = bookingId?.toString() ?? '';
    final current = List<Map<String, dynamic>>.from(bookingsNotifier.value);
    for (int i = 0; i < current.length; i++) {
      final b = current[i];
      final bId = (b['id'] ?? b['bookingId'] ?? b['booking_code'])?.toString();
      if (bId == strId || b['bookingCode']?.toString() == strId) {
        current[i] = {...b, ...changes};
        break;
      }
    }
    bookingsNotifier.value = current;
    _saveToCache(current);
  }
}
