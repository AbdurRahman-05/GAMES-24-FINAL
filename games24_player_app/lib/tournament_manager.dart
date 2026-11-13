import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

enum TournamentStatus { ongoing, upcoming, completed, cancelled }

class Tournament {
  final String id;
  final String title;
  final String sport;
  final TournamentStatus status;
  final String date;
  final String time;
  final String venue;
  final String location;
  final String entryFee;
  final String prizePool;
  final String grandPrize;
  final int maxTeams;
  final int registeredTeams;
  final String format;
  final String imageUrl;
  final String reportingTime;
  final String matchDay;
  final String tournamentProgress;
  final List<Map<String, dynamic>>
  registeredUsers; // List of registered team data
  final bool isPrivate;
  final String? accessCode;
  final List<String> rules;
  final bool isVenueTBA;
  final String? externalTicketUrl;
  final int courtsCount;
  final String? organizerPhone;
  final String? organizerName;

  Tournament({
    required this.id,
    required this.title,
    required this.sport,
    required this.status,
    required this.date,
    required this.time,
    required this.venue,
    required this.location,
    required this.entryFee,
    required this.prizePool,
    required this.grandPrize,
    required this.maxTeams,
    required this.registeredTeams,
    required this.format,
    required this.imageUrl,
    this.reportingTime = '30 minutes before match',
    this.matchDay = 'Day 1',
    this.tournamentProgress = 'Started',
    this.registeredUsers = const [],
    this.isPrivate = false,
    this.accessCode,
    this.rules = const [],
    this.isVenueTBA = false,
    this.externalTicketUrl,
    this.courtsCount = 2,
    this.organizerPhone,
    this.organizerName,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? '').toString().toLowerCase();
    TournamentStatus parsedStatus = TournamentStatus.upcoming;
    if (rawStatus == 'ongoing' || rawStatus == 'live') {
      parsedStatus = TournamentStatus.ongoing;
    } else if (rawStatus == 'completed' || rawStatus == 'finished') {
      parsedStatus = TournamentStatus.completed;
    } else if (rawStatus == 'cancelled') {
      parsedStatus = TournamentStatus.cancelled;
    }

    final entryFeeVal = (json['entryFee'] is num)
        ? '₹${(json['entryFee'] as num).toInt()}'
        : (json['entryFee']?.toString() ?? '₹1,500');

    final maxTeamsVal = (json['maxTeams'] is num)
        ? (json['maxTeams'] as num).toInt()
        : (int.tryParse(json['maxTeams']?.toString() ?? '') ?? 12);

    final regTeamsVal = (json['registeredTeams'] is num)
        ? (json['registeredTeams'] as num).toInt()
        : (int.tryParse(json['registeredTeams']?.toString() ?? '') ?? 0);

    List<Map<String, dynamic>> regUsers = [];
    if (json['registeredUsers'] is List) {
      regUsers = (json['registeredUsers'] as List).map((u) {
        if (u is Map<String, dynamic>) return u;
        if (u is Map) return Map<String, dynamic>.from(u);
        return <String, dynamic>{};
      }).toList();
    }

    return Tournament(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Tournament',
      sport: json['sport']?.toString() ?? 'Football',
      status: parsedStatus,
      date: json['date']?.toString() ?? 'Upcoming',
      time: json['time']?.toString() ?? '09:00 AM',
      venue: json['venue']?.toString() ?? (json['venueName']?.toString() ?? 'Champions Arena'),
      location: json['location']?.toString() ?? 'Madurai',
      entryFee: entryFeeVal,
      prizePool: json['prizePool']?.toString() ?? '₹15,000',
      grandPrize: json['grandPrize']?.toString() ?? (json['prizePool']?.toString() ?? '₹15,000'),
      maxTeams: maxTeamsVal,
      registeredTeams: regTeamsVal,
      format: json['format']?.toString() ?? 'Knockout',
      imageUrl: json['imageUrl']?.toString() ?? (json['bannerUrl']?.toString() ?? 'https://picsum.photos/seed/tournament/800/400'),
      reportingTime: json['reportingTime']?.toString() ?? '30 minutes before match',
      matchDay: json['matchDay']?.toString() ?? 'Day 1',
      tournamentProgress: json['tournamentProgress']?.toString() ?? (parsedStatus == TournamentStatus.ongoing ? 'Live Now' : 'Upcoming'),
      registeredUsers: regUsers,
      isPrivate: json['isPrivate'] == true,
      accessCode: json['accessCode']?.toString(),
      rules: (json['rules'] is List) ? List<String>.from(json['rules']) : const [],
      isVenueTBA: json['isVenueTBA'] == true || (json['venue']?.toString().contains('TBA') ?? false),
      externalTicketUrl: json['externalTicketUrl']?.toString(),
      courtsCount: (json['courtsCount'] is num) ? (json['courtsCount'] as num).toInt() : 2,
      organizerPhone: json['organizerPhone']?.toString(),
      organizerName: json['organizerName']?.toString(),
    );
  }

