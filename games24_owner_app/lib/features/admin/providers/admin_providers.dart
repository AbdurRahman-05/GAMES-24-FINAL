import '../../../api_config.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

class AdminSlotState {
  final Map<String, Set<String>> blockedSlotsByDate;
  final Map<String, Set<String>> bookedSlotsByDate;
  final Map<String, Map<String, String>> discountedSlotsByDate;
  final String weekdayOpeningTime;
  final String weekdayClosingTime;
  final String weekendOpeningTime;
  final String weekendClosingTime;

  List<String> getAvailableSlotsForDate(DateTime date) {
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    return AppConstants.generateTimeSlots(
      isWeekend ? weekendOpeningTime : weekdayOpeningTime,
      isWeekend ? weekendClosingTime : weekdayClosingTime,
    );
  }

  List<String> getUpcomingSlotsForDate(DateTime date) {
    final all = getAvailableSlotsForDate(date);
    return all.where((s) => !AppConstants.isSlotPast(s, date)).toList();
  }

  List<String> get availableSlots => getAvailableSlotsForDate(DateTime.now());

  AdminSlotState({
    Map<String, Set<String>>? blockedSlotsByDate,
    Map<String, Set<String>>? bookedSlotsByDate,
    Map<String, Map<String, String>>? discountedSlotsByDate,
    this.weekdayOpeningTime = '06:00 AM',
    this.weekdayClosingTime = '10:00 PM',
    this.weekendOpeningTime = '06:00 AM',
    this.weekendClosingTime = '10:00 PM',
  })  : blockedSlotsByDate = blockedSlotsByDate ?? {},
        bookedSlotsByDate = bookedSlotsByDate ?? {},
        discountedSlotsByDate = discountedSlotsByDate ?? {};

  Set<String> getBlockedSlotsForDate(String dateKey) {
    return blockedSlotsByDate[dateKey] ?? {};
  }

  Set<String> getBookedSlotsForDate(String dateKey) {
    return bookedSlotsByDate[dateKey] ?? {};
  }

  Map<String, String> getDiscountedSlotsForDate(String dateKey) {
    return discountedSlotsByDate[dateKey] ?? {};
  }

  AdminSlotState copyWith({
    Map<String, Set<String>>? blockedSlotsByDate,
    Map<String, Set<String>>? bookedSlotsByDate,
    Map<String, Map<String, String>>? discountedSlotsByDate,
    String? weekdayOpeningTime,
    String? weekdayClosingTime,
    String? weekendOpeningTime,
    String? weekendClosingTime,
  }) {
    return AdminSlotState(
      blockedSlotsByDate: blockedSlotsByDate ?? this.blockedSlotsByDate,
      bookedSlotsByDate: bookedSlotsByDate ?? this.bookedSlotsByDate,
      discountedSlotsByDate: discountedSlotsByDate ?? this.discountedSlotsByDate,
      weekdayOpeningTime: weekdayOpeningTime ?? this.weekdayOpeningTime,
      weekdayClosingTime: weekdayClosingTime ?? this.weekdayClosingTime,
      weekendOpeningTime: weekendOpeningTime ?? this.weekendOpeningTime,
      weekendClosingTime: weekendClosingTime ?? this.weekendClosingTime,
    );
  }
}

class AdminSlotNotifier extends Notifier<AdminSlotState> {
  @override
  AdminSlotState build() => AdminSlotState();

  void setSlotsForDate(String dateKey, {Set<String>? booked, Set<String>? blocked, Map<String, String>? offers}) {
    final currentBooked = Map<String, Set<String>>.from(state.bookedSlotsByDate);
    final currentBlocked = Map<String, Set<String>>.from(state.blockedSlotsByDate);
    final currentOffers = Map<String, Map<String, String>>.from(state.discountedSlotsByDate);
    if (booked != null) currentBooked[dateKey] = booked;
    if (blocked != null) currentBlocked[dateKey] = blocked;
    if (offers != null) currentOffers[dateKey] = offers;
    state = state.copyWith(
      bookedSlotsByDate: currentBooked,
      blockedSlotsByDate: currentBlocked,
      discountedSlotsByDate: currentOffers,
    );
  }

  Future<void> fetchSlotsForDate(int adminId, String dateKey) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/turfs/$adminId/slots?date=$dateKey&role=owner'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['slots'] is List) {
          final booked = <String>{};
          final blocked = <String>{};
          final offers = <String, String>{};
          for (final s in json['slots']) {
            final slotStr = (s['slot'] ?? s['time'])?.toString() ?? '';
            final status = s['status']?.toString();
            if (status == 'booked') booked.add(slotStr);
            if (status == 'blocked') blocked.add(slotStr);
            final offerTag = s['offerTag']?.toString();
            if (offerTag != null && offerTag.isNotEmpty) {
              offers[slotStr] = offerTag;
            }
          }
          setSlotsForDate(dateKey, booked: booked, blocked: blocked, offers: offers);
        }
      }
    } catch (e) {
      debugPrint("Error fetching realtime slots: $e");
    }
  }

  Future<bool> toggleSlotOfferRealtime(int adminId, String slot, String offerString, String dateKey) async {
    toggleSlotDiscount(slot, offerString, dateKey);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/turfs/$adminId/slot-offer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': dateKey,
          'timeSlot': slot,
          'offerString': offerString,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      } else {
        fetchSlotsForDate(adminId, dateKey);
        return false;
      }
    } catch (e) {
      debugPrint("Error saving slot offer in DB: $e");
      fetchSlotsForDate(adminId, dateKey);
      return false;
    }
  }

  Future<bool> toggleBlockSlotRealtime(int adminId, String slot, String dateKey) async {
    if (state.getBookedSlotsForDate(dateKey).contains(slot)) {
      debugPrint("Cannot block slot $slot: already booked by customer.");
      return false;
    }

    toggleBlockSlot(slot, dateKey);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/turfs/$adminId/toggle-block'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': dateKey,
          'timeSlot': slot,
          'reason': 'Blocked by Turf Owner',
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      } else {
        toggleBlockSlot(slot, dateKey);
        return false;
      }
    } catch (e) {
      debugPrint("Error toggling block slot in DB: $e");
      toggleBlockSlot(slot, dateKey);
      return false;
    }
  }

  void toggleBlockSlot(String timeSlot, String dateKey) {
    final currentBlockedMap = Map<String, Set<String>>.from(state.blockedSlotsByDate);
    final dateBlocked = Set<String>.from(currentBlockedMap[dateKey] ?? {});
    
    if (dateBlocked.contains(timeSlot)) {
      dateBlocked.remove(timeSlot);
    } else {
      dateBlocked.add(timeSlot);
    }
    
    currentBlockedMap[dateKey] = dateBlocked;
    state = state.copyWith(blockedSlotsByDate: currentBlockedMap);
  }

  void toggleSlotDiscount(String timeSlot, String offerText, String dateKey) {
    final currentOffersMap = Map<String, Map<String, String>>.from(state.discountedSlotsByDate);
    final dateOffers = Map<String, String>.from(currentOffersMap[dateKey] ?? {});
    
    if (dateOffers.containsKey(timeSlot)) {
      if (offerText.isEmpty || dateOffers[timeSlot] == offerText) {
        dateOffers.remove(timeSlot);
      } else {
        dateOffers[timeSlot] = offerText;
      }
    } else {
      if (offerText.isNotEmpty) {
        dateOffers[timeSlot] = offerText;
      }
    }
    
    currentOffersMap[dateKey] = dateOffers;
    state = state.copyWith(discountedSlotsByDate: currentOffersMap);
  }

  void updateOperatingHours(String wkdayOpen, String wkdayClose, String wkendOpen, String wkendClose) {
    state = state.copyWith(
      weekdayOpeningTime: wkdayOpen,
      weekdayClosingTime: wkdayClose,
      weekendOpeningTime: wkendOpen,
      weekendClosingTime: wkendClose,
    );
  }

  void reserveTournamentSlots(String dateKey, List<String> slots, String tournamentTitle) {
    final currentBlockedMap = Map<String, Set<String>>.from(state.blockedSlotsByDate);
    final dateBlocked = Set<String>.from(currentBlockedMap[dateKey] ?? {});
    dateBlocked.addAll(slots);
    currentBlockedMap[dateKey] = dateBlocked;

    final currentOffersMap = Map<String, Map<String, String>>.from(state.discountedSlotsByDate);
    final dateOffers = Map<String, String>.from(currentOffersMap[dateKey] ?? {});
    for (final s in slots) {
      dateOffers[s] = 'PERCENT|0|Reserved for $tournamentTitle 🏆';
    }
    currentOffersMap[dateKey] = dateOffers;

    state = state.copyWith(
      blockedSlotsByDate: currentBlockedMap,
      discountedSlotsByDate: currentOffersMap,
    );
  }
}

