import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    );
  }
}

class TournamentManager extends ChangeNotifier {
  static final TournamentManager _instance = TournamentManager._internal();
  factory TournamentManager() => _instance;
  TournamentManager._internal() {
    fetchTournaments();
  }

  List<Tournament> _tournaments = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Tournament> get allTournaments => _tournaments;
  List<Tournament> get ongoingTournaments =>
      _tournaments.where((t) => t.status == TournamentStatus.ongoing).toList();
  List<Tournament> get upcomingTournaments =>
      _tournaments.where((t) => t.status == TournamentStatus.upcoming).toList();
  List<Tournament> get myTournaments =>
      _tournaments.where((t) => t.registeredUsers.isNotEmpty).toList();

  Future<void> fetchTournaments({String? sport}) async {
    _isLoading = true;
    try {
      final url = (sport != null && sport.isNotEmpty && sport != 'All Sports')
          ? '${ApiConfig.baseUrl}/turfs/tournaments?sport=${Uri.encodeComponent(sport)}'
          : '${ApiConfig.baseUrl}/turfs/tournaments';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
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
