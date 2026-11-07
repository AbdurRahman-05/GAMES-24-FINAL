import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerItem {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String avatarInitials;

  PlayerItem({
    required this.id,
    required this.name,
    required this.phone,
    this.role = 'Player',
    String? avatarInitials,
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
      };

  factory PlayerItem.fromJson(Map<String, dynamic> json) => PlayerItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Player',
        phone: json['phone']?.toString() ?? '',
        role: json['role']?.toString() ?? 'Player',
        avatarInitials: json['avatarInitials']?.toString(),
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
  }) : completedAt = completedAt ?? DateTime.now();

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

  // Pre-configured address book contacts for realistic contact picker
  List<PlayerItem> getDeviceContacts() {
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