  Tournament copyWith({
    String? id,
    String? title,
    String? sport,
    TournamentStatus? status,
    String? date,
    String? time,
    String? venue,
    String? location,
    String? entryFee,
    String? prizePool,
    String? grandPrize,
    int? maxTeams,
    int? registeredTeams,
    String? format,
    String? imageUrl,
    String? reportingTime,
    String? matchDay,
    String? tournamentProgress,
    List<Map<String, dynamic>>? registeredUsers,
    bool? isPrivate,
    String? accessCode,
    String? organizerPhone,
    String? organizerName,
  }) {
    return Tournament(
      id: id ?? this.id,
      title: title ?? this.title,
      sport: sport ?? this.sport,
      status: status ?? this.status,
      date: date ?? this.date,
      time: time ?? this.time,
      venue: venue ?? this.venue,
      location: location ?? this.location,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      grandPrize: grandPrize ?? this.grandPrize,
      maxTeams: maxTeams ?? this.maxTeams,
      registeredTeams: registeredTeams ?? this.registeredTeams,
      format: format ?? this.format,
      imageUrl: imageUrl ?? this.imageUrl,
      reportingTime: reportingTime ?? this.reportingTime,
      matchDay: matchDay ?? this.matchDay,
      tournamentProgress: tournamentProgress ?? this.tournamentProgress,
      registeredUsers: registeredUsers ?? this.registeredUsers,
      isPrivate: isPrivate ?? this.isPrivate,
      accessCode: accessCode ?? this.accessCode,
      organizerPhone: organizerPhone ?? this.organizerPhone,
      organizerName: organizerName ?? this.organizerName,
    );
  }
}

class TournamentManager extends ChangeNotifier {
  static final TournamentManager _instance = TournamentManager._internal();
  factory TournamentManager() => _instance;
  TournamentManager._internal() {
    _initUserData();
    fetchTournaments();
  }

  List<Tournament> _tournaments = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _currentUserPhone = '';
  Set<String> _myCreatedTournamentIds = {};
  Set<String> _myRegisteredTournamentIds = {};

