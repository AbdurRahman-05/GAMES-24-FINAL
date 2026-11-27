import 'core/network/api_client.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JoinRequest {
  final String id;
  final String teamName;
  final String teamSize;
  final String contactDetails;
  final String requestedAt;

  JoinRequest({
    required this.id,
    required this.teamName,
    required this.teamSize,
    required this.contactDetails,
    this.requestedAt = 'Just now',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamName': teamName,
    'teamSize': teamSize,
    'contactDetails': contactDetails,
    'requestedAt': requestedAt,
  };

  factory JoinRequest.fromJson(Map<String, dynamic> json) => JoinRequest(
    id: json['id']?.toString() ?? '',
    teamName: json['teamName']?.toString() ?? '',
    teamSize: json['teamSize']?.toString() ?? '7 Players (7v7)',
    contactDetails: json['contactDetails']?.toString() ?? '',
    requestedAt: json['requestedAt']?.toString() ?? 'Just now',
  );
}

class Challenge {
  final String id;
  final String turfName;
  final String location;
  final String date;
  final String time;
  final String sport;
  final String challengerName;
  final String challengerTeamInitials;
  final Color challengerColor;
  final String creatorPhone;
  final String teamSize;

  bool isCreator;
  bool isJoined;
  String? opponentName;
  String? opponentTeamSize;
  String? opponentContact;
  List<JoinRequest> joinRequests;
  bool userHasRequested;

  Challenge({
    required this.id,
    required this.turfName,
    this.location = 'Madurai',
    required this.date,
    required this.time,
    required this.sport,
    required this.challengerName,
    required this.challengerTeamInitials,
    required this.challengerColor,
    this.creatorPhone = '',
    this.teamSize = '7v7',
    this.isCreator = false,
    this.isJoined = false,
    this.opponentName,
    this.opponentTeamSize,
    this.opponentContact,
    this.joinRequests = const [],
    this.userHasRequested = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'turfName': turfName,
    'location': location,
    'date': date,
    'time': time,
    'sport': sport,
    'challengerName': challengerName,
    'challengerTeamInitials': challengerTeamInitials,
    'challengerColor': challengerColor.toARGB32(),
    'creatorPhone': creatorPhone,
    'teamSize': teamSize,
    'isCreator': isCreator,
    'isJoined': isJoined,
    'opponentName': opponentName,
    'opponentTeamSize': opponentTeamSize,
    'opponentContact': opponentContact,
    'joinRequests': joinRequests.map((r) => r.toJson()).toList(),
    'userHasRequested': userHasRequested,
  };

  static String _cleanString(dynamic raw, [String defaultValue = '']) {
    if (raw == null) return defaultValue;
    return raw
        .toString()
        .replaceAll('âš½', '')
        .replaceAll('â€¢', '\u2022')
        .replaceAll('⚽', '')
        .replaceAll('🏏', '')
        .trim();
  }

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
    id: json['id']?.toString() ?? '',
    turfName: json['turfName']?.toString() ?? '',
    location: json['location']?.toString() ?? 'Madurai',
    date: _cleanString(json['date']),
    time: _cleanString(json['time']),
    sport: _cleanString(json['sport'], 'Football'),
    challengerName: json['challengerName']?.toString() ?? '',
    challengerTeamInitials: json['challengerTeamInitials']?.toString() ?? 'TC',
    challengerColor: Color(
      json['challengerColor'] is int
          ? json['challengerColor'] as int
          : (int.tryParse(json['challengerColor']?.toString() ?? '') ?? 0xFFD4FF00),
    ),
    creatorPhone: json['creatorPhone']?.toString() ?? '',
    teamSize: json['teamSize']?.toString() ?? '7v7',
    isCreator: json['isCreator'] == true,
    isJoined: json['isJoined'] == true,
    opponentName: json['opponentName']?.toString(),
    opponentTeamSize: json['opponentTeamSize']?.toString(),
    opponentContact: json['opponentContact']?.toString(),
    joinRequests: (json['joinRequests'] is List)
        ? (json['joinRequests'] as List)
              .map((r) => JoinRequest.fromJson(Map<String, dynamic>.from(r)))
              .toList()
        : [],
    userHasRequested: json['userHasRequested'] == true,
  );