final adminSlotProvider =
    NotifierProvider<AdminSlotNotifier, AdminSlotState>(
  () => AdminSlotNotifier(),
);

// Admin Mode Active State Provider
class AdminModeNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggleMode() => state = !state;
  void setMode(bool value) => state = value;
}

final isAdminModeProvider = NotifierProvider<AdminModeNotifier, bool>(
  () => AdminModeNotifier(),
);

// Models for Turf Owner Profile
class TurfBookingHistoryItem {
  final String id;
  final String customerName;
  final String customerPhone;
  final String sport;
  final String courtName;
  final String date;
  final String timeSlot;
  final String dateTimeSlot;
  final double amount;
  final String paymentMethod;
  final String status; // 'Confirmed', 'Completed', 'Cancelled'
  final bool isOpenMatch;
  final String? teamName;
  final String? openMatchStatus;

  const TurfBookingHistoryItem({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.sport,
    required this.courtName,
    this.date = '',
    this.timeSlot = '',
    required this.dateTimeSlot,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.isOpenMatch = false,
    this.teamName,
    this.openMatchStatus,
  });

  String get effectiveDate {
    if (date.trim().isNotEmpty) return date.trim();
    if (dateTimeSlot.contains(',')) {
      return dateTimeSlot.split(',')[0].trim();
    }
    return '';
  }

  String get effectiveTimeSlot {
    if (timeSlot.trim().isNotEmpty) return timeSlot.trim();
    if (dateTimeSlot.contains(',')) {
      final idx = dateTimeSlot.indexOf(',');
      return dateTimeSlot.substring(idx + 1).trim();
    }
    return dateTimeSlot.trim();
  }

