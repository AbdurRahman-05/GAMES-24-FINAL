import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' hide PermissionStatus;
import 'package:shared_preferences/shared_preferences.dart';

class PlayerItem {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String avatarInitials;
  final bool isPhysicalContact;

  PlayerItem({
    required this.id,
    required this.name,
    required this.phone,
    this.role = 'Player',
    String? avatarInitials,
    this.isPhysicalContact = false,
  }) : avatarInitials = avatarInitials ?? _getInitials(name);

  static String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'PL';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role,
        'avatarInitials': avatarInitials,
        'isPhysicalContact': isPhysicalContact,
      };

  factory PlayerItem.fromJson(Map<String, dynamic> json) => PlayerItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Player',
        phone: json['phone']?.toString() ?? '',
        role: json['role']?.toString() ?? 'Player',
        avatarInitials: json['avatarInitials']?.toString(),
        isPhysicalContact: json['isPhysicalContact'] == true,
      );
}

class PlayerMatchStat {
  final String name;
  final String role;
  int runs;
  int balls;
  int fours;
  int sixes;
  bool isOut;
  int ballsBowled;
  int runsConceded;
  int wickets;
  int maidens;
  int catches;
  int runOuts;

  PlayerMatchStat({
    required this.name,
    this.role = 'Player',
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.ballsBowled = 0,
    this.runsConceded = 0,
    this.wickets = 0,
    this.maidens = 0,
    this.catches = 0,
    this.runOuts = 0,
  });

  String get strikeRate =>
      balls > 0 ? ((runs / balls) * 100).toStringAsFixed(1) : '0.0';

  String get oversBowled => '${ballsBowled ~/ 6}.${ballsBowled % 6}';

  String get economy => ballsBowled > 0
      ? (runsConceded / (ballsBowled / 6.0)).toStringAsFixed(1)
      : '0.0';

  int get fantasyPoints => (runs * 1) + (wickets * 25) + (catches * 10) + (sixes * 2);

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'runs': runs,
        'balls': balls,
        'fours': fours,
        'sixes': sixes,
        'isOut': isOut,
        'ballsBowled': ballsBowled,
        'runsConceded': runsConceded,
        'wickets': wickets,
        'maidens': maidens,
        'catches': catches,
        'runOuts': runOuts,
      };

  factory PlayerMatchStat.fromJson(Map<String, dynamic> json) =>
      PlayerMatchStat(
        name: json['name']?.toString() ?? 'Player',
        role: json['role']?.toString() ?? 'Player',
        runs: int.tryParse(json['runs']?.toString() ?? '0') ?? 0,
        balls: int.tryParse(json['balls']?.toString() ?? '0') ?? 0,
        fours: int.tryParse(json['fours']?.toString() ?? '0') ?? 0,
        sixes: int.tryParse(json['sixes']?.toString() ?? '0') ?? 0,
        isOut: json['isOut'] == true,
        ballsBowled:
            int.tryParse(json['ballsBowled']?.toString() ?? '0') ?? 0,
        runsConceded:
            int.tryParse(json['runsConceded']?.toString() ?? '0') ?? 0,
        wickets: int.tryParse(json['wickets']?.toString() ?? '0') ?? 0,
        maidens: int.tryParse(json['maidens']?.toString() ?? '0') ?? 0,
        catches: int.tryParse(json['catches']?.toString() ?? '0') ?? 0,
        runOuts: int.tryParse(json['runOuts']?.toString() ?? '0') ?? 0,
      );
}

class MatchResultItem {
  final String id;
  final String bookingId;
  final String turfName;
  final String sport;
  final String date;
  final String timeSlot;
  final String teamAName;
  final String teamBName;
  final List<PlayerItem> teamAPlayers;
  final List<PlayerItem> teamBPlayers;
  final String tossWinner;
  final String tossDecision;
  final String teamAScore;
  final String teamBScore;
  final String winner;
  final String winningMargin;
  final bool userWon;
  final DateTime completedAt;
  final String? manOfTheMatch;
  final String? highestScorer;
  final String? bestBowler;
  final String? bestFielder;
  final int? overs;
  final String? teamSize;
  final int matchIndex;
  final List<PlayerMatchStat> playerStatsA;
  final List<PlayerMatchStat> playerStatsB;