  bool get isExpired {
    try {
      final now = DateTime.now();
      DateTime challengeDate;

      final dStr = date.trim().toLowerCase();
      if (dStr == 'today') {
        challengeDate = DateTime(now.year, now.month, now.day);
      } else if (dStr == 'tomorrow') {
        challengeDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 1));
      } else if (dStr == 'yesterday') {
        return true;
      } else {
        DateTime? parsed = DateTime.tryParse(date.trim());
        if (parsed != null) {
          challengeDate = DateTime(parsed.year, parsed.month, parsed.day);
        } else {
          final parts = date.trim().split(RegExp(r'[-/ ]'));
          if (parts.length >= 3) {
            int? day = int.tryParse(parts[0]);
            int? month = int.tryParse(parts[1]);
            int? year = int.tryParse(parts[2]);
            if (day != null && month != null && year != null) {
              if (year < 100) year += 2000;
              challengeDate = DateTime(year, month, day);
            } else {
              challengeDate = DateTime(now.year, now.month, now.day);
            }
          } else {
            challengeDate = DateTime(now.year, now.month, now.day);
          }
        }
      }

      final todayDate = DateTime(now.year, now.month, now.day);
      if (challengeDate.isBefore(todayDate)) {
        return true;
      }
      if (challengeDate.isAfter(todayDate)) {
        return false;
      }

      // If it is today, check if match slot time has already passed
      String timeStr = time.trim();
      if (timeStr.contains('-')) {
        timeStr = timeStr.split('-').first.trim();
      }

      final timeRegex = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)?',
        caseSensitive: false,
      );
      final match = timeRegex.firstMatch(timeStr);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String? ampm = match.group(3)?.toUpperCase();

        if (ampm == 'PM' && hour < 12) {
          hour += 12;
        } else if (ampm == 'AM' && hour == 12) {
          hour = 0;
        }

        final matchDateTime = DateTime(
          challengeDate.year,
          challengeDate.month,
          challengeDate.day,
          hour,
          minute,
        );

        return now.isAfter(matchDateTime);
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}

/// Result of a challenge action, carrying the server's message for the UI.
class ChallengeActionResult {
  final bool ok;
  final String message;
  const ChallengeActionResult(this.ok, this.message);
}

/// Open challenges are owned by the server: every action is sent there first and the local list
/// only changes when the server accepts it. Local storage is just a per-user cache.
class ChallengeManager {
  static final ChallengeManager _instance = ChallengeManager._internal();
  factory ChallengeManager() => _instance;
  ChallengeManager._internal() {
    _loadFromStorage();
    fetchChallenges();
  }

  static const String _storageKey = 'saved_open_challenges';
  String _currentUserPhone = '';
  String? _lastLocation;
  String? _lastSport;

  final ValueNotifier<List<Challenge>> challengesNotifier =
      ValueNotifier<List<Challenge>>([]);

  List<Challenge> get activeChallenges =>
      challengesNotifier.value.where((c) => !c.isExpired).toList();

  /// Clears the previous user's cached challenges (logout / account switch) and reloads.
  Future<void> reset() async {
    challengesNotifier.value = [];
    _currentUserPhone = '';
    await _loadFromStorage();
    await fetchChallenges(location: _lastLocation, sport: _lastSport);
  }

