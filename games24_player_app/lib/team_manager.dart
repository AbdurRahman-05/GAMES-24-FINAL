import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'match_score_manager.dart';

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
  final List<PlayerItem> members;

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
    List<PlayerItem>? members,
  }) : members = members ?? [];

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
    'members': members.map((m) => m.toJson()).toList(),
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
    members: (json['members'] as List?)
        ?.map((m) => PlayerItem.fromJson(Map<String, dynamic>.from(m)))
        .where((p) => !MatchScoreManager.isDemoPlayer(p))
        .toList() ?? [],
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

      final phone = (prefs.getString('mobileNumber') ?? '').trim();
      if (phone.isNotEmpty) {
        final res = await http
            .get(Uri.parse('${ApiConfig.baseUrl}/auth/user-profile?phone=${Uri.encodeComponent(phone)}'))
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['teams'] is List && (data['teams'] as List).isNotEmpty) {
            final remoteTeams = (data['teams'] as List)
                .map((item) => PlayerTeam.fromJson(Map<String, dynamic>.from(item)))
                .where((t) => t.name != 'Blazing Strikers FC' && t.name != 'Thunder Smashers')
                .toList();
            teamsNotifier.value = remoteTeams;
            await prefs.setString(_storageKey, jsonEncode(remoteTeams.map((t) => t.toJson()).toList()));
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading teams: $e");
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teamList = teamsNotifier.value.map((t) => t.toJson()).toList();
      final str = jsonEncode(teamList);
      await prefs.setString(_storageKey, str);

      final phone = (prefs.getString('mobileNumber') ?? '').trim();
      if (phone.isNotEmpty) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/auth/user/teams');
        await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'teams': teamList}),
        ).timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint("Error saving teams: $e");
    }
  }

  Future<void> createTeam({
    required String name,
    required String sport,
    required String squadSize,
    List<PlayerItem>? members,
  }) async {
    final playerList = members ?? [];
    final newTeam = PlayerTeam(
      id: 'team_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      sport: sport,
      squadSize: squadSize,
      roleBadge: 'Captain',
      isCaptain: true,
      membersCount: playerList.isNotEmpty ? playerList.length : 1,
      winsCount: 0,
      rating: '5.0',
      dateText: 'Created Today',
      members: playerList,
    );

    teamsNotifier.value = [newTeam, ...teamsNotifier.value];
    await _saveToStorage();
  }

  Future<void> addMembersToTeam(String teamId, List<PlayerItem> newMembers) async {
    final list = List<PlayerTeam>.from(teamsNotifier.value);
    final idx = list.indexWhere((t) => t.id == teamId);
    if (idx != -1) {
      final team = list[idx];
      final currentMembers = List<PlayerItem>.from(team.members);
      for (final m in newMembers) {
        if (!currentMembers.any((existing) => existing.phone == m.phone || existing.name == m.name)) {
          currentMembers.add(m);
        }
      }
      list[idx] = PlayerTeam(
        id: team.id,
        name: team.name,
        sport: team.sport,
        roleBadge: team.roleBadge,
        isCaptain: team.isCaptain,
        squadSize: team.squadSize,
        membersCount: currentMembers.length,
        winsCount: team.winsCount,
        rating: team.rating,
        logoUrl: team.logoUrl,
        nextMatchText: team.nextMatchText,
        nextMatchTime: team.nextMatchTime,
        dateText: team.dateText,
        members: currentMembers,
      );
      teamsNotifier.value = list;
      await _saveToStorage();
    }
  }

  Future<void> updateTeamMembers(String teamId, List<PlayerItem> updatedMembers) async {
    final list = List<PlayerTeam>.from(teamsNotifier.value);
    final idx = list.indexWhere((t) => t.id == teamId);
    if (idx != -1) {
      final team = list[idx];
      list[idx] = PlayerTeam(
        id: team.id,
        name: team.name,
        sport: team.sport,
        roleBadge: team.roleBadge,
        isCaptain: team.isCaptain,
        squadSize: team.squadSize,
        membersCount: updatedMembers.length,
        winsCount: team.winsCount,
        rating: team.rating,
        logoUrl: team.logoUrl,
        nextMatchText: team.nextMatchText,
        nextMatchTime: team.nextMatchTime,
        dateText: team.dateText,
        members: updatedMembers,
      );
      teamsNotifier.value = list;
      await _saveToStorage();
    }
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

