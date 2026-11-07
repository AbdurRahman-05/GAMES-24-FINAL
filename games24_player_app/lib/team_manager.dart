import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerTeam {
  final String id;
  final String name;
  final String sport;
  final String roleBadge;
  final bool isCaptain;
  final String squadSize;
  final int membersCount;
  final int winsCount;
  final String rating;
  final String logoUrl;
  final String? nextMatchText;
  final String? nextMatchTime;
  final String dateText;

  PlayerTeam({
    required this.id,
    required this.name,
    required this.sport,
    this.roleBadge = 'Captain',
    this.isCaptain = true,
    this.squadSize = '7v7 Squad',
    this.membersCount = 1,
    this.winsCount = 0,
    this.rating = '5.0',
    this.logoUrl = 'https://picsum.photos/seed/team_default/150/150',
    this.nextMatchText,
    this.nextMatchTime,
    this.dateText = 'Joined Recently',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sport': sport,
    'roleBadge': roleBadge,
    'isCaptain': isCaptain,
    'squadSize': squadSize,
    'membersCount': membersCount,
    'winsCount': winsCount,
    'rating': rating,
    'logoUrl': logoUrl,
    'nextMatchText': nextMatchText,
    'nextMatchTime': nextMatchTime,
    'dateText': dateText,
  };

  factory PlayerTeam.fromJson(Map<String, dynamic> json) => PlayerTeam(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    sport: json['sport']?.toString() ?? 'Football',
    roleBadge: json['roleBadge']?.toString() ?? 'Captain',
    isCaptain: json['isCaptain'] == true,
    squadSize: json['squadSize']?.toString() ?? '7v7 Squad',
    membersCount: int.tryParse(json['membersCount']?.toString() ?? '1') ?? 1,
    winsCount: int.tryParse(json['winsCount']?.toString() ?? '0') ?? 0,
    rating: json['rating']?.toString() ?? '5.0',
    logoUrl: json['logoUrl']?.toString() ?? 'https://picsum.photos/seed/team_default/150/150',
    nextMatchText: json['nextMatchText']?.toString(),
    nextMatchTime: json['nextMatchTime']?.toString(),
    dateText: json['dateText']?.toString() ?? 'Joined Recently',
  );
}

class TeamManager {
  static final TeamManager _instance = TeamManager._internal();
  factory TeamManager() => _instance;
  TeamManager._internal() {
    _loadFromStorage();
  }

  static const String _storageKey = 'user_player_teams';
  final ValueNotifier<List<PlayerTeam>> teamsNotifier = ValueNotifier<List<PlayerTeam>>([]);

  List<PlayerTeam> get teams => teamsNotifier.value;

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_storageKey);
      if (str != null && str.isNotEmpty) {
        final List list = jsonDecode(str);
        final loaded = list
            .map((item) => PlayerTeam.fromJson(Map<String, dynamic>.from(item)))
            .where((t) => t.name != 'Blazing Strikers FC' && t.name != 'Thunder Smashers')
            .toList();
        teamsNotifier.value = loaded;
      }
    } catch (e) {
      debugPrint("Error loading teams: $e");
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = jsonEncode(teamsNotifier.value.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, str);
    } catch (e) {
      debugPrint("Error saving teams: $e");
    }
  }

  Future<void> createTeam({
    required String name,
    required String sport,
    required String squadSize,
  }) async {
    final newTeam = PlayerTeam(
      id: 'team_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      sport: sport,
      squadSize: squadSize,
      roleBadge: 'Captain',
      isCaptain: true,
      membersCount: 1,
      winsCount: 0,
      rating: '5.0',
      dateText: 'Created Today',
    );

    teamsNotifier.value = [newTeam, ...teamsNotifier.value];
    await _saveToStorage();
  }

  Future<bool> joinTeamWithCode(String code) async {
    if (code.trim().isEmpty) return false;
    final cleanCode = code.trim().toUpperCase();
    final newTeam = PlayerTeam(
      id: 'team_joined_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Squad $cleanCode',
      sport: 'Football',
      squadSize: '7v7 Squad',
      roleBadge: 'Member',
      isCaptain: false,
      membersCount: 8,
      winsCount: 0,
      rating: '5.0',
      dateText: 'Joined with Code',
    );

    teamsNotifier.value = [newTeam, ...teamsNotifier.value];
    await _saveToStorage();
    return true;
  }
}