  static int parseSlotEndMinutes(String slotStr) {
    if (slotStr.trim().isEmpty) return -1;
    final slotList = slotStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final lastSlot = slotList.isNotEmpty ? slotList.last : slotStr;
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

  static int parseSlotStartMinutes(String slotStr) {
    if (slotStr.trim().isEmpty) return -1;
    final slotList = slotStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final firstSlot = slotList.isNotEmpty ? slotList.first : slotStr;
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

  bool isCompleted([DateTime? nowTime]) {
    final now = nowTime ?? DateTime.now();
    final s = status.toLowerCase();
    if (s == 'cancelled') return false;
    if (s == 'completed') return true;

    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final d = effectiveDate;

    if (d.isNotEmpty) {
      if (d.toLowerCase() == 'yesterday') return true;
      if (d.toLowerCase() == 'tomorrow') return false;
      if (d.compareTo(todayStr) < 0) return true;
      if (d.compareTo(todayStr) > 0) return false;
    }

    final endMin = parseSlotEndMinutes(effectiveTimeSlot);
    if (endMin == -1) return false;
    final currentMin = now.hour * 60 + now.minute;
    return currentMin >= endMin;
  }

  bool isLiveNow([DateTime? nowTime]) {
    final now = nowTime ?? DateTime.now();
    final s = status.toLowerCase();
    if (s == 'cancelled') return false;
    if (isCompleted(now)) return false;

    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final d = effectiveDate;

    if (d.isNotEmpty && d.toLowerCase() != 'today' && d != todayStr) {
      return false;
    }

    final startMin = parseSlotStartMinutes(effectiveTimeSlot);
    final endMin = parseSlotEndMinutes(effectiveTimeSlot);
    if (startMin == -1 || endMin == -1) return false;

    final currentMin = now.hour * 60 + now.minute;
    return currentMin >= startMin && currentMin < endMin;
  }

  bool isUpcoming([DateTime? nowTime]) {
    final now = nowTime ?? DateTime.now();
    final s = status.toLowerCase();
    if (s == 'cancelled') return false;
    if (isCompleted(now)) return false;
    if (isLiveNow(now)) return false;
    return true;
  }

  bool get isCancelled => status.toLowerCase() == 'cancelled';
}

class TurfCourtVenueItem {
  final String id;
  final String name;
  final String sport;
  final List<String> sports;
  final String surface;
  final double hourlyRate;
  final String timings;
  final String description;
  final List<String> amenities;
  final List<String> imageUrls;

  const TurfCourtVenueItem({
    required this.id,
    required this.name,
    required this.sport,
    this.sports = const [],
    required this.surface,
    required this.hourlyRate,
    required this.timings,
    this.description = '',
    this.amenities = const [],
    this.imageUrls = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sport': sport,
    'sports': sports.isNotEmpty ? sports : (sport.isNotEmpty ? sport.split(RegExp(r'\s*[•,]\s*')).where((s) => s.isNotEmpty).toList() : ['Cricket', 'Football']),
    'surface': surface,
    'hourlyRate': hourlyRate,
    'timings': timings,
    'description': description,
    'amenities': amenities,
    'imageUrls': imageUrls,
  };

  factory TurfCourtVenueItem.fromJson(Map<String, dynamic> json) {
    final rawSports = json['sports'];
    List<String> sportsList = [];
    if (rawSports is List) {
      sportsList = rawSports.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } else if (json['sport'] != null) {
      sportsList = json['sport'].toString().split(RegExp(r'\s*[•,]\s*')).where((s) => s.isNotEmpty).toList();
    }
    final primarySport = sportsList.isNotEmpty ? sportsList.join(' • ') : (json['sport']?.toString() ?? 'Cricket • Football');

    return TurfCourtVenueItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sport: primarySport,
      sports: sportsList.isNotEmpty ? sportsList : ['Cricket', 'Football'],
      surface: json['surface']?.toString() ?? 'Synthetic Turf',
      hourlyRate: (json['hourlyRate'] is num)
          ? (json['hourlyRate'] as num).toDouble()
          : (double.tryParse(json['hourlyRate']?.toString() ?? '') ?? 1000.0),
      timings: json['timings']?.toString() ?? '06:00 AM - 11:00 PM',
      description: json['description']?.toString() ?? '',
      amenities: (json['amenities'] is List) ? (json['amenities'] as List).map((e) => e.toString()).toList() : const [],
      imageUrls: (json['imageUrls'] is List) ? (json['imageUrls'] as List).map((e) => e.toString()).toList() : const [],
    );
  }
}

class TurfSportItem {
  final String name;
  final double hourlyRate;
  final double weekdayRate;
  final double weekendRate;
  final double nightRate;
  final int courtsAvailable;

  const TurfSportItem({
    required this.name,
    required this.hourlyRate,
    this.weekdayRate = 1200.0,
    this.weekendRate = 1600.0,
    this.nightRate = 1400.0,
    required this.courtsAvailable,
  });

  TurfSportItem copyWith({
    String? name,
    double? hourlyRate,
    double? weekdayRate,
    double? weekendRate,
    double? nightRate,
    int? courtsAvailable,
  }) {
    return TurfSportItem(
      name: name ?? this.name,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      weekdayRate: weekdayRate ?? this.weekdayRate,
      weekendRate: weekendRate ?? this.weekendRate,
      nightRate: nightRate ?? this.nightRate,
      courtsAvailable: courtsAvailable ?? this.courtsAvailable,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'hourlyRate': hourlyRate,
    'weekdayRate': weekdayRate,
    'weekendRate': weekendRate,
    'nightRate': nightRate,
    'courtsAvailable': courtsAvailable,
  };

  factory TurfSportItem.fromJson(Map<String, dynamic> json) => TurfSportItem(
    name: json['name']?.toString() ?? 'Football',
    hourlyRate: (json['hourlyRate'] is num)
        ? (json['hourlyRate'] as num).toDouble()
        : (double.tryParse(json['hourlyRate']?.toString() ?? '') ?? 1000.0),
    weekdayRate: (json['weekdayRate'] is num)
        ? (json['weekdayRate'] as num).toDouble()
        : (double.tryParse(json['weekdayRate']?.toString() ?? '') ?? 1200.0),
    weekendRate: (json['weekendRate'] is num)
        ? (json['weekendRate'] as num).toDouble()
        : (double.tryParse(json['weekendRate']?.toString() ?? '') ?? 1600.0),
    nightRate: (json['nightRate'] is num)
        ? (json['nightRate'] as num).toDouble()
        : (double.tryParse(json['nightRate']?.toString() ?? '') ?? 1400.0),
    courtsAvailable: (json['courtsAvailable'] is num)
        ? (json['courtsAvailable'] as num).toInt()
        : (int.tryParse(json['courtsAvailable']?.toString() ?? '') ?? 2),
  );
}

class SubscriptionPaymentItem {
  final String id;
  final String date;
  final double baseAmount;
  final double gstAmount;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final String validPeriod;
  final String receiptNumber;

  const SubscriptionPaymentItem({
    required this.id,
    required this.date,
    required this.baseAmount,
    required this.gstAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.validPeriod,
    required this.receiptNumber,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'baseAmount': baseAmount,
    'gstAmount': gstAmount,
    'totalAmount': totalAmount,
    'paymentMethod': paymentMethod,
    'status': status,
    'validPeriod': validPeriod,
    'receiptNumber': receiptNumber,
  };

  factory SubscriptionPaymentItem.fromJson(Map<String, dynamic> json) => SubscriptionPaymentItem(
    id: json['id']?.toString() ?? 'SUB-01',
    date: json['date']?.toString() ?? '07 Nov 2026',
    baseAmount: (json['baseAmount'] is num) ? (json['baseAmount'] as num).toDouble() : 1000.0,
    gstAmount: (json['gstAmount'] is num) ? (json['gstAmount'] as num).toDouble() : 180.0,
    totalAmount: (json['totalAmount'] is num) ? (json['totalAmount'] as num).toDouble() : 1180.0,
    paymentMethod: json['paymentMethod']?.toString() ?? 'UPI (GPay)',
    status: json['status']?.toString() ?? 'Paid & Active',
    validPeriod: json['validPeriod']?.toString() ?? '07 Nov 2026 - 07 Dec 2026',
    receiptNumber: json['receiptNumber']?.toString() ?? 'RCP-SUB-84920',
  );
}

class OwnerTurfBranchItem {
  final int id;
  final String venueName;
  final String neighborhoodArea;
  final String streetAddress;
  final String ownerPhone;
  final String status;
  final int todayBookingsCount;
  final double todayRevenue;
  final double monthRevenue;
  final int monthTotalBookings;
  final bool isActive;

  const OwnerTurfBranchItem({
    required this.id,
    required this.venueName,
    required this.neighborhoodArea,
    required this.streetAddress,
    required this.ownerPhone,
    required this.status,
    required this.todayBookingsCount,
    required this.todayRevenue,
    required this.monthRevenue,
    required this.monthTotalBookings,
    required this.isActive,
  });

  factory OwnerTurfBranchItem.fromJson(Map<String, dynamic> json) => OwnerTurfBranchItem(
    id: (json['id'] is num) ? (json['id'] as num).toInt() : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
    venueName: json['venueName']?.toString() ?? '',
    neighborhoodArea: json['neighborhoodArea']?.toString() ?? 'Main Branch',
    streetAddress: json['streetAddress']?.toString() ?? '',
    ownerPhone: json['ownerPhone']?.toString() ?? '',
    status: json['status']?.toString() ?? 'VERIFIED',
    todayBookingsCount: int.tryParse(json['todayBookingsCount']?.toString() ?? '') ?? 0,
    todayRevenue: double.tryParse(json['todayRevenue']?.toString() ?? '') ?? 0.0,
    monthRevenue: double.tryParse(json['monthRevenue']?.toString() ?? '') ?? 0.0,
    monthTotalBookings: int.tryParse(json['monthTotalBookings']?.toString() ?? '') ?? 0,
    isActive: json['isActive'] == true,
  );
}

class TurfProfileState {
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String venueName;
  final String address;
  final String area;
  final List<OwnerTurfBranchItem> branches;
  final String openingTime;
  final String closingTime;
  final String weekdayOpeningTime;
  final String weekdayClosingTime;
  final String weekendOpeningTime;
  final String weekendClosingTime;
  final double dayRate;
  final double nightRate;
  final double weekdayRate;
  final double weekendRate;
  final List<String> facilities;
  final List<TurfSportItem> sports;
  final List<TurfCourtVenueItem> courts;
  final List<TurfBookingHistoryItem> bookingHistory;
  final List<String> photoUrls;
  final String? trackingCode;
  final int? adminUserId;
  final int? verifiedAdminId;
  final String? aadhaarDocUrl;
  final String? panDocUrl;
  final String? gstDocUrl;

  // Non-editable Locked KYC details
  final String gstin;
  final String pan;
  final String aadhaar;
  final String bankAccount;
  final String ifsc;
  final String upiId;
  final bool kycVerified;

  // Realtime Venue Performance KPIs from VerifiedAdmin Database Table
  final int todayBookingsCount;
  final int todayPaidBookings;
  final int todayCashBookings;
  final double todayRevenue;
  final String todayBookingsGrowth;
  final double monthRevenue;
  final int monthTotalBookings;
  final String revenueBadge;
  final double monthlyRevenueTarget;
  final int freeSlotsCount;
  final int bookedSlotsCount;
  final int blockedSlotsCount;
  final String slotsBadge;
  final int cancelledTotal;
  final int cancelledCount;
  final int shiftedCount;
  final String cancelledBadge;

  // Monthly Platform Subscription Details (₹1,000 + 18% GST = ₹1,180)
  final bool _isSubscriptionActive;
  final String _subscriptionStatus;
  final double subscriptionBaseFee;
  final double subscriptionGstFee;
  final double subscriptionTotalFee;
  final String subscriptionStartDate;
  final String subscriptionRenewDate;
  final bool isBookingHold;
  final int _subscriptionDaysRemaining;
  final List<SubscriptionPaymentItem> subscriptionHistory;

  int get turfId => verifiedAdminId ?? adminUserId ?? 1;

  DateTime? get subscriptionRenewDateTime {
    try {
      final clean = subscriptionRenewDate.trim();
      if (clean.isEmpty) return null;
      try {
        return DateFormat('dd MMM yyyy').parse(clean);
      } catch (_) {
        return DateTime.tryParse(clean);
      }
    } catch (_) {
      return null;
    }
  }

  DateTime? get subscriptionStartDateTime {
    try {
      final clean = subscriptionStartDate.trim();
      if (clean.isEmpty) return null;
      try {
        return DateFormat('dd MMM yyyy').parse(clean);
      } catch (_) {
        return DateTime.tryParse(clean);
      }
    } catch (_) {
      return null;
    }
  }

  int get subscriptionDaysRemaining {
    if (isBookingHold) return 0;
    final renew = subscriptionRenewDateTime;
    if (renew != null) {
      final now = DateTime.now();
      final nowDateOnly = DateTime(now.year, now.month, now.day);
      final renewDateOnly = DateTime(renew.year, renew.month, renew.day);
      final diff = renewDateOnly.difference(nowDateOnly).inDays;
      return diff < 0 ? 0 : diff;
    }
    return _subscriptionDaysRemaining;
  }

  bool get isSubscriptionActive {
    if (isBookingHold) return false;
    if (subscriptionDaysRemaining <= 0) return false;
    return _isSubscriptionActive;
  }

  String get subscriptionStatus {
    return isSubscriptionActive ? 'ACTIVE' : 'EXPIRED';
  }

  bool get isSubscriptionEndingSoon =>
      isSubscriptionActive && !isBookingHold && subscriptionDaysRemaining <= 3 && subscriptionDaysRemaining > 0;

  bool get isSubscriptionBlocked =>
      !isSubscriptionActive || isBookingHold || subscriptionDaysRemaining <= 0;

  const TurfProfileState({
    this.ownerName = 'Karthikeyan M',
    this.ownerPhone = '+91 98765 43210',
    this.ownerEmail = 'karthik@championsarena.in',
    this.venueName = 'Madurai Champions Turf Hub',
    this.address = 'No. 42, 80 Feet Road, KK Nagar, Madurai',
    this.area = 'KK Nagar',
    this.openingTime = '06:00 AM',
    this.closingTime = '11:30 PM',
    this.weekdayOpeningTime = '06:00 AM',
    this.weekdayClosingTime = '11:00 PM',
    this.weekendOpeningTime = '05:00 AM',
    this.weekendClosingTime = '11:30 PM',
    this.dayRate = 1000.0,
    this.nightRate = 1400.0,
    this.weekdayRate = 1200.0,
    this.weekendRate = 1600.0,
    this.facilities = const [
      'Drinking Water',
      'Parking',
      'Toilets',
      'Floodlights',
      'Changing Rooms',
      'First Aid',
    ],
    this.photoUrls = const [],
    this.trackingCode,
    this.adminUserId,
    this.verifiedAdminId = 1,
    this.aadhaarDocUrl,
    this.panDocUrl,
    this.gstDocUrl,
    this.sports = const [
      TurfSportItem(name: 'Cricket', hourlyRate: 1000.0, courtsAvailable: 1),
      TurfSportItem(name: 'Football', hourlyRate: 1400.0, courtsAvailable: 1),
    ],
    this.courts = const [
      TurfCourtVenueItem(
        id: 'CR-01',
        name: 'Main Ground',
        sport: 'Football',
        surface: 'Synthetic Turf',
        hourlyRate: 1200.0,
        timings: '06:00 AM - 11:00 PM',
      ),
    ],
    this.bookingHistory = const [],
    this.gstin = '33AAACM1234F1Z8',
    this.pan = 'ABCDE1234F',
    this.aadhaar = '1234 5678 9012',
    this.bankAccount = '91802003881234',
    this.ifsc = 'HDFC0001234',
    this.upiId = 'karthik@okaxis',
    this.kycVerified = true,
    this.todayBookingsCount = 0,
    this.todayPaidBookings = 0,
    this.todayCashBookings = 0,
    this.todayRevenue = 0.0,
    this.branches = const [],
    this.todayBookingsGrowth = '0% Today',
    this.monthRevenue = 0.0,
    this.monthTotalBookings = 0,
    this.revenueBadge = '₹0 GMV',
    this.monthlyRevenueTarget = 50000.0,
    this.freeSlotsCount = 0,
    this.bookedSlotsCount = 0,
    this.blockedSlotsCount = 0,
    this.slotsBadge = '0% Full',
    this.cancelledTotal = 0,
    this.cancelledCount = 0,
    this.shiftedCount = 0,
    this.cancelledBadge = 'Tracked',
    bool isSubscriptionActive = true,
    String subscriptionStatus = 'ACTIVE',
    this.subscriptionBaseFee = 1000.0,
    this.subscriptionGstFee = 180.0,
    this.subscriptionTotalFee = 1180.0,
    this.subscriptionStartDate = '07 Nov 2026',
    this.subscriptionRenewDate = '07 Dec 2026',
    this.isBookingHold = false,
    int subscriptionDaysRemaining = 30,
    this.subscriptionHistory = const [
      SubscriptionPaymentItem(
        id: 'SUB-2026-11',
        date: '07 Nov 2026, 10:15 AM',
        baseAmount: 1000.0,
        gstAmount: 180.0,
        totalAmount: 1180.0,
        paymentMethod: 'UPI (GPay)',
        status: 'Paid & Active',
        validPeriod: '07 Nov 2026 - 07 Dec 2026',
        receiptNumber: 'RCP-SUB-84920',
      ),
      SubscriptionPaymentItem(
        id: 'SUB-2026-10',
        date: '07 Oct 2026, 11:30 AM',
        baseAmount: 1000.0,
        gstAmount: 180.0,
        totalAmount: 1180.0,
        paymentMethod: 'UPI (PhonePe)',
        status: 'Completed',
        validPeriod: '07 Oct 2026 - 07 Nov 2026',
        receiptNumber: 'RCP-SUB-72109',
      ),
    ],
  })  : _isSubscriptionActive = isSubscriptionActive,
        _subscriptionStatus = subscriptionStatus,
        _subscriptionDaysRemaining = subscriptionDaysRemaining;

  TurfProfileState copyWith({
    String? ownerName,
    String? ownerPhone,
    String? ownerEmail,
    String? venueName,
    String? address,
    String? area,
    String? openingTime,
    String? closingTime,
    String? weekdayOpeningTime,
    String? weekdayClosingTime,
    String? weekendOpeningTime,
    String? weekendClosingTime,
    double? dayRate,
    double? nightRate,
    double? weekdayRate,
    double? weekendRate,
    List<String>? facilities,
    List<TurfSportItem>? sports,
    List<TurfCourtVenueItem>? courts,
    List<TurfBookingHistoryItem>? bookingHistory,
    List<String>? photoUrls,
    String? trackingCode,
    int? adminUserId,
    int? verifiedAdminId,
    String? aadhaarDocUrl,
    String? panDocUrl,
    String? gstDocUrl,
    String? gstin,
    String? pan,
    String? aadhaar,
    String? bankAccount,
    String? ifsc,
    String? upiId,
    bool? kycVerified,
    int? todayBookingsCount,
    int? todayPaidBookings,
    int? todayCashBookings,
    double? todayRevenue,
    List<OwnerTurfBranchItem>? branches,
    String? todayBookingsGrowth,
    double? monthRevenue,
    int? monthTotalBookings,
    String? revenueBadge,
    double? monthlyRevenueTarget,
    int? freeSlotsCount,
    int? bookedSlotsCount,
    int? blockedSlotsCount,
    String? slotsBadge,
    int? cancelledTotal,
    int? cancelledCount,
    int? shiftedCount,
    String? cancelledBadge,
    bool? isSubscriptionActive,
    String? subscriptionStatus,
    double? subscriptionBaseFee,
    double? subscriptionGstFee,
    double? subscriptionTotalFee,
    String? subscriptionStartDate,
    String? subscriptionRenewDate,
    bool? isBookingHold,
    int? subscriptionDaysRemaining,
    List<SubscriptionPaymentItem>? subscriptionHistory,
  }) {
    return TurfProfileState(
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      area: area ?? this.area,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      weekdayOpeningTime: weekdayOpeningTime ?? this.weekdayOpeningTime,
      weekdayClosingTime: weekdayClosingTime ?? this.weekdayClosingTime,
      weekendOpeningTime: weekendOpeningTime ?? this.weekendOpeningTime,
      weekendClosingTime: weekendClosingTime ?? this.weekendClosingTime,
      dayRate: dayRate ?? this.dayRate,
      nightRate: nightRate ?? this.nightRate,
      weekdayRate: weekdayRate ?? this.weekdayRate,
      weekendRate: weekendRate ?? this.weekendRate,
      facilities: facilities ?? this.facilities,
      sports: sports ?? this.sports,
      courts: courts ?? this.courts,
      bookingHistory: bookingHistory ?? this.bookingHistory,
      photoUrls: photoUrls ?? this.photoUrls,
      trackingCode: trackingCode ?? this.trackingCode,
      adminUserId: adminUserId ?? this.adminUserId,
      verifiedAdminId: verifiedAdminId ?? this.verifiedAdminId,
      aadhaarDocUrl: aadhaarDocUrl ?? this.aadhaarDocUrl,
      panDocUrl: panDocUrl ?? this.panDocUrl,
      gstDocUrl: gstDocUrl ?? this.gstDocUrl,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      aadhaar: aadhaar ?? this.aadhaar,
      bankAccount: bankAccount ?? this.bankAccount,
      ifsc: ifsc ?? this.ifsc,
      upiId: upiId ?? this.upiId,
      kycVerified: kycVerified ?? this.kycVerified,
      todayBookingsCount: todayBookingsCount ?? this.todayBookingsCount,
      todayPaidBookings: todayPaidBookings ?? this.todayPaidBookings,
      todayCashBookings: todayCashBookings ?? this.todayCashBookings,
      todayRevenue: todayRevenue ?? this.todayRevenue,
      branches: branches ?? this.branches,
      todayBookingsGrowth: todayBookingsGrowth ?? this.todayBookingsGrowth,
      monthRevenue: monthRevenue ?? this.monthRevenue,
      monthTotalBookings: monthTotalBookings ?? this.monthTotalBookings,
      revenueBadge: revenueBadge ?? this.revenueBadge,
      monthlyRevenueTarget: monthlyRevenueTarget ?? this.monthlyRevenueTarget,
      freeSlotsCount: freeSlotsCount ?? this.freeSlotsCount,
      bookedSlotsCount: bookedSlotsCount ?? this.bookedSlotsCount,
      blockedSlotsCount: blockedSlotsCount ?? this.blockedSlotsCount,
      slotsBadge: slotsBadge ?? this.slotsBadge,
      cancelledTotal: cancelledTotal ?? this.cancelledTotal,
      cancelledCount: cancelledCount ?? this.cancelledCount,
      shiftedCount: shiftedCount ?? this.shiftedCount,
      cancelledBadge: cancelledBadge ?? this.cancelledBadge,
      isSubscriptionActive: isSubscriptionActive ?? _isSubscriptionActive,
      subscriptionStatus: subscriptionStatus ?? _subscriptionStatus,
      subscriptionBaseFee: subscriptionBaseFee ?? this.subscriptionBaseFee,
      subscriptionGstFee: subscriptionGstFee ?? this.subscriptionGstFee,
      subscriptionTotalFee: subscriptionTotalFee ?? this.subscriptionTotalFee,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionRenewDate: subscriptionRenewDate ?? this.subscriptionRenewDate,
      isBookingHold: isBookingHold ?? this.isBookingHold,
      subscriptionDaysRemaining: subscriptionDaysRemaining ?? _subscriptionDaysRemaining,
      subscriptionHistory: subscriptionHistory ?? this.subscriptionHistory,
    );
  }
}

class TurfProfileNotifier extends Notifier<TurfProfileState> {
  @override
  TurfProfileState build() {
    _loadFromStorage();
    return const TurfProfileState();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTarget = prefs.getDouble('owner_monthly_revenue_target');
      if (savedTarget != null && savedTarget > 0) {
        state = state.copyWith(monthlyRevenueTarget: savedTarget);
      }
      final savedJson = prefs.getString('verified_admin_data');
      if (savedJson != null && savedJson.isNotEmpty) {
        final data = jsonDecode(savedJson);
        if (data is Map<String, dynamic>) {
          setFromVerifiedAdmin(data, saveToStorage: false);
        }
      }
      final savedRenewDate = prefs.getString('owner_subscription_renew_date');
      final savedStartDate = prefs.getString('owner_subscription_start_date');
      final savedHold = prefs.getBool('owner_subscription_hold');
      if (savedRenewDate != null && savedRenewDate.isNotEmpty) {
        state = state.copyWith(
          subscriptionRenewDate: savedRenewDate,
          subscriptionStartDate: savedStartDate ?? state.subscriptionStartDate,
          isBookingHold: savedHold ?? state.isBookingHold,
        );
      }
      final savedHistory = prefs.getString('subscription_history');
      if (savedHistory != null && savedHistory.isNotEmpty) {
        final List hList = jsonDecode(savedHistory);
        final history = hList.map((i) => SubscriptionPaymentItem.fromJson(Map<String, dynamic>.from(i))).toList();
        state = state.copyWith(subscriptionHistory: history);
      }
      final savedSports = prefs.getString('owner_sports_data');
      if (savedSports != null && savedSports.isNotEmpty) {
        final List sList = jsonDecode(savedSports);
        final sports = sList.map((i) => TurfSportItem.fromJson(Map<String, dynamic>.from(i))).toList();
        if (sports.isNotEmpty) {
          state = state.copyWith(sports: sports);
        }
      }
      final savedWkdayRate = prefs.getDouble('owner_weekday_rate');
      final savedWkendRate = prefs.getDouble('owner_weekend_rate');
      final savedDayRate = prefs.getDouble('owner_day_rate');
      final savedNightRate = prefs.getDouble('owner_night_rate');
      final savedWkOpen = prefs.getString('owner_weekday_open');
      final savedWkClose = prefs.getString('owner_weekday_close');
      final savedWkendOpen = prefs.getString('owner_weekend_open');
      final savedWkendClose = prefs.getString('owner_weekend_close');
      if (savedWkdayRate != null || savedWkendRate != null || savedDayRate != null || savedNightRate != null || savedWkOpen != null) {
        state = state.copyWith(
          weekdayRate: savedWkdayRate ?? state.weekdayRate,
          weekendRate: savedWkendRate ?? state.weekendRate,
          dayRate: savedDayRate ?? state.dayRate,
          nightRate: savedNightRate ?? state.nightRate,
          weekdayOpeningTime: savedWkOpen ?? state.weekdayOpeningTime,
          weekdayClosingTime: savedWkClose ?? state.weekdayClosingTime,
          weekendOpeningTime: savedWkendOpen ?? state.weekendOpeningTime,
          weekendClosingTime: savedWkendClose ?? state.weekendClosingTime,
        );
      }
      final phone = prefs.getString('owner_phone');
      final savedTurfId = prefs.getInt('selected_turf_id');
      if (phone != null && phone.isNotEmpty) {
        await fetchVerifiedAdminByPhone(phone, turfId: savedTurfId);
      }
    } catch (e) {
      debugPrint("Error loading admin from storage: $e");
    }
  }

  Future<void> fetchVerifiedAdminByPhone(String phone, {int? turfId}) async {
    try {
      final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final url = turfId != null
          ? '${ApiConfig.baseUrl}/auth/verified-admin/$clean?turfId=$turfId'
          : '${ApiConfig.baseUrl}/auth/verified-admin/$clean';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['admin'] != null && json['admin'] is Map<String, dynamic>) {
          final adminData = json['admin'] as Map<String, dynamic>;
          if (json['branches'] is List) {
            adminData['branches'] = json['branches'];
          }
          setFromVerifiedAdmin(adminData);
        }
      }
    } catch (e) {
      debugPrint("Error fetching verified admin: $e");
    }
  }

  Future<void> switchBranch(int branchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_turf_id', branchId);
    await fetchVerifiedAdminByPhone(state.ownerPhone, turfId: branchId);
  }

  Future<bool> addNewBranch({
    required String venueName,
    required String neighborhoodArea,
    required String streetAddress,
    required String alternativePhone,
    double? dayRate,
    double? nightRate,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verified-admin/add-branch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ownerPhone': state.ownerPhone,
          'venueName': venueName,
          'neighborhoodArea': neighborhoodArea,
          'streetAddress': streetAddress,
          'alternativePhone': alternativePhone,
          'dayRate': dayRate ?? 1000.0,
          'nightRate': nightRate ?? 1400.0,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        final newBranchId = json['branch']?['id'];
        if (newBranchId != null) {
          final intId = (newBranchId is num) ? newBranchId.toInt() : int.tryParse(newBranchId.toString()) ?? 0;
          await switchBranch(intId);
        } else {
          await fetchVerifiedAdminByPhone(state.ownerPhone);
        }
        return true;
      }
    } catch (e) {
      debugPrint("Error adding new branch: $e");
    }
    return false;
  }

