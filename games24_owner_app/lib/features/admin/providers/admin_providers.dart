import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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
      final res = await http.get(Uri.parse('http://localhost:3000/turfs/$adminId/slots?date=$dateKey&role=owner'));
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
        Uri.parse('http://localhost:3000/turfs/$adminId/slot-offer'),
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
        Uri.parse('http://localhost:3000/turfs/$adminId/toggle-block'),
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
  final String dateTimeSlot;
  final double amount;
  final String paymentMethod;
  final String status; // 'Confirmed', 'Completed', 'Cancelled'

  const TurfBookingHistoryItem({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.sport,
    required this.courtName,
    required this.dateTimeSlot,
    required this.amount,
    required this.paymentMethod,
    required this.status,
  });
}

class TurfCourtVenueItem {
  final String id;
  final String name;
  final String sport;
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
    required this.surface,
    required this.hourlyRate,
    required this.timings,
    this.description = '',
    this.amenities = const [],
    this.imageUrls = const [],
  });
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
}

class TurfProfileState {
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String venueName;
  final String address;
  final String area;
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
  final String todayBookingsGrowth;
  final double monthRevenue;
  final int monthTotalBookings;
  final String revenueBadge;
  final int freeSlotsCount;
  final int bookedSlotsCount;
  final int blockedSlotsCount;
  final String slotsBadge;
  final int cancelledTotal;
  final int cancelledCount;
  final int shiftedCount;
  final String cancelledBadge;

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
      TurfSportItem(name: 'Cricket', hourlyRate: 1000.0, courtsAvailable: 2),
      TurfSportItem(name: 'Football', hourlyRate: 1400.0, courtsAvailable: 2),
      TurfSportItem(name: 'Pickle ball', hourlyRate: 800.0, courtsAvailable: 2),
      TurfSportItem(name: 'Badminton', hourlyRate: 450.0, courtsAvailable: 4),
    ],
    this.courts = const [
      TurfCourtVenueItem(
        id: 'CR-01',
        name: 'Main Turf Arena A (7v7)',
        sport: 'Football',
        surface: 'FIFA Quality 50mm Synthetic Turf',
        hourlyRate: 1400.0,
        timings: 'Wkday 06:00 AM - 11:00 PM | Wkend 05:00 AM - 11:30 PM',
      ),
      TurfCourtVenueItem(
        id: 'CR-02',
        name: 'Box Cricket Arena B',
        sport: 'Box Cricket',
        surface: 'High-Density Turf with Net Enclosure',
        hourlyRate: 1000.0,
        timings: 'Wkday 06:00 AM - 11:00 PM | Wkend 05:00 AM - 11:30 PM',
      ),
      TurfCourtVenueItem(
        id: 'CR-03',
        name: 'Indoor Wooden Court 1',
        sport: 'Badminton',
        surface: 'Teakwood Synthetic Mat Court',
        hourlyRate: 450.0,
        timings: '06:00 AM - 10:00 PM (All Days)',
      ),
    ],
    this.bookingHistory = const [
      TurfBookingHistoryItem(
        id: 'BK-99214',
        customerName: 'Vijay Sethu (7v7 Match)',
        customerPhone: '98450 12345',
        sport: 'Football 7v7',
        courtName: 'Artificial Grass Turf A',
        dateTimeSlot: 'Today, 08:00 PM - 09:00 PM',
        amount: 1200.0,
        paymentMethod: 'UPI (GPay)',
        status: 'Confirmed',
      ),
      TurfBookingHistoryItem(
        id: 'BK-99215',
        customerName: 'Manojh Kumar (Box Cricket)',
        customerPhone: '97890 88211',
        sport: 'Box Cricket',
        courtName: 'Box Cricket Arena B',
        dateTimeSlot: 'Today, 09:00 PM - 10:00 PM',
        amount: 1500.0,
        paymentMethod: 'Cash at Venue',
        status: 'Confirmed',
      ),
      TurfBookingHistoryItem(
        id: 'BK-99201',
        customerName: 'Vijay V (Madurai Strikers)',
        customerPhone: '98450 12345',
        sport: 'Football 7v7',
        courtName: 'Main Turf Arena A',
        dateTimeSlot: 'Today, 06:00 PM - 07:00 PM',
        amount: 1400.0,
        paymentMethod: 'UPI (GPay)',
        status: 'Confirmed',
      ),
      TurfBookingHistoryItem(
        id: 'BK-99188',
        customerName: 'Suresh Kumar',
        customerPhone: '97890 88211',
        sport: 'Box Cricket',
        courtName: 'Box Cricket Arena B',
        dateTimeSlot: 'Today, 08:00 PM - 09:00 PM',
        amount: 1000.0,
        paymentMethod: 'Cash at Venue',
        status: 'Confirmed',
      ),
      TurfBookingHistoryItem(
        id: 'BK-98920',
        customerName: 'Priya Sharma',
        customerPhone: '98421 99012',
        sport: 'Badminton',
        courtName: 'Indoor Wooden Court 1',
        dateTimeSlot: 'Yesterday, 07:00 AM - 08:00 AM',
        amount: 450.0,
        paymentMethod: 'UPI (PhonePe)',
        status: 'Completed',
      ),
      TurfBookingHistoryItem(
        id: 'BK-98754',
        customerName: 'Ramesh Krishnan',
        customerPhone: '94431 55432',
        sport: 'Football 7v7',
        courtName: 'Main Turf Arena A',
        dateTimeSlot: '25 Jul 2026, 09:00 PM - 10:00 PM',
        amount: 1400.0,
        paymentMethod: 'Razorpay Card',
        status: 'Completed',
      ),
      TurfBookingHistoryItem(
        id: 'BK-98610',
        customerName: 'Karthik Raja',
        customerPhone: '90034 11223',
        sport: 'Box Cricket',
        courtName: 'Box Cricket Arena B',
        dateTimeSlot: '24 Jul 2026, 05:00 PM - 06:00 PM',
        amount: 1000.0,
        paymentMethod: 'UPI (Paytm)',
        status: 'Cancelled',
      ),
    ],
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
    this.todayBookingsGrowth = '0% Today',
    this.monthRevenue = 0.0,
    this.monthTotalBookings = 0,
    this.revenueBadge = '₹0 GMV',
    this.freeSlotsCount = 0,
    this.bookedSlotsCount = 0,
    this.blockedSlotsCount = 0,
    this.slotsBadge = '0% Full',
    this.cancelledTotal = 0,
    this.cancelledCount = 0,
    this.shiftedCount = 0,
    this.cancelledBadge = 'Tracked',
  });

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
    String? todayBookingsGrowth,
    double? monthRevenue,
    int? monthTotalBookings,
    String? revenueBadge,
    int? freeSlotsCount,
    int? bookedSlotsCount,
    int? blockedSlotsCount,
    String? slotsBadge,
    int? cancelledTotal,
    int? cancelledCount,
    int? shiftedCount,
    String? cancelledBadge,
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
      todayBookingsGrowth: todayBookingsGrowth ?? this.todayBookingsGrowth,
      monthRevenue: monthRevenue ?? this.monthRevenue,
      monthTotalBookings: monthTotalBookings ?? this.monthTotalBookings,
      revenueBadge: revenueBadge ?? this.revenueBadge,
      freeSlotsCount: freeSlotsCount ?? this.freeSlotsCount,
      bookedSlotsCount: bookedSlotsCount ?? this.bookedSlotsCount,
      blockedSlotsCount: blockedSlotsCount ?? this.blockedSlotsCount,
      slotsBadge: slotsBadge ?? this.slotsBadge,
      cancelledTotal: cancelledTotal ?? this.cancelledTotal,
      cancelledCount: cancelledCount ?? this.cancelledCount,
      shiftedCount: shiftedCount ?? this.shiftedCount,
      cancelledBadge: cancelledBadge ?? this.cancelledBadge,
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
      final savedJson = prefs.getString('verified_admin_data');
      if (savedJson != null && savedJson.isNotEmpty) {
        final data = jsonDecode(savedJson);
        if (data is Map<String, dynamic>) {
          setFromVerifiedAdmin(data, saveToStorage: false);
          return;
        }
      }
      final phone = prefs.getString('owner_phone');
      if (phone != null && phone.isNotEmpty) {
        await fetchVerifiedAdminByPhone(phone);
      }
    } catch (e) {
      debugPrint("Error loading admin from storage: $e");
    }
  }

  Future<void> fetchVerifiedAdminByPhone(String phone) async {
    try {
      final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final res = await http.get(Uri.parse('http://localhost:3000/auth/verified-admin/$clean'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['admin'] != null && json['admin'] is Map<String, dynamic>) {
          setFromVerifiedAdmin(json['admin'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint("Error fetching verified admin: $e");
    }
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

    // Dynamically tailored courts based on real venue name
    final courts = [
      TurfCourtVenueItem(
        id: 'CR-01',
        name: '$venueName - Main Turf Arena A (7v7)',
        sport: 'Football',
        surface: 'FIFA Quality 50mm Synthetic Turf',
        hourlyRate: 1400.0,
        timings: 'Wkday 06:00 AM - 11:00 PM | Wkend 05:00 AM - 11:30 PM',
        amenities: amenities,
        imageUrls: photoUrls,
      ),
      TurfCourtVenueItem(
        id: 'CR-02',
        name: '$venueName - Box Cricket Arena B',
        sport: 'Box Cricket',
        surface: 'High-Density Turf with Net Enclosure',
        hourlyRate: 1000.0,
        timings: 'Wkday 06:00 AM - 11:00 PM | Wkend 05:00 AM - 11:30 PM',
        amenities: amenities,
        imageUrls: photoUrls,
      ),
      TurfCourtVenueItem(
        id: 'CR-03',
        name: '$venueName - Court 1',
        sport: 'Badminton',
        surface: 'Teakwood Synthetic Mat Court',
        hourlyRate: 450.0,
        timings: '06:00 AM - 10:00 PM (All Days)',
        amenities: amenities,
        imageUrls: photoUrls,
      ),
    ];

    // Real dynamic bookings from database if available, else fallback
    List<TurfBookingHistoryItem> bookingHistory = [];
    if (data['bookings'] is List && (data['bookings'] as List).isNotEmpty) {
      bookingHistory = (data['bookings'] as List).map((b) {
        final amt = (b['amount'] is num) ? (b['amount'] as num).toDouble() : 1000.0;
        return TurfBookingHistoryItem(
          id: 'BK-${b['id']}',
          customerName: b['customerName']?.toString() ?? 'Player Customer',
          customerPhone: b['customerPhone']?.toString() ?? '',
          sport: b['sport']?.toString() ?? 'Football',
          courtName: b['courtName']?.toString() ?? venueName,
          dateTimeSlot: "${b['date']}, ${b['timeSlot']}",
          amount: amt,
          paymentMethod: b['paymentMethod']?.toString() ?? 'UPI (GPay)',
          status: b['status']?.toString() ?? 'Confirmed',
        );
      }).toList();
    } else {
      bookingHistory = [
        TurfBookingHistoryItem(
          id: 'BK-99214',
          customerName: 'Vijay Sethu (7v7 Match)',
          customerPhone: '98450 12345',
          sport: 'Football 7v7',
          courtName: '$venueName Turf A',
          dateTimeSlot: 'Today, 08:00 PM - 09:00 PM',
          amount: 1200.0,
          paymentMethod: 'UPI (GPay)',
          status: 'Confirmed',
        ),
        TurfBookingHistoryItem(
          id: 'BK-99215',
          customerName: 'Manojh Kumar (Box Cricket)',
          customerPhone: '97890 88211',
          sport: 'Box Cricket',
          courtName: '$venueName Arena B',
          dateTimeSlot: 'Today, 09:00 PM - 10:00 PM',
          amount: 1500.0,
          paymentMethod: 'Cash at Venue',
          status: 'Confirmed',
        ),
        TurfBookingHistoryItem(
          id: 'BK-99201',
          customerName: 'Madurai Strikers FC',
          customerPhone: '98421 99012',
          sport: 'Football 7v7',
          courtName: '$venueName Turf A',
          dateTimeSlot: 'Today, 06:00 PM - 07:00 PM',
          amount: 1400.0,
          paymentMethod: 'UPI (PhonePe)',
          status: 'Confirmed',
        ),
        TurfBookingHistoryItem(
          id: 'BK-98920',
          customerName: 'Priya Sharma',
          customerPhone: '94431 55432',
          sport: 'Badminton',
          courtName: '$venueName Court 1',
          dateTimeSlot: 'Yesterday, 07:00 AM - 08:00 AM',
          amount: 450.0,
          paymentMethod: 'UPI (PhonePe)',
          status: 'Completed',
        ),
        TurfBookingHistoryItem(
          id: 'BK-98754',
          customerName: 'Ramesh Krishnan',
          customerPhone: '90034 11223',
          sport: 'Football 7v7',
          courtName: '$venueName Turf A',
          dateTimeSlot: 'Yesterday, 09:00 PM - 10:00 PM',
          amount: 1400.0,
          paymentMethod: 'Card',
          status: 'Completed',
        ),
      ];
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
      kycVerified: true,
      courts: courts,
      bookingHistory: bookingHistory,
      todayBookingsCount: todayBookingsCount,
      todayPaidBookings: todayPaidBookings,
      todayCashBookings: todayCashBookings,
      todayBookingsGrowth: (dash['todayBookingsGrowth'] ?? data['todayBookingsGrowth'])?.toString() ?? '0% Today',
      monthRevenue: double.tryParse((dash['monthRevenue'] ?? data['monthRevenue'])?.toString() ?? '') ?? 0.0,
      monthTotalBookings: monthTotalBookings,
      revenueBadge: (dash['revenueBadge'] ?? data['revenueBadge'])?.toString() ?? '₹0 GMV',
      freeSlotsCount: int.tryParse((dash['freeSlotsCount'] ?? data['freeSlotsCount'])?.toString() ?? '') ?? 0,
      bookedSlotsCount: int.tryParse((dash['bookedSlotsCount'] ?? data['bookedSlotsCount'])?.toString() ?? '') ?? 0,
      blockedSlotsCount: int.tryParse((dash['blockedSlotsCount'] ?? data['blockedSlotsCount'])?.toString() ?? '') ?? 0,
      slotsBadge: (dash['slotsBadge'] ?? data['slotsBadge'])?.toString() ?? '0% Full',
      cancelledTotal: int.tryParse((dash['cancelledTotal'] ?? data['cancelledTotal'])?.toString() ?? '') ?? 0,
      cancelledCount: int.tryParse((dash['cancelledCount'] ?? data['cancelledCount'])?.toString() ?? '') ?? 0,
      shiftedCount: int.tryParse((dash['shiftedCount'] ?? data['shiftedCount'])?.toString() ?? '') ?? 0,
      cancelledBadge: (dash['cancelledBadge'] ?? data['cancelledBadge'])?.toString() ?? 'Tracked',
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
        Uri.parse('http://localhost:3000/auth/verified-admin/$id/profile'),
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
  }) {
    state = state.copyWith(
      weekdayOpeningTime: weekdayOpening,
      weekdayClosingTime: weekdayClosing,
      weekendOpeningTime: weekendOpening,
      weekendClosingTime: weekendClosing,
      openingTime: weekdayOpening,
      closingTime: weekendClosing,
    );
  }

  void addSport(TurfSportItem sport) {
    final updatedSports = List<TurfSportItem>.from(state.sports)..add(sport);
    state = state.copyWith(sports: updatedSports);
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
  }

  void addCourtVenue(TurfCourtVenueItem court) {
    final updatedCourts = List<TurfCourtVenueItem>.from(state.courts)..add(court);
    state = state.copyWith(courts: updatedCourts);
  }

  void updateCourtVenue(TurfCourtVenueItem updatedCourt) {
    final updatedCourts = state.courts.map((c) {
      return c.id == updatedCourt.id ? updatedCourt : c;
    }).toList();
    state = state.copyWith(courts: updatedCourts);
  }

  void removeCourtVenue(String courtId) {
    final updatedCourts = state.courts.where((c) => c.id != courtId).toList();
    state = state.copyWith(courts: updatedCourts);
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
        Uri.parse('http://localhost:3000/auth/verified-admin/$id/metrics'),
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
    String? todayBookingsGrowth,
    double? monthRevenue,
    int? monthTotalBookings,
    String? revenueBadge,
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
        Uri.parse('http://localhost:3000/auth/verified-admin/$id/metrics'),
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
}

final turfProfileProvider = NotifierProvider<TurfProfileNotifier, TurfProfileState>(
  () => TurfProfileNotifier(),
);

