import 'core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final String? subtitle;
  final String? description;
  final String? courtAllocation;
  final String? startDate;
  final String? endDate;
  final String? registrationDeadline;
  final int playersPerTeam;
  final String? championPrize;
  final String? runnerUpPrize;
  final bool isOwnerCreated;
  final String createdByRole;

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
    this.subtitle,
    this.description,
    this.courtAllocation,
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.playersPerTeam = 8,
    this.championPrize,
    this.runnerUpPrize,
    this.isOwnerCreated = true,
    this.createdByRole = 'OWNER',
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

    final mockNames = {
      'super strikers',
      'royal kings',
      'madurai panthers',
      'kk nagar xi',
      'anna nagar titans',
      'chola warriors',
    };

    List<Map<String, dynamic>> regUsers = [];
    if (json['registeredUsers'] is List) {
      for (final u in (json['registeredUsers'] as List)) {
        if (u is Map) {
          final m = Map<String, dynamic>.from(u);
          final tName = (m['teamName'] ?? '').toString().trim();
          final regId = (m['id'] ?? '').toString();
          if (tName.isEmpty ||
              mockNames.contains(tName.toLowerCase()) ||
              regId.startsWith('reg_')) {
            continue; // Skip mock teams
          }
          regUsers.add(m);
        }
      }
    }

    final realTeamsCount = regUsers.length;

    return Tournament(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Tournament',
      sport: json['sport']?.toString() ?? 'Football',
      status: parsedStatus,
      date: json['date']?.toString() ?? 'Upcoming',
      time: json['time']?.toString() ?? '09:00 AM',
      venue:
          json['venue']?.toString() ??
          (json['venueName']?.toString() ?? 'Champions Arena'),
      location: json['location']?.toString() ?? 'Madurai',
      entryFee: entryFeeVal,
      prizePool: json['prizePool']?.toString() ?? '₹15,000',
      grandPrize:
          json['grandPrize']?.toString() ??
          (json['prizePool']?.toString() ?? '₹15,000'),
      maxTeams: maxTeamsVal,
      registeredTeams: realTeamsCount,
      format: json['format']?.toString() ?? 'Knockout',
      imageUrl:
          json['imageUrl']?.toString() ??
          (json['bannerUrl']?.toString() ??
              'https://picsum.photos/seed/tournament/800/400'),
      reportingTime:
          json['reportingTime']?.toString() ?? '30 minutes before match',
      matchDay: json['matchDay']?.toString() ?? 'Day 1',
      tournamentProgress:
          json['tournamentProgress']?.toString() ??
          (parsedStatus == TournamentStatus.ongoing ? 'Live Now' : 'Upcoming'),
      registeredUsers: regUsers,
      isPrivate: json['isPrivate'] == true,
      accessCode: json['accessCode']?.toString(),
      rules: (json['rules'] is List)
          ? List<String>.from(json['rules'])
          : const [],
      isVenueTBA:
          json['isVenueTBA'] == true ||
          (json['venue']?.toString().contains('TBA') ?? false),
      externalTicketUrl: json['externalTicketUrl']?.toString(),
      courtsCount: (json['courtsCount'] is num)
          ? (json['courtsCount'] as num).toInt()
          : 2,
      organizerPhone: json['organizerPhone']?.toString(),
      organizerName: json['organizerName']?.toString(),
      subtitle: json['subtitle']?.toString(),
      description: json['description']?.toString(),
      courtAllocation: json['courtAllocation']?.toString(),
      startDate: json['startDate']?.toString() ?? json['date']?.toString(),
      endDate: json['endDate']?.toString(),
      registrationDeadline: json['registrationDeadline']?.toString(),
      playersPerTeam: (json['playersPerTeam'] is num)
          ? (json['playersPerTeam'] as num).toInt()
          : (int.tryParse(json['playersPerTeam']?.toString() ?? '') ?? 8),
      championPrize:
          json['championPrize']?.toString() ?? json['prizePool']?.toString(),
      runnerUpPrize: json['runnerUpPrize']?.toString(),
      isOwnerCreated:
          json['isOwnerCreated'] == true ||
          json['createdByRole'] == 'OWNER' ||
          (json['verifiedAdminId'] != null && json['verifiedAdminId'] != 0),
      createdByRole:
          json['createdByRole']?.toString() ??
          ((json['isOwnerCreated'] == true || json['verifiedAdminId'] != null)
              ? 'OWNER'
              : 'PLAYER'),
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
    String? subtitle,
    String? description,
    String? courtAllocation,
    String? startDate,
    String? endDate,
    String? registrationDeadline,
    int? playersPerTeam,
    String? championPrize,
    String? runnerUpPrize,
    bool? isOwnerCreated,
    String? createdByRole,
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
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      courtAllocation: courtAllocation ?? this.courtAllocation,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      playersPerTeam: playersPerTeam ?? this.playersPerTeam,
      championPrize: championPrize ?? this.championPrize,
      runnerUpPrize: runnerUpPrize ?? this.runnerUpPrize,
      isOwnerCreated: isOwnerCreated ?? this.isOwnerCreated,
      createdByRole: createdByRole ?? this.createdByRole,
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
      final createdList =
          prefs.getStringList('my_created_tournament_ids') ?? [];
      final registeredList =
          prefs.getStringList('my_registered_tournament_ids') ?? [];
      _myCreatedTournamentIds = createdList.toSet();
      _myRegisteredTournamentIds = registeredList.toSet();
      notifyListeners();
    } catch (_) {}
  }

  /// Clears the previous user's tournament state (logout / account switch) and reloads.
  Future<void> reset() async {
    _tournaments = [];
    _currentUserPhone = '';
    _myCreatedTournamentIds = {};
    _myRegisteredTournamentIds = {};
    notifyListeners();
    await fetchTournaments();
  }

  void updateCurrentUserPhone(String phone) {
    _currentUserPhone = phone.trim();
    notifyListeners();
  }

  bool isUserRegistered(Tournament t) {
    if (_myRegisteredTournamentIds.contains(t.id)) return true;
    final cleanNumericId = t.id.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumericId.isNotEmpty) {
      if (_myRegisteredTournamentIds.contains(cleanNumericId) ||
          _myRegisteredTournamentIds.contains('tourn_$cleanNumericId')) {
        return true;
      }
    }

    final cleanPhone = _currentUserPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final last10 = cleanPhone.length >= 10
        ? cleanPhone.substring(cleanPhone.length - 10)
        : cleanPhone;

    if (last10.isNotEmpty) {
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
    }
    return false;
  }

  Map<String, dynamic>? getRegisteredTeam(Tournament t) {
    final cleanPhone = _currentUserPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final last10 = cleanPhone.length >= 10
        ? cleanPhone.substring(cleanPhone.length - 10)
        : cleanPhone;

    if (last10.isNotEmpty) {
      for (final u in t.registeredUsers) {
        final contact = (u['contact'] ?? u['phone'] ?? u['mobileNumber'] ?? '')
            .toString()
            .replaceAll(RegExp(r'[^0-9]'), '');
        final contactLast10 = contact.length >= 10
            ? contact.substring(contact.length - 10)
            : contact;
        if (contactLast10.isNotEmpty && contactLast10 == last10) {
          return u;
        }
      }
    }

    if (isUserRegistered(t) && t.registeredUsers.isNotEmpty) {
      return t.registeredUsers.last;
    }
    return null;
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
          _myRegisteredTournamentIds.contains(t.id) ||
          isUserRegistered(t)) {
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
      // "viewer" lets the server include this player's own private tournaments.
      final res = await ApiClient.get('/turfs/tournaments', query: {
        'sport': (sport != null && sport.isNotEmpty && sport != 'All Sports') ? sport : null,
        'viewer': _currentUserPhone.isNotEmpty ? _currentUserPhone : null,
      });
      if (res.ok && res.data is List) {
        _tournaments = (res.data as List)
            .map((item) => Tournament.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching realtime tournaments: $e");
    } finally {
      _isLoading = false;
    }
  }

  /// Finds a private tournament by its access PIN and adds it to the list so it can be opened.
  Future<({Tournament? tournament, String? error})> findPrivateTournament(String pin) async {
    final res = await ApiClient.get('/turfs/tournaments/private/${Uri.encodeComponent(pin.trim())}');
    if (!res.ok || res.map['tournament'] is! Map) {
      return (tournament: null, error: res.message);
    }
    final json = Map<String, dynamic>.from(res.map['tournament'] as Map);
    json['accessCode'] = pin.trim().toUpperCase(); // remember the PIN for registration
    final t = Tournament.fromJson(json);
    _tournaments.removeWhere((x) => x.id == t.id);
    _tournaments.insert(0, t);
    notifyListeners();
    return (tournament: t, error: null);
  }

  void addTournament(Tournament tournament) {
    _tournaments.insert(0, tournament);
    _myCreatedTournamentIds.add(tournament.id);
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.setStringList(
            'my_created_tournament_ids',
            _myCreatedTournamentIds.toList(),
          );
        })
        .catchError((_) {});
    notifyListeners();
  }

  /// Creates the tournament on the server. Returns null on success or the server's error.
  /// Nothing is added locally on failure (no phantom tournaments only this phone can see).
  Future<String?> createTournamentInBackend(Map<String, dynamic> data) async {
    final res = await ApiClient.post('/turfs/tournaments', body: data);
    if (!res.ok) return res.message;
    final created = res.map['tournament'];
    final createdId = (created is Map ? created['id'] : res.map['id'])?.toString();
    if (createdId != null && createdId.isNotEmpty) {
      _myCreatedTournamentIds.add(createdId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('my_created_tournament_ids', _myCreatedTournamentIds.toList());
    }
    if (created is Map && created['accessCode'] != null) {
      lastCreatedAccessCode = created['accessCode'].toString();
    }
    await fetchTournaments();
    return null;
  }

  /// PIN assigned by the server to the most recently created private tournament.
  String? lastCreatedAccessCode;

  /// Registers a team. Only marks the tournament as joined when the server accepts it.
  /// Returns null on success or the server's reason (full, on hold, wrong PIN, duplicate...).
  Future<String?> registerTeam(
    String tournamentId,
    Map<String, dynamic> registrationData,
  ) async {
    final intId = int.tryParse(tournamentId.replaceAll(RegExp(r'[^0-9]'), ''));
    if (intId == null || intId <= 0) return 'This tournament could not be found.';

    final t = _tournaments.where((x) => x.id == tournamentId).firstOrNull;
    final body = Map<String, dynamic>.from(registrationData);
    if (t?.isPrivate == true && (t?.accessCode ?? '').isNotEmpty) {
      body['accessCode'] = t!.accessCode;
    }

    final res = await ApiClient.post('/turfs/tournaments/$intId/register', body: body);
    if (!res.ok) return res.message;

    _myRegisteredTournamentIds.add(tournamentId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('my_registered_tournament_ids', _myRegisteredTournamentIds.toList());
    } catch (_) {}
    await fetchTournaments();
    return null;
  }
}
