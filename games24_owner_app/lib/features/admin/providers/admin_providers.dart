import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

class AdminSlotState {
  final Map<String, Set<String>> blockedSlotsByDate;
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
    Map<String, Map<String, String>>? discountedSlotsByDate,
    this.weekdayOpeningTime = '05:00 AM',
    this.weekdayClosingTime = '11:00 PM',
    this.weekendOpeningTime = '05:00 AM',
    this.weekendClosingTime = '11:30 PM',
  })  : blockedSlotsByDate = blockedSlotsByDate ?? {
          _getTodayKey(): {'02:00 PM - 03:00 PM'},
        },
        discountedSlotsByDate = discountedSlotsByDate ?? {
          _getTodayKey(): {
            '01:00 PM - 02:00 PM': 'PERCENT|20|Happy Hour',
            '03:00 PM - 04:00 PM': 'PRICE|1000|800',
          },
        };

  static String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Set<String> getBlockedSlotsForDate(String dateKey) {
    return blockedSlotsByDate[dateKey] ?? {};
  }

  Map<String, String> getDiscountedSlotsForDate(String dateKey) {
    return discountedSlotsByDate[dateKey] ?? {};
  }

  AdminSlotState copyWith({
    Map<String, Set<String>>? blockedSlotsByDate,
    Map<String, Map<String, String>>? discountedSlotsByDate,
    String? weekdayOpeningTime,
    String? weekdayClosingTime,
    String? weekendOpeningTime,
    String? weekendClosingTime,
  }) {
    return AdminSlotState(
      blockedSlotsByDate: blockedSlotsByDate ?? this.blockedSlotsByDate,
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
    final adminUserId = data['adminUserId'] is int ? data['adminUserId'] as int : null;

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

    // Real dynamic bookings tailored to this venue
    final bookingHistory = [
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

    state = state.copyWith(
      venueName: venueName,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      ownerEmail: ownerEmail,
      address: streetAddress,
      area: neighborhoodArea,
      facilities: amenities,
      photoUrls: photoUrls,
      trackingCode: trackingCode,
      adminUserId: adminUserId,
      gstin: gstin,
      pan: pan,
      aadhaar: aadhaar,
      bankAccount: bankAccount,
      ifsc: ifsc,
      upiId: upiId,
      aadhaarDocUrl: aadhaarDocUrl,
      panDocUrl: panDocUrl,
      gstDocUrl: gstDocUrl,
      kycVerified: true,
      courts: courts,
      bookingHistory: bookingHistory,
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

  void updateProfileDetails({
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
  }) {
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
}

final turfProfileProvider = NotifierProvider<TurfProfileNotifier, TurfProfileState>(
  () => TurfProfileNotifier(),
);