  void cleanExpiredChallenges() {
    final active = activeChallenges;
    if (active.length != challengesNotifier.value.length) {
      challengesNotifier.value = active;
      _saveToStorage();
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserPhone = (prefs.getString('mobileNumber') ?? '').trim();
      final savedStr = prefs.getString(_storageKey);
      if (savedStr != null && savedStr.isNotEmpty) {
        final List list = jsonDecode(savedStr);
        challengesNotifier.value = list
            .map((item) => Challenge.fromJson(Map<String, dynamic>.from(item)))
            .where((c) => !c.isExpired)
            .toList();
      }
      await syncWithCurrentUser();
    } catch (e) {
      debugPrint("Error loading challenges: $e");
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(challengesNotifier.value.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      debugPrint("Error saving challenges: $e");
    }
  }

  /// Replaces the list with the server's open matches. Challenges the server no longer returns
  /// (accepted elsewhere, cancelled, converted to private) disappear instead of lingering.
  Future<void> fetchChallenges({String? location, String? sport}) async {
    _lastLocation = location;
    _lastSport = sport;
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserPhone = (prefs.getString('mobileNumber') ?? '').trim();

      final loc = (location ?? '').toLowerCase();
      final res = await ApiClient.get('/turfs/open-matches', query: {
        'location': (loc.isEmpty || loc == 'all' || loc == 'all madurai') ? null : location,
        'sport': (sport == null || sport.toLowerCase() == 'all') ? null : sport,
      });
      if (!res.ok || res.map['matches'] is! List) return;

      final List<Challenge> serverChallenges = [];
      for (final item in res.map['matches'] as List) {
        final c = Challenge.fromJson(Map<String, dynamic>.from(item as Map));
        if (_currentUserPhone.isNotEmpty && c.creatorPhone.isNotEmpty) {
          c.isCreator = _isMatchingPhone(c.creatorPhone, _currentUserPhone);
        }
        if (!c.isCreator && _currentUserPhone.isNotEmpty) {
          c.userHasRequested = c.joinRequests.any(
            (r) => _isMatchingPhone(r.contactDetails, _currentUserPhone),
          );
        }
        if (!c.isExpired) serverChallenges.add(c);
      }

      challengesNotifier.value = serverChallenges;
      await _saveToStorage();
    } catch (e) {
      debugPrint("Error fetching open challenges from backend: $e");
    }
  }

  Future<void> syncWithCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserPhone = (prefs.getString('mobileNumber') ?? '').trim();
      if (_currentUserPhone.isEmpty) return;

      final list = List<Challenge>.from(challengesNotifier.value);
      bool changed = false;
      for (final c in list) {
        if (c.creatorPhone.isNotEmpty) {
          final isMine = _isMatchingPhone(c.creatorPhone, _currentUserPhone);
          if (c.isCreator != isMine) {
            c.isCreator = isMine;
            changed = true;
          }
        }
      }
      if (changed) challengesNotifier.value = list;
    } catch (_) {}
  }

  bool _isMatchingPhone(String p1, String p2) {
    final clean1 = p1.replaceAll(RegExp(r'[^0-9]'), '');
    final clean2 = p2.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean1 == clean2 && clean1.isNotEmpty) return true;
    if (clean1.length >= 10 && clean2.length >= 10) {
      return clean1.substring(clean1.length - 10) ==
          clean2.substring(clean2.length - 10);
    }
    return false;
  }

  Future<ChallengeActionResult> requestToJoin(
    String id,
    String teamName,
    String teamSize,
    String contactDetails,
  ) async {
    final res = await ApiClient.post('/turfs/open-matches/$id/join', body: {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'teamName': teamName,
      'teamSize': teamSize,
      'contactDetails': contactDetails,
    });
    if (!res.ok) return ChallengeActionResult(false, res.message);
    await fetchChallenges(location: _lastLocation, sport: _lastSport);
    return ChallengeActionResult(true, res.message);
  }

  Future<ChallengeActionResult> acceptRequest(String challengeId, JoinRequest request) async {
    final res = await ApiClient.post('/turfs/open-matches/$challengeId/accept', body: {
      'opponentName': request.teamName,
      'opponentContact': request.contactDetails,
      'opponentTeamSize': request.teamSize,
    });
    if (!res.ok) return ChallengeActionResult(false, res.message);
    await fetchChallenges(location: _lastLocation, sport: _lastSport);
    return ChallengeActionResult(true, 'Challenge accepted! Paired with ${request.teamName}.');
  }

  Future<ChallengeActionResult> rejectRequest(String challengeId, String requestId) async {
    final res = await ApiClient.post('/turfs/open-matches/$challengeId/reject', body: {
      'requestId': requestId,
      'callerPhone': _currentUserPhone,
    });
    if (!res.ok) return ChallengeActionResult(false, res.message);
    await fetchChallenges(location: _lastLocation, sport: _lastSport);
    return const ChallengeActionResult(true, 'Request declined.');
  }
}
