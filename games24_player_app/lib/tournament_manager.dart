import 'package:flutter/material.dart';

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
  });

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
  TournamentManager._internal();

  final List<Tournament> _tournaments = [];

  List<Tournament> get allTournaments => _tournaments;
  List<Tournament> get ongoingTournaments =>
      _tournaments.where((t) => t.status == TournamentStatus.ongoing).toList();
  List<Tournament> get upcomingTournaments =>
      _tournaments.where((t) => t.status == TournamentStatus.upcoming).toList();
  List<Tournament> get myTournaments =>
      _tournaments.where((t) => t.registeredUsers.isNotEmpty).toList();

  void addTournament(Tournament tournament) {
    _tournaments.add(tournament);
    notifyListeners();
  }

  bool registerTeam(
    String tournamentId,
    Map<String, dynamic> registrationData,
  ) {
    final index = _tournaments.indexWhere((t) => t.id == tournamentId);
    if (index != -1) {
      final tournament = _tournaments[index];
      if (tournament.registeredTeams < tournament.maxTeams) {
        // Prevent duplicate registration based on team name (simplistic check)
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
        return true;
      }
    }
    return false;
  }
}