  MatchResultItem({
    required this.id,
    required this.bookingId,
    required this.turfName,
    required this.sport,
    required this.date,
    required this.timeSlot,
    required this.teamAName,
    required this.teamBName,
    required this.teamAPlayers,
    required this.teamBPlayers,
    required this.tossWinner,
    required this.tossDecision,
    required this.teamAScore,
    required this.teamBScore,
    required this.winner,
    required this.winningMargin,
    required this.userWon,
    DateTime? completedAt,
    this.manOfTheMatch,
    this.highestScorer,
    this.bestBowler,
    this.bestFielder,
    this.overs,
    this.teamSize,
    this.matchIndex = 1,
    List<PlayerMatchStat>? playerStatsA,
    List<PlayerMatchStat>? playerStatsB,
  })  : completedAt = completedAt ?? DateTime.now(),
        playerStatsA = playerStatsA ?? [],
        playerStatsB = playerStatsB ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'turfName': turfName,
        'sport': sport,
        'date': date,
        'timeSlot': timeSlot,
        'teamAName': teamAName,
        'teamBName': teamBName,
        'teamAPlayers': teamAPlayers.map((p) => p.toJson()).toList(),
        'teamBPlayers': teamBPlayers.map((p) => p.toJson()).toList(),
        'tossWinner': tossWinner,
        'tossDecision': tossDecision,
        'teamAScore': teamAScore,
        'teamBScore': teamBScore,
        'winner': winner,
        'winningMargin': winningMargin,
        'userWon': userWon,
        'completedAt': completedAt.toIso8601String(),
        'manOfTheMatch': manOfTheMatch,
        'highestScorer': highestScorer,
        'bestBowler': bestBowler,
        'bestFielder': bestFielder,
        'overs': overs,
        'teamSize': teamSize,
        'matchIndex': matchIndex,
        'playerStatsA': playerStatsA.map((s) => s.toJson()).toList(),
        'playerStatsB': playerStatsB.map((s) => s.toJson()).toList(),
      };

  factory MatchResultItem.fromJson(Map<String, dynamic> json) =>
      MatchResultItem(
        id: json['id']?.toString() ?? '',
        bookingId: json['bookingId']?.toString() ?? '',
        turfName: json['turfName']?.toString() ?? 'Turf Arena',
        sport: json['sport']?.toString() ?? 'Cricket',
        date: json['date']?.toString() ?? '',
        timeSlot: json['timeSlot']?.toString() ?? '',
        teamAName: json['teamAName']?.toString() ?? 'Team A',
        teamBName: json['teamBName']?.toString() ?? 'Team B',
        teamAPlayers: (json['teamAPlayers'] as List?)
                ?.map((p) => PlayerItem.fromJson(Map<String, dynamic>.from(p)))
                .toList() ??
            [],
        teamBPlayers: (json['teamBPlayers'] as List?)
                ?.map((p) => PlayerItem.fromJson(Map<String, dynamic>.from(p)))
                .toList() ??
            [],
        tossWinner: json['tossWinner']?.toString() ?? 'Team A',
        tossDecision: json['tossDecision']?.toString() ?? 'Bat First',
        teamAScore: json['teamAScore']?.toString() ?? '0',
        teamBScore: json['teamBScore']?.toString() ?? '0',
        winner: json['winner']?.toString() ?? 'Team A',
        winningMargin: json['winningMargin']?.toString() ?? '',
        userWon: json['userWon'] == true,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        manOfTheMatch: json['manOfTheMatch']?.toString(),
        highestScorer: json['highestScorer']?.toString(),
        bestBowler: json['bestBowler']?.toString(),
        bestFielder: json['bestFielder']?.toString(),
        overs: int.tryParse(json['overs']?.toString() ?? ''),
        teamSize: json['teamSize']?.toString(),
        matchIndex: int.tryParse(json['matchIndex']?.toString() ?? '1') ?? 1,
        playerStatsA: (json['playerStatsA'] as List?)
                ?.map((s) => PlayerMatchStat.fromJson(Map<String, dynamic>.from(s)))
                .toList() ??
            [],
        playerStatsB: (json['playerStatsB'] as List?)
                ?.map((s) => PlayerMatchStat.fromJson(Map<String, dynamic>.from(s)))
                .toList() ??
            [],
      );
}