  Future<void> _initUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserPhone = (prefs.getString('mobileNumber') ?? '').trim();
      final createdList = prefs.getStringList('my_created_tournament_ids') ?? [];
      final registeredList = prefs.getStringList('my_registered_tournament_ids') ?? [];
      _myCreatedTournamentIds = createdList.toSet();
      _myRegisteredTournamentIds = registeredList.toSet();
      notifyListeners();
    } catch (_) {}
  }

  void updateCurrentUserPhone(String phone) {
    _currentUserPhone = phone.trim();
    notifyListeners();
  }

  List<Tournament> get allTournaments => _tournaments;
  List<Tournament> get ongoingTournaments =>
      _tournaments.where((t) => t.status == TournamentStatus.ongoing).toList();
  List<Tournament> get upcomingTournaments =>
      _tournaments.where((t) => t.status == TournamentStatus.upcoming).toList();

  List<Tournament> get myTournaments {
    final cleanPhone = _currentUserPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final last10 = cleanPhone.length >= 10
        ? cleanPhone.substring(cleanPhone.length - 10)
        : cleanPhone;

    return _tournaments.where((t) {
      // 1. Locally recorded created or registered tournament IDs
      if (_myCreatedTournamentIds.contains(t.id) ||
          _myRegisteredTournamentIds.contains(t.id)) {
        return true;
      }

      // If user phone is not known yet, do not falsely display other users' tournaments
      if (last10.isEmpty) return false;

      // 2. Created by current user (organizerPhone match)
      if (t.organizerPhone != null && t.organizerPhone!.trim().isNotEmpty) {
        final orgClean = t.organizerPhone!.replaceAll(RegExp(r'[^0-9]'), '');
        final orgLast10 = orgClean.length >= 10
            ? orgClean.substring(orgClean.length - 10)
            : orgClean;
        if (orgLast10.isNotEmpty && orgLast10 == last10) {
          return true;
        }
      }

      // 3. Registered / Joined by current user (team contact phone match)
      for (final u in t.registeredUsers) {
        final contact = (u['contact'] ?? u['phone'] ?? u['mobileNumber'] ?? '')
            .toString()
            .replaceAll(RegExp(r'[^0-9]'), '');
        final contactLast10 = contact.length >= 10
            ? contact.substring(contact.length - 10)
            : contact;
        if (contactLast10.isNotEmpty && contactLast10 == last10) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  Future<void> fetchTournaments({String? sport}) async {
    _isLoading = true;
    await _initUserData();
    try {
      final url = (sport != null && sport.isNotEmpty && sport != 'All Sports')
          ? '${ApiConfig.baseUrl}/turfs/tournaments?sport=${Uri.encodeComponent(sport)}'
          : '${ApiConfig.baseUrl}/turfs/tournaments';
      http.Response res;
      try {
        res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 18));
      } catch (_) {
        // Cold start retry once
        await Future.delayed(const Duration(milliseconds: 1000));
        res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 18));
      }
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        _tournaments = list.map((item) => Tournament.fromJson(Map<String, dynamic>.from(item))).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching realtime tournaments: $e");
    } finally {
      _isLoading = false;
    }
  }

  void addTournament(Tournament tournament) {
    _tournaments.insert(0, tournament);
    _myCreatedTournamentIds.add(tournament.id);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('my_created_tournament_ids', _myCreatedTournamentIds.toList());
    }).catchError((_) {});
    notifyListeners();
  }

  Future<bool> createTournamentInBackend(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/turfs/tournaments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        try {
          final resJson = jsonDecode(res.body);
          final createdId = (resJson['tournament']?['id'] ?? resJson['id'])?.toString();
          if (createdId != null && createdId.isNotEmpty) {
            _myCreatedTournamentIds.add(createdId);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('my_created_tournament_ids', _myCreatedTournamentIds.toList());
          }
        } catch (_) {}
        await fetchTournaments();
        return true;
      }
    } catch (e) {
      debugPrint("Error creating tournament in backend: $e");
    }
    return false;
  }

  Future<bool> registerTeam(
    String tournamentId,
    Map<String, dynamic> registrationData,
  ) async {
    final index = _tournaments.indexWhere((t) => t.id == tournamentId);
    if (index != -1) {
      final tournament = _tournaments[index];
      if (tournament.registeredTeams < tournament.maxTeams) {
        bool alreadyRegistered = tournament.registeredUsers.any(
          (user) => user['teamName'] == registrationData['teamName'],
        );
        if (alreadyRegistered) {
          return false;
        }

        final updatedUsers = List<Map<String, dynamic>>.from(
          tournament.registeredUsers,
        )..add(registrationData);
        _tournaments[index] = tournament.copyWith(
          registeredTeams: tournament.registeredTeams + 1,
          registeredUsers: updatedUsers,
        );

        _myRegisteredTournamentIds.add(tournamentId);
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('my_registered_tournament_ids', _myRegisteredTournamentIds.toList());
        } catch (_) {}

        notifyListeners();

        // Sync with backend database
        try {
          final intId = int.tryParse(tournamentId);
          if (intId != null) {
            await http.post(
              Uri.parse('${ApiConfig.baseUrl}/turfs/tournaments/$intId/register'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(registrationData),
            );
          }
        } catch (e) {
          debugPrint("Error registering tournament in backend: $e");
        }
        return true;
      }
    }
    return false;
  }
}
