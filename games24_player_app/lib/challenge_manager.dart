import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

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

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
    id: json['id']?.toString() ?? '',
    turfName: json['turfName']?.toString() ?? '',
    location: json['location']?.toString() ?? 'Madurai',
    date: json['date']?.toString() ?? '',
    time: json['time']?.toString() ?? '',
    sport: json['sport']?.toString() ?? 'Football',
    challengerName: json['challengerName']?.toString() ?? '',
    challengerTeamInitials: json['challengerTeamInitials']?.toString() ?? 'TC',
    challengerColor: Color(
      json['challengerColor'] is int
          ? json['challengerColor'] as int
          : (int.tryParse(json['challengerColor']?.toString() ?? '') ?? 0xFF154D36),
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

class ChallengeManager {
  static final ChallengeManager _instance = ChallengeManager._internal();
  factory ChallengeManager() => _instance;
  ChallengeManager._internal() {
    _loadFromStorage();
    fetchChallenges();
  }

  static const String _storageKey = 'saved_open_challenges';
  String _currentUserPhone = '';

  final ValueNotifier<List<Challenge>> challengesNotifier =
      ValueNotifier<List<Challenge>>([]);

  List<Challenge> get activeChallenges =>
      challengesNotifier.value.where((c) => !c.isExpired).toList();

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
        final loaded = list
            .map((item) => Challenge.fromJson(Map<String, dynamic>.from(item)))
            .where((c) => c.id != '1' && c.id != '2' && !c.isExpired)
            .toList();
        challengesNotifier.value = loaded;
      }
      syncWithCurrentUser();
    } catch (e) {
      debugPrint("Error loading challenges: $e");
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = jsonEncode(
        challengesNotifier.value.map((c) => c.toJson()).toList(),
      );
      await prefs.setString(_storageKey, str);
    } catch (e) {
      debugPrint("Error saving challenges: $e");
    }
  }

  /// Fetches real-time open matches from the cloud backend so matches created
  /// in any player account are instantly visible to all other accounts across devices.
  Future<void> fetchChallenges({String? location, String? sport}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserPhone = (prefs.getString('mobileNumber') ?? '').trim();

      String query = '';
      if (location != null && location.isNotEmpty && location.toLowerCase() != 'all madurai' && location.toLowerCase() != 'all') {
        query += '?location=${Uri.encodeComponent(location)}';
      }
      if (sport != null && sport.isNotEmpty && sport.toLowerCase() != 'all') {
        query += '${query.isEmpty ? '?' : '&'}sport=${Uri.encodeComponent(sport)}';
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/turfs/open-matches$query');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['matches'] is List) {
          final List list = data['matches'];
          final List<Challenge> serverChallenges = [];

          for (var item in list) {
            final map = Map<String, dynamic>.from(item);
            final c = Challenge.fromJson(map);

            if (_currentUserPhone.isNotEmpty && c.creatorPhone.isNotEmpty) {
              c.isCreator = _isMatchingPhone(c.creatorPhone, _currentUserPhone);
            }

            if (!c.isCreator && _currentUserPhone.isNotEmpty) {
              c.userHasRequested = c.joinRequests.any((r) => _isMatchingPhone(r.contactDetails, _currentUserPhone));
            }

            if (!c.isExpired) {
              serverChallenges.add(c);
            }
          }

          // Merge: keep local user-created challenges that might still be sending
          final Map<String, Challenge> merged = {};
          for (var c in serverChallenges) {
            merged[c.id] = c;
          }
          for (var c in challengesNotifier.value) {
            if (!merged.containsKey(c.id) && !c.isExpired) {
              merged[c.id] = c;
            }
          }

          challengesNotifier.value = merged.values.toList();
          _saveToStorage();
        }
      }
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
      for (int i = 0; i < list.length; i++) {
        final c = list[i];
        if (c.creatorPhone.isNotEmpty) {
          final isMine = _isMatchingPhone(c.creatorPhone, _currentUserPhone);
          if (c.isCreator != isMine) {
            c.isCreator = isMine;
            changed = true;
          }
        }
      }
      if (changed) {
        challengesNotifier.value = list;
      }
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

  void addChallenge(Challenge challenge) {
    challengesNotifier.value = [challenge, ...challengesNotifier.value];
    _saveToStorage();

    // Sync to backend in background so other accounts/phones immediately see it
    http.post(
      Uri.parse('${ApiConfig.baseUrl}/turfs/open-matches'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(challenge.toJson()),
    ).then((res) {
      debugPrint("Open challenge synced to cloud: ${res.statusCode}");
    }).catchError((e) {
      debugPrint("Error syncing open challenge to cloud: $e");
    });
  }

  void requestToJoin(
    String id,
    String teamName,
    String teamSize,
    String contactDetails,
  ) {
    final list = List<Challenge>.from(challengesNotifier.value);
    final index = list.indexWhere((c) => c.id == id);
    if (index != -1) {
      final req = JoinRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        teamName: teamName,
        teamSize: teamSize,
        contactDetails: contactDetails,
        requestedAt: 'Just now',
      );
      final updatedRequests = List<JoinRequest>.from(list[index].joinRequests)
        ..add(req);

      list[index] = Challenge(
        id: list[index].id,
        turfName: list[index].turfName,
        location: list[index].location,
        date: list[index].date,
        time: list[index].time,
        sport: list[index].sport,
        challengerName: list[index].challengerName,
        challengerTeamInitials: list[index].challengerTeamInitials,
        challengerColor: list[index].challengerColor,
        creatorPhone: list[index].creatorPhone,
        teamSize: list[index].teamSize,
        isCreator: list[index].isCreator,
        isJoined: list[index].isJoined,
        opponentName: list[index].opponentName,
        opponentTeamSize: list[index].opponentTeamSize,
        opponentContact: list[index].opponentContact,
        joinRequests: updatedRequests,
        userHasRequested: true,
      );

      challengesNotifier.value = list;
      _saveToStorage();

      // Sync join request to cloud
      http.post(
        Uri.parse('${ApiConfig.baseUrl}/turfs/open-matches/$id/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': req.id,
          'teamName': teamName,
          'teamSize': teamSize,
          'contactDetails': contactDetails,
        }),
      ).catchError((e) {
        debugPrint("Error syncing join request: $e");
        return http.Response('', 500);
      });
    }
  }

  void acceptRequest(String challengeId, JoinRequest request) {
    final list = List<Challenge>.from(challengesNotifier.value);
    final index = list.indexWhere((c) => c.id == challengeId);
    if (index != -1) {
      list[index] = Challenge(
        id: list[index].id,
        turfName: list[index].turfName,
        location: list[index].location,
        date: list[index].date,
        time: list[index].time,
        sport: list[index].sport,
        challengerName: list[index].challengerName,
        challengerTeamInitials: list[index].challengerTeamInitials,
        challengerColor: list[index].challengerColor,
        creatorPhone: list[index].creatorPhone,
        teamSize: list[index].teamSize,
        isCreator: list[index].isCreator,
        isJoined: true,
        opponentName: request.teamName,
        opponentTeamSize: request.teamSize,
        opponentContact: request.contactDetails,
        joinRequests: [],
        userHasRequested: list[index].userHasRequested,
      );
      challengesNotifier.value = list;
      _saveToStorage();

      // Sync accepted match to cloud
      http.post(
        Uri.parse('${ApiConfig.baseUrl}/turfs/open-matches/$challengeId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'opponentName': request.teamName,
          'opponentContact': request.contactDetails,
          'opponentTeamSize': request.teamSize,
        }),
      ).catchError((e) {
        debugPrint("Error syncing accepted challenge: $e");
        return http.Response('', 500);
      });
    }
  }

  void rejectRequest(String challengeId, String requestId) {
    final list = List<Challenge>.from(challengesNotifier.value);
    final index = list.indexWhere((c) => c.id == challengeId);
    if (index != -1) {
      final updatedRequests = list[index].joinRequests
          .where((r) => r.id != requestId)
          .toList();
      list[index] = Challenge(
        id: list[index].id,
        turfName: list[index].turfName,
        location: list[index].location,
        date: list[index].date,
        time: list[index].time,
        sport: list[index].sport,
        challengerName: list[index].challengerName,
        challengerTeamInitials: list[index].challengerTeamInitials,
        challengerColor: list[index].challengerColor,
        creatorPhone: list[index].creatorPhone,
        teamSize: list[index].teamSize,
        isCreator: list[index].isCreator,
        isJoined: list[index].isJoined,
        opponentName: list[index].opponentName,
        opponentTeamSize: list[index].opponentTeamSize,
        opponentContact: list[index].opponentContact,
        joinRequests: updatedRequests,
        userHasRequested: list[index].userHasRequested,
      );
      challengesNotifier.value = list;
      _saveToStorage();
    }
  }
}