class MatchScoreManager {
  static final MatchScoreManager _instance = MatchScoreManager._internal();
  factory MatchScoreManager() => _instance;

  final ValueNotifier<int> statsNotifier = ValueNotifier<int>(0);
  final List<MatchResultItem> _matches = [];

  int _extraWins = 0;
  int _extraMatches = 0;
  double _formBonus = 0.0;

  MatchScoreManager._internal() {
    _loadFromStorage();
  }

  List<MatchResultItem> get matches => List.unmodifiable(_matches);
  int get extraWins => _extraWins;
  int get extraMatches => _extraMatches;

  MatchResultItem? getLatestResultForBooking(String bookingId) {
    try {
      return _matches.firstWhere((m) => m.bookingId == bookingId);
    } catch (_) {
      return null;
    }
  }

  List<MatchResultItem> getAllResultsForBooking(String bookingId) {
    return _matches.where((m) => m.bookingId == bookingId).toList();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _extraWins = prefs.getInt('player_scorecard_wins') ?? 0;
      _extraMatches = prefs.getInt('player_scorecard_matches') ?? 0;
      _formBonus = prefs.getDouble('player_scorecard_form_bonus') ?? 0.0;

      final savedJson = prefs.getString('player_scorecard_history_v1');
      if (savedJson != null && savedJson.isNotEmpty) {
        final List list = jsonDecode(savedJson);
        _matches.clear();
        for (final item in list) {
          _matches.add(MatchResultItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      statsNotifier.value++;
    } catch (e) {
      debugPrint('Error loading MatchScoreManager data: $e');
    }
  }

  Future<void> _persistToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('player_scorecard_wins', _extraWins);
      await prefs.setInt('player_scorecard_matches', _extraMatches);
      await prefs.setDouble('player_scorecard_form_bonus', _formBonus);

      final jsonStr = jsonEncode(_matches.map((m) => m.toJson()).toList());
      await prefs.setString('player_scorecard_history_v1', jsonStr);
    } catch (e) {
      debugPrint('Error saving MatchScoreManager data: $e');
    }
  }

  int getTotalMatches(int baseBookingsCount) {
    final count = baseBookingsCount + _extraMatches;
    return count > 0 ? count : (_extraMatches > 0 ? _extraMatches : 1);
  }

  int getTotalWins(int baseBookingsCount) {
    final base = (baseBookingsCount > 0 ? (baseBookingsCount * 0.6).round() : 0);
    final total = base + _extraWins;
    return total > 0 ? total : (_extraWins > 0 ? _extraWins : 1);
  }

  String getFormIndex(int baseBookingsCount) {
    final baseMatches = getTotalMatches(baseBookingsCount);
    if (baseMatches <= 0) return '0.0';
    double score = 8.2 + _formBonus;
    if (score > 9.9) score = 9.9;
    return score.toStringAsFixed(1);
  }

  Future<void> recordMatchResult(MatchResultItem result) async {
    _matches.insert(0, result);
    _extraMatches += 1;
    if (result.userWon) {
      _extraWins += 1;
      _formBonus += 0.4;
    } else {
      _formBonus = (_formBonus - 0.1).clamp(0.0, 1.7);
    }
    statsNotifier.value++;
    await _persistToStorage();
  }