  void setFromVerifiedAdmin(Map<String, dynamic> data, {bool saveToStorage = true}) {
    final venueName = (data['venueName'] ?? 'Turf Arena').toString();
    final ownerName = (data['ownerName'] ?? 'Turf Owner').toString();
    final ownerPhone = (data['ownerPhone'] ?? '').toString();
    final ownerEmail = (data['ownerEmail'] ?? '').toString();
    final streetAddress = (data['streetAddress'] ?? '').toString();
    final neighborhoodArea = (data['neighborhoodArea'] ?? '').toString();
    final trackingCode = data['trackingCode']?.toString();
    final verifiedAdminId = (data['id'] is int)
        ? data['id'] as int
        : (int.tryParse(data['id']?.toString() ?? '') ?? 1);
    final adminUserId = data['adminUserId'] is int ? data['adminUserId'] as int : verifiedAdminId;

    List<String> photoUrls = [];
    if (data['photoUrls'] is List) {
      photoUrls = (data['photoUrls'] as List).map((e) => e.toString()).toList();
    }

    List<String> amenities = [];
    if (data['amenities'] is List && (data['amenities'] as List).isNotEmpty) {
      amenities = (data['amenities'] as List).map((e) => e.toString()).toList();
    } else {
      amenities = [
        'Drinking Water',
        'Parking',
        'Toilets',
        'Floodlights',
        'Changing Rooms',
        'First Aid',
      ];
    }

    final gstin = (data['gstin'] != null && data['gstin'].toString().isNotEmpty)
        ? data['gstin'].toString()
        : 'Not Registered';
    final pan = data['panNumber']?.toString() ?? 'ABCDE1234F';
    final aadhaar = data['aadhaarNumber']?.toString() ?? '1234 5678 9012';
    final bankAccount = data['bankAccount']?.toString() ?? '91802003881234';
    final ifsc = data['ifscCode']?.toString() ?? 'HDFC0001234';
    final upiId = data['upiId']?.toString() ?? '$ownerPhone@upi';
    final aadhaarDocUrl = data['aadhaarDocUrl']?.toString();
    final panDocUrl = data['panDocUrl']?.toString();
    final gstDocUrl = data['gstDocUrl']?.toString();
    final dayRate = double.tryParse(data['dayRate']?.toString() ?? '') ??
        double.tryParse(data['weekdayRate']?.toString() ?? '') ??
        state.dayRate;

    // Parse real dynamic sports configured for this turf if provided
    List<TurfSportItem> parsedSports = [];
    if (data['sportsList'] is List && (data['sportsList'] as List).isNotEmpty) {
      parsedSports = (data['sportsList'] as List).map((i) {
        if (i is Map<String, dynamic>) return TurfSportItem.fromJson(i);
        if (i is Map) return TurfSportItem.fromJson(Map<String, dynamic>.from(i));
        return TurfSportItem(name: i.toString(), hourlyRate: 1000.0, courtsAvailable: 2);
      }).toList();
    } else if (data['sports'] is List && (data['sports'] as List).isNotEmpty) {
      parsedSports = (data['sports'] as List).map((name) {
        return TurfSportItem(name: name.toString(), hourlyRate: 1000.0, courtsAvailable: 2);
      }).toList();
    }

    // Parse dynamic branches if owner has multiple locations/venues
    List<OwnerTurfBranchItem> branches = [];
    if (data['branches'] is List) {
      branches = (data['branches'] as List).map((b) {
        if (b is Map<String, dynamic>) return OwnerTurfBranchItem.fromJson(b);
        if (b is Map) return OwnerTurfBranchItem.fromJson(Map<String, dynamic>.from(b));
        return null;
      }).whereType<OwnerTurfBranchItem>().toList();
    }

    // Dynamically tailored courts based on real venue name or backend configuration
    List<TurfCourtVenueItem> courts = [];
    if (data['courts'] is List && (data['courts'] as List).isNotEmpty) {
      courts = (data['courts'] as List).map((c) {
        if (c is Map) {
          final cName = c['name']?.toString() ?? '';
          final isMockPattern = RegExp(
            r'^(Cricket|Football|Pickle ball|Badminton)\s+Court\s+\d+$',
            caseSensitive: false,
          ).hasMatch(cName.trim());
          if (isMockPattern) return null;

          return TurfCourtVenueItem.fromJson(Map<String, dynamic>.from(c));
        }
        return null;
      }).whereType<TurfCourtVenueItem>().toList();
    }

    if (courts.isEmpty) {
      final availableSportNames = parsedSports.isNotEmpty ? parsedSports.map((s) => s.name).toList() : ['Cricket', 'Football'];
      courts = [
        TurfCourtVenueItem(
          id: 'CR-01',
          name: '$venueName - Main Ground',
          sport: availableSportNames.join(' • '),
          sports: availableSportNames,
          surface: 'Synthetic Turf',
          hourlyRate: dayRate > 0 ? dayRate : 1200.0,
          timings: '06:00 AM - 11:00 PM',
          amenities: amenities,
          imageUrls: photoUrls,
        ),
      ];
    }

    // Real dynamic bookings from database if available, else fallback
    List<TurfBookingHistoryItem> bookingHistory = [];
    if (data['bookings'] is List && (data['bookings'] as List).isNotEmpty) {
      bookingHistory = (data['bookings'] as List).map((b) {
        final amt = (b['amount'] is num) ? (b['amount'] as num).toDouble() : 1000.0;
        final dateVal = (b['date'] ?? '').toString();
        final timeSlotVal = (b['timeSlot'] ?? '').toString();
        final dt = dateVal.isNotEmpty && timeSlotVal.isNotEmpty
            ? "$dateVal, $timeSlotVal"
            : (dateVal.isNotEmpty ? dateVal : timeSlotVal);
        final bookingCode = b['bookingCode']?.toString() ??
            b['bookingId']?.toString() ??
            (b['id'] != null ? 'G24-BK-${b['id'].toString().padLeft(4, '0')}' : 'G24-BK-0001');
        return TurfBookingHistoryItem(
          id: bookingCode,
          customerName: b['customerName']?.toString() ?? 'Player Customer',
          customerPhone: b['customerPhone']?.toString() ?? '',
          sport: b['sport']?.toString() ?? 'Football',
          courtName: b['courtName']?.toString() ?? venueName,
          date: dateVal,
          timeSlot: timeSlotVal,
          dateTimeSlot: dt,
          amount: amt,
          paymentMethod: b['paymentMethod']?.toString() ?? 'UPI (GPay)',
          status: b['status']?.toString() ?? 'Confirmed',
          isOpenMatch: b['isOpenMatch'] == true,
          teamName: b['teamName']?.toString(),
          openMatchStatus: b['openMatchStatus']?.toString(),
        );
      }).toList();
    }

    final dash = (data['dashboard'] is Map<String, dynamic>)
        ? data['dashboard'] as Map<String, dynamic>
        : data;

    final openingTime = (dash['openingTime'] ?? data['openingTime'])?.toString() ?? '05:00 AM';
    final closingTime = (dash['closingTime'] ?? data['closingTime'])?.toString() ?? '11:00 PM';

    final todayBookingsCount = int.tryParse((dash['todayBookingsCount'] ?? data['todayBookingsCount'])?.toString() ?? '') ?? 0;
    int todayPaidBookings = int.tryParse((dash['todayPaidBookings'] ?? data['todayPaidBookings'])?.toString() ?? '') ?? 0;
    int todayCashBookings = int.tryParse((dash['todayCashBookings'] ?? data['todayCashBookings'])?.toString() ?? '') ?? 0;
    int monthTotalBookings = int.tryParse((dash['monthTotalBookings'] ?? data['monthTotalBookings'])?.toString() ?? '') ?? 0;

    // Safety guard: paid + cash cannot exceed total bookings
    if (todayPaidBookings + todayCashBookings > todayBookingsCount && todayBookingsCount > 0) {
      todayPaidBookings = todayBookingsCount - todayCashBookings;
      if (todayPaidBookings < 0) todayPaidBookings = 0;
    }
    if (monthTotalBookings < todayBookingsCount) {
      monthTotalBookings = todayBookingsCount;
    }

    final realCancelledBookings = bookingHistory.where((b) => b.isCancelled).length;
    int parsedCancelledCount = int.tryParse((dash['cancelledCount'] ?? data['cancelledCount'])?.toString() ?? '') ?? 0;
    if (realCancelledBookings > parsedCancelledCount) {
      parsedCancelledCount = realCancelledBookings;
    }
    final parsedShiftedCount = int.tryParse((dash['shiftedCount'] ?? data['shiftedCount'])?.toString() ?? '') ?? 0;
    int parsedCancelledTotal = int.tryParse((dash['cancelledTotal'] ?? data['cancelledTotal'])?.toString() ?? '') ?? 0;
    if (parsedCancelledCount + parsedShiftedCount > parsedCancelledTotal) {
      parsedCancelledTotal = parsedCancelledCount + parsedShiftedCount;
    }

    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final activeTodayBookings = bookingHistory.where((b) {
      if (b.isCancelled) return false;
      final d = b.effectiveDate;
      return d == nowStr || d.toLowerCase() == 'today';
    }).toList();
    final finalTodayBookingsCount = activeTodayBookings.isNotEmpty ? activeTodayBookings.length : todayBookingsCount;

    int activeBookedSlotsCount = 0;
    for (final b in activeTodayBookings) {
      final slotStr = b.effectiveTimeSlot;
      if (slotStr.isNotEmpty) {
        final slots = slotStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        activeBookedSlotsCount += slots.isNotEmpty ? slots.length : 1;
      } else {
        activeBookedSlotsCount += 1;
      }
    }
    if (activeBookedSlotsCount == 0 && finalTodayBookingsCount > 0) {
      activeBookedSlotsCount = finalTodayBookingsCount;
    }

    final totalDailySlots = AppConstants.generateTimeSlots(openingTime, closingTime).length;
    final totalSlotsSafe = totalDailySlots > 0 ? totalDailySlots : 18;
    final blockedSlotsCount = int.tryParse((dash['blockedSlotsCount'] ?? data['blockedSlotsCount'])?.toString() ?? '') ?? 0;

    // Time-aware slot availability: total slots - passed slots - upcoming booked slots = remaining
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    int passedSlotsCount = 0;
    for (final s in AppConstants.generateTimeSlots(openingTime, closingTime)) {
      final startMin = AppConstants.parseSlotStartMinutes(s);
      if (startMin != -1 && currentMinutes >= startMin) {
        passedSlotsCount++;
      }
    }

    int upcomingBookedSlots = 0;
    for (final b in activeTodayBookings) {
      final startMin = TurfBookingHistoryItem.parseSlotStartMinutes(b.effectiveTimeSlot);
      if (startMin == -1 || currentMinutes < startMin) {
        final slotStr = b.effectiveTimeSlot;
        if (slotStr.isNotEmpty) {
          final slots = slotStr.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
          upcomingBookedSlots += slots.isNotEmpty ? slots.length : 1;
        } else {
          upcomingBookedSlots += 1;
        }
      }
    }

    final dynamicRemainingSlots = (totalSlotsSafe - passedSlotsCount - upcomingBookedSlots - blockedSlotsCount) > 0
        ? (totalSlotsSafe - passedSlotsCount - upcomingBookedSlots - blockedSlotsCount)
        : 0;
    final dynamicOccupancyPct = totalSlotsSafe > 0 ? ((activeBookedSlotsCount / totalSlotsSafe.toDouble()) * 100).round() : 0;
    final dynamicSlotsBadge = '$dynamicOccupancyPct% Full';

    state = state.copyWith(
      venueName: venueName,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      ownerEmail: ownerEmail,
      address: streetAddress,
      area: neighborhoodArea,
      openingTime: openingTime,
      closingTime: closingTime,
      weekdayOpeningTime: openingTime,
      weekdayClosingTime: closingTime,
      weekendOpeningTime: openingTime,
      weekendClosingTime: closingTime,
      facilities: amenities,
      photoUrls: photoUrls,
      trackingCode: trackingCode,
      adminUserId: adminUserId,
      verifiedAdminId: verifiedAdminId,
      gstin: gstin,
      pan: pan,
      aadhaar: aadhaar,
      bankAccount: bankAccount,
      ifsc: ifsc,
      upiId: upiId,
      aadhaarDocUrl: aadhaarDocUrl,
      panDocUrl: panDocUrl,
      gstDocUrl: gstDocUrl,
      dayRate: double.tryParse(data['dayRate']?.toString() ?? '') ?? state.dayRate,
      nightRate: double.tryParse(data['nightRate']?.toString() ?? '') ?? state.nightRate,
      weekdayRate: double.tryParse(data['weekdayRate']?.toString() ?? '') ?? state.weekdayRate,
      weekendRate: double.tryParse(data['weekendRate']?.toString() ?? '') ?? state.weekendRate,
      sports: parsedSports.isNotEmpty ? parsedSports : state.sports,
      kycVerified: true,
      courts: courts,
      bookingHistory: bookingHistory,
      todayBookingsCount: finalTodayBookingsCount,
      todayPaidBookings: todayPaidBookings,
      todayCashBookings: todayCashBookings,
      todayRevenue: double.tryParse((dash['todayRevenue'] ?? data['todayRevenue'])?.toString() ?? '') ??
          activeTodayBookings.fold<double>(0.0, (double sum, b) => sum + b.amount),
      branches: branches.isNotEmpty ? branches : state.branches,
      todayBookingsGrowth: (dash['todayBookingsGrowth'] ?? data['todayBookingsGrowth'])?.toString() ?? '0% Today',
      monthRevenue: double.tryParse((dash['monthRevenue'] ?? data['monthRevenue'])?.toString() ?? '') ?? 0.0,
      monthTotalBookings: monthTotalBookings,
      revenueBadge: (dash['revenueBadge'] ?? data['revenueBadge'])?.toString() ?? '₹0 GMV',
      monthlyRevenueTarget: double.tryParse((dash['monthlyRevenueTarget'] ?? data['monthlyRevenueTarget'])?.toString() ?? '') ?? state.monthlyRevenueTarget,
      freeSlotsCount: dynamicRemainingSlots,
      bookedSlotsCount: activeBookedSlotsCount,
      blockedSlotsCount: blockedSlotsCount,
      slotsBadge: dynamicSlotsBadge,
      cancelledTotal: parsedCancelledTotal,
      cancelledCount: parsedCancelledCount,
      shiftedCount: parsedShiftedCount,
      cancelledBadge: '$parsedCancelledTotal Tracked',
      isSubscriptionActive: !(data['isBookingHold'] == true || data['status'] == 'HOLD'),
      subscriptionStatus: (data['isBookingHold'] == true || data['status'] == 'HOLD') ? 'EXPIRED' : 'ACTIVE',
      isBookingHold: data['isBookingHold'] == true || data['status'] == 'HOLD',
    );

    // Sync operating schedule with AdminSlotNotifier immediately so slots auto-split
    ref.read(adminSlotProvider.notifier).updateOperatingHours(
      openingTime,
      closingTime,
      openingTime,
      closingTime,
    );

    if (saveToStorage) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('verified_admin_data', jsonEncode(data));
        prefs.setString('owner_phone', ownerPhone);
        prefs.setString('owner_venue_name', venueName);
      }).catchError((err) {
        debugPrint("Error saving to SharedPreferences: $err");
      });
    }
  }

  Future<bool> updateProfileDetails({
    required String ownerName,
    required String ownerPhone,
    required String ownerEmail,
    required String venueName,
    required String address,
    required String area,
    required double dayRate,
    required double nightRate,
    required double weekdayRate,
    required double weekendRate,
  }) async {
    state = state.copyWith(
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      ownerEmail: ownerEmail,
      venueName: venueName,
      address: address,
      area: area,
      dayRate: dayRate,
      nightRate: nightRate,
      weekdayRate: weekdayRate,
      weekendRate: weekendRate,
    );

    try {
      final id = state.verifiedAdminId ?? state.adminUserId ?? 1;
      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/auth/verified-admin/$id/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ownerName': ownerName,
          'ownerPhone': ownerPhone,
          'ownerEmail': ownerEmail,
          'venueName': venueName,
          'streetAddress': address,
          'neighborhoodArea': area,
          'dayRate': dayRate,
          'nightRate': nightRate,
          'weekdayRate': weekdayRate,
          'weekendRate': weekendRate,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint("Turf Profile & Hourly Rates saved to database successfully.");
        return true;
      }
    } catch (e) {
      debugPrint("Error updating profile in DB: $e");
    }
    return false;
  }

  void updateOperatingHours({
    required String weekdayOpening,
    required String weekdayClosing,
    required String weekendOpening,
    required String weekendClosing,
    double? weekdayRate,
    double? weekendRate,
    double? dayRate,
    double? nightRate,
  }) {
    state = state.copyWith(
      weekdayOpeningTime: weekdayOpening,
      weekdayClosingTime: weekdayClosing,
      weekendOpeningTime: weekendOpening,
      weekendClosingTime: weekendClosing,
      openingTime: weekdayOpening,
      closingTime: weekendClosing,
      weekdayRate: weekdayRate ?? state.weekdayRate,
      weekendRate: weekendRate ?? state.weekendRate,
      dayRate: dayRate ?? state.dayRate,
      nightRate: nightRate ?? state.nightRate,
    );
    SharedPreferences.getInstance().then((prefs) {
      if (weekdayRate != null) prefs.setDouble('owner_weekday_rate', weekdayRate);
      if (weekendRate != null) prefs.setDouble('owner_weekend_rate', weekendRate);
      if (dayRate != null) prefs.setDouble('owner_day_rate', dayRate);
      if (nightRate != null) prefs.setDouble('owner_night_rate', nightRate);
      prefs.setString('owner_weekday_open', weekdayOpening);
      prefs.setString('owner_weekday_close', weekdayClosing);
      prefs.setString('owner_weekend_open', weekendOpening);
      prefs.setString('owner_weekend_close', weekendClosing);
    }).catchError((e) {
      debugPrint("Error saving timing rates: $e");
    });
  }

  void addSport(TurfSportItem sport) {
    final updatedSports = List<TurfSportItem>.from(state.sports)..add(sport);
    state = state.copyWith(sports: updatedSports);
    _saveSports(updatedSports);
  }

  void updateSportRate(
    String sportName, {
    required double hourlyRate,
    required double weekdayRate,
    required double weekendRate,
    required double nightRate,
  }) {
    final updatedSports = state.sports.map((s) {
      if (s.name.toLowerCase() == sportName.toLowerCase()) {
        return s.copyWith(
          hourlyRate: hourlyRate,
          weekdayRate: weekdayRate,
          weekendRate: weekendRate,
          nightRate: nightRate,
        );
      }
      return s;
    }).toList();
    state = state.copyWith(sports: updatedSports);
    _saveSports(updatedSports);
  }

  Future<void> _saveSports(List<TurfSportItem> sports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(sports.map((s) => s.toJson()).toList());
      await prefs.setString('owner_sports_data', jsonStr);

      final id = state.verifiedAdminId ?? state.adminUserId ?? 1;
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/turfs/$id/sports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sports': sports.map((s) => s.toJson()).toList()}),
      );
    } catch (e) {
      debugPrint("Error persisting owner sports: $e");
    }
  }

  void addCourtVenue(TurfCourtVenueItem court) {
    final updatedCourts = List<TurfCourtVenueItem>.from(state.courts)..add(court);
    state = state.copyWith(courts: updatedCourts);
    _syncCourtsToBackend(updatedCourts);
  }

  void updateCourtVenue(TurfCourtVenueItem updatedCourt) {
    final updatedCourts = state.courts.map((c) {
      return c.id == updatedCourt.id ? updatedCourt : c;
    }).toList();
    state = state.copyWith(courts: updatedCourts);
    _syncCourtsToBackend(updatedCourts);
  }

  void removeCourtVenue(String courtId) {
    final updatedCourts = state.courts.where((c) => c.id != courtId).toList();
    state = state.copyWith(courts: updatedCourts);
    _syncCourtsToBackend(updatedCourts);
  }

  void updateFacilities(List<String> newFacilities) {
    state = state.copyWith(facilities: newFacilities);
  }

  void updateMonthlyRevenueTarget(double target) {
    state = state.copyWith(monthlyRevenueTarget: target);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble('owner_monthly_revenue_target', target);
    }).catchError((e) {
      debugPrint("Error saving monthly target to prefs: $e");
    });
  }

  Future<void> _syncCourtsToBackend(List<TurfCourtVenueItem> courts) async {
    final tId = state.turfId;
    if (tId <= 0) return;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/turfs/$tId/courts');
      final payload = jsonEncode({
        'courts': courts.map((c) => c.toJson()).toList(),
      });
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Error syncing courts to backend: $e');
    }
  }

  Future<bool> updateOperatingSchedule({
    required String openingTime,
    required String closingTime,
  }) async {
    try {
      // 1. Update local TurfProfileState
      state = state.copyWith(
        openingTime: openingTime,
        closingTime: closingTime,
        weekdayOpeningTime: openingTime,
        weekdayClosingTime: closingTime,
        weekendOpeningTime: openingTime,
        weekendClosingTime: closingTime,
      );

      // 2. Update AdminSlotNotifier so slots auto-split into 1-hour slots immediately
      ref.read(adminSlotProvider.notifier).updateOperatingHours(
        openingTime,
        closingTime,
        openingTime,
        closingTime,
      );

      // 3. Persist to AdminDashboard table in backend database
      final id = state.verifiedAdminId ?? state.adminUserId ?? 1;
      final payload = <String, dynamic>{
        'openingTime': openingTime,
        'closingTime': closingTime,
      };

      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/auth/verified-admin/$id/metrics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        if (json['admin'] != null && json['admin'] is Map<String, dynamic>) {
          setFromVerifiedAdmin(json['admin'] as Map<String, dynamic>);
          return true;
        }
      }
      return true;
    } catch (e) {
      debugPrint("Error updating operating schedule: $e");
      return false;
    }
  }

  Future<bool> updateVenueKpiMetrics({
    String? openingTime,
    String? closingTime,
    int? todayBookingsCount,
    int? todayPaidBookings,
    int? todayCashBookings,
    double? todayRevenue,
    List<OwnerTurfBranchItem>? branches,
    String? todayBookingsGrowth,
    double? monthRevenue,
    int? monthTotalBookings,
    String? revenueBadge,
    double? monthlyRevenueTarget,
    int? freeSlotsCount,
    int? bookedSlotsCount,
    int? blockedSlotsCount,
    String? slotsBadge,
    int? cancelledTotal,
    int? cancelledCount,
    int? shiftedCount,
    String? cancelledBadge,
  }) async {
    try {
      final id = state.verifiedAdminId ?? state.adminUserId ?? 1;
      final payload = <String, dynamic>{};
      if (openingTime != null) payload['openingTime'] = openingTime;
      if (closingTime != null) payload['closingTime'] = closingTime;
      if (todayBookingsCount != null) payload['todayBookingsCount'] = todayBookingsCount;
      if (todayPaidBookings != null) payload['todayPaidBookings'] = todayPaidBookings;
      if (todayCashBookings != null) payload['todayCashBookings'] = todayCashBookings;
      if (todayBookingsGrowth != null) payload['todayBookingsGrowth'] = todayBookingsGrowth;
      if (monthRevenue != null) payload['monthRevenue'] = monthRevenue;
      if (monthTotalBookings != null) payload['monthTotalBookings'] = monthTotalBookings;
      if (revenueBadge != null) payload['revenueBadge'] = revenueBadge;
      if (freeSlotsCount != null) payload['freeSlotsCount'] = freeSlotsCount;
      if (bookedSlotsCount != null) payload['bookedSlotsCount'] = bookedSlotsCount;
      if (blockedSlotsCount != null) payload['blockedSlotsCount'] = blockedSlotsCount;
      if (slotsBadge != null) payload['slotsBadge'] = slotsBadge;
      if (cancelledTotal != null) payload['cancelledTotal'] = cancelledTotal;
      if (cancelledCount != null) payload['cancelledCount'] = cancelledCount;
      if (shiftedCount != null) payload['shiftedCount'] = shiftedCount;
      if (cancelledBadge != null) payload['cancelledBadge'] = cancelledBadge;

      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/auth/verified-admin/$id/metrics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        if (json['admin'] != null && json['admin'] is Map<String, dynamic>) {
          setFromVerifiedAdmin(json['admin'] as Map<String, dynamic>);
          return true;
        }
      }
    } catch (e) {
      debugPrint("Error updating venue metrics: $e");
    }
    return false;
  }

  void setSubscriptionDays(int days) {
    final isBlocked = days <= 0;
    final now = DateTime.now();
    final newRenew = now.add(Duration(days: days));
    final renewStr = DateFormat('dd MMM yyyy').format(newRenew);
    state = state.copyWith(
      subscriptionDaysRemaining: days,
      subscriptionRenewDate: renewStr,
      isSubscriptionActive: !isBlocked,
      isBookingHold: isBlocked,
      subscriptionStatus: isBlocked ? 'EXPIRED' : 'ACTIVE',
    );
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('owner_subscription_renew_date', renewStr);
      prefs.setBool('owner_subscription_hold', isBlocked);
    }).catchError((_) {});
  }

  Future<bool> payPlatformSubscription({String paymentMethod = 'UPI (GPay)'}) async {
    try {
      final id = state.verifiedAdminId ?? state.adminUserId ?? 1;
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/turfs/$id/pay-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentMethod': paymentMethod,
          'amount': 1180.0,
        }),
      );
    } catch (e) {
      debugPrint("Error paying platform subscription on server: $e");
    }

    final now = DateTime.now();
    DateTime nextRenewal;
    final currentRenew = state.subscriptionRenewDateTime;
    if (state.isSubscriptionActive && currentRenew != null && currentRenew.isAfter(now)) {
      nextRenewal = currentRenew.add(const Duration(days: 30));
    } else {
      nextRenewal = now.add(const Duration(days: 30));
    }

    final startStr = DateFormat('dd MMM yyyy').format(now);
    final renewStr = DateFormat('dd MMM yyyy').format(nextRenewal);
    final periodStr = '$startStr - $renewStr';
    final receiptNum = 'RCP-SUB-${now.millisecondsSinceEpoch % 100000}';

    final newPayment = SubscriptionPaymentItem(
      id: 'SUB-${now.year}-${now.month.toString().padLeft(2, '0')}',
      date: DateFormat('dd MMM yyyy, hh:mm a').format(now),
      baseAmount: 1000.0,
      gstAmount: 180.0,
      totalAmount: 1180.0,
      paymentMethod: paymentMethod,
      status: 'Paid & Active',
      validPeriod: periodStr,
      receiptNumber: receiptNum,
    );

    final updatedHistory = [newPayment, ...state.subscriptionHistory];
    final nowDateOnly = DateTime(now.year, now.month, now.day);
    final renewDateOnly = DateTime(nextRenewal.year, nextRenewal.month, nextRenewal.day);
    final newDays = renewDateOnly.difference(nowDateOnly).inDays;

    state = state.copyWith(
      isSubscriptionActive: true,
      isBookingHold: false,
      subscriptionStatus: 'ACTIVE',
      subscriptionStartDate: startStr,
      subscriptionRenewDate: renewStr,
      subscriptionDaysRemaining: newDays,
      subscriptionHistory: updatedHistory,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('owner_subscription_start_date', startStr);
      await prefs.setString('owner_subscription_renew_date', renewStr);
      await prefs.setBool('owner_subscription_hold', false);
      final savedJson = prefs.getString('verified_admin_data');
      if (savedJson != null && savedJson.isNotEmpty) {
        final map = jsonDecode(savedJson);
        if (map is Map<String, dynamic>) {
          map['isBookingHold'] = false;
          map['status'] = 'VERIFIED';
          await prefs.setString('verified_admin_data', jsonEncode(map));
        }
      }
      await prefs.setString('subscription_history', jsonEncode(updatedHistory.map((h) => h.toJson()).toList()));
    } catch (e) {
      debugPrint("Error saving subscription history to prefs: $e");
    }
    return true;
  }

  Future<void> togglePlatformSubscription() async {
    try {
      final id = state.verifiedAdminId ?? state.adminUserId ?? 1;
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/turfs/$id/toggle-subscription'),
      );
      final newActive = !state.isSubscriptionActive;
      state = state.copyWith(
        isSubscriptionActive: newActive,
        isBookingHold: !newActive,
        subscriptionStatus: newActive ? 'ACTIVE' : 'EXPIRED',
      );

      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('verified_admin_data');
      if (savedJson != null && savedJson.isNotEmpty) {
        final map = jsonDecode(savedJson);
        if (map is Map<String, dynamic>) {
          map['isBookingHold'] = !newActive;
          map['status'] = newActive ? 'VERIFIED' : 'HOLD';
          await prefs.setString('verified_admin_data', jsonEncode(map));
        }
      }
    } catch (e) {
      debugPrint("Error toggling subscription: $e");
      final newActive = !state.isSubscriptionActive;
      state = state.copyWith(
        isSubscriptionActive: newActive,
        isBookingHold: !newActive,
        subscriptionStatus: newActive ? 'ACTIVE' : 'EXPIRED',
      );
    }
  }

  Future<void> toggleSubscription() => togglePlatformSubscription();
  Future<bool> paySubscription({String paymentMethod = 'UPI'}) =>
      payPlatformSubscription(paymentMethod: paymentMethod);
}

final turfProfileProvider = NotifierProvider<TurfProfileNotifier, TurfProfileState>(
  () => TurfProfileNotifier(),
);