  List<PlayerItem>? _cachedRealContacts;

  /// Fetches real physical contacts from the device using flutter_contacts & permissions
  Future<List<PlayerItem>> fetchPhysicalContacts() async {
    if (_cachedRealContacts != null && _cachedRealContacts!.isNotEmpty) {
      return List<PlayerItem>.from(_cachedRealContacts!);
    }
    try {
      bool permission = false;
      try {
        final status = await FlutterContacts.permissions.request(PermissionType.read);
        permission = (status == PermissionStatus.granted || status == PermissionStatus.limited);
      } catch (_) {
        try {
          final phStatus = await Permission.contacts.request();
          permission = phStatus.isGranted || phStatus.isLimited;
        } catch (_) {}
      }

      if (permission) {
        final deviceContacts = await FlutterContacts.getAll(
          properties: {ContactProperty.name, ContactProperty.phone},
        );
        final List<PlayerItem> items = [];
        final Set<String> seenNumbers = {};

        for (final c in deviceContacts) {
          final name = (c.displayName != null && c.displayName!.trim().isNotEmpty)
              ? c.displayName!.trim()
              : ('${c.name?.first ?? ''} ${c.name?.last ?? ''}').trim();
          if (name.isEmpty) continue;

          for (final ph in c.phones) {
            final rawNumber = ph.number.trim();
            final normalized = rawNumber.replaceAll(RegExp(r'[^0-9+]'), '');
            if (normalized.length >= 7 && !seenNumbers.contains(normalized)) {
              seenNumbers.add(normalized);
              items.add(PlayerItem(
                id: 'ph_${c.id ?? items.length}',
                name: name,
                phone: rawNumber,
                role: 'Player',
                isPhysicalContact: true,
              ));
              break;
            }
          }
        }
        if (items.isNotEmpty) {
          _cachedRealContacts = items;
          return List<PlayerItem>.from(items);
        }
      }
    } catch (e) {
      debugPrint("Error fetching physical contacts: $e");
    }
    return getDeviceContacts();
  }

  // Pre-configured address book contacts for realistic contact picker / simulator fallback
  List<PlayerItem> getDeviceContacts() {
    if (_cachedRealContacts != null && _cachedRealContacts!.isNotEmpty) {
      return List<PlayerItem>.from(_cachedRealContacts!);
    }
    return [
      PlayerItem(id: 'c1', name: 'Alex Hunter', phone: '+91 98765 43210', role: 'Captain / All-Rounder'),
      PlayerItem(id: 'c2', name: 'Karthik Raja', phone: '+91 98412 34567', role: 'Striker / Batsman'),
      PlayerItem(id: 'c3', name: 'Rohan Sharma', phone: '+91 97890 12345', role: 'Fast Bowler'),
      PlayerItem(id: 'c4', name: 'Vikas Nair', phone: '+91 96543 21098', role: 'Goalkeeper / Wicket Keeper'),
      PlayerItem(id: 'c5', name: 'Suresh Kumar', phone: '+91 95432 10987', role: 'Midfielder / Spinner'),
      PlayerItem(id: 'c6', name: 'David Miller', phone: '+91 94321 09876', role: 'Power Hitter'),
      PlayerItem(id: 'c7', name: 'Arjun Patel', phone: '+91 93210 98765', role: 'Defender / Opener'),
      PlayerItem(id: 'c8', name: 'Mohamed Imran', phone: '+91 92109 87654', role: 'Pacer / Winger'),
      PlayerItem(id: 'c9', name: 'Pradeep Chandran', phone: '+91 91098 76543', role: 'Vice Captain'),
      PlayerItem(id: 'c10', name: 'Dinesh Balaji', phone: '+91 90987 65432', role: 'Finisher'),
    ];
  }
}

