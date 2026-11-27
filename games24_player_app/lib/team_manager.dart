import 'core/network/api_client.dart';
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
  final String teamCode;
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
    String? teamCode,
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
  })  : teamCode = teamCode ?? _generateCode(id, name),
        members = members ?? [];

  static String _generateCode(String id, String name) {
    final codeNum = (id.hashCode.abs() + name.hashCode.abs()) % 9000 + 1000;
    return 'TM-$codeNum';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sport': sport,
    'teamCode': teamCode,
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
    teamCode: json['teamCode']?.toString(),
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

class TeamInvitation {
  final String id;
  final String senderPhone;
  final String senderPlayerId;
  final String senderName;
  final String senderTeamId;
  final String senderTeamCode;
  final String senderTeamName;
  final String senderTeamSport;
  final String targetPlayerId;
  final String targetPhone;
  final String targetName;
  final String role;
  final String status;
  final String createdAt;

  TeamInvitation({
    required this.id,
    required this.senderPhone,
    required this.senderPlayerId,
    required this.senderName,
    required this.senderTeamId,
    required this.senderTeamCode,
    required this.senderTeamName,
    required this.senderTeamSport,
    required this.targetPlayerId,
    required this.targetPhone,
    required this.targetName,
    this.role = 'Player',
    this.status = 'pending',
    required this.createdAt,
  });

  factory TeamInvitation.fromJson(Map<String, dynamic> json) => TeamInvitation(
    id: json['id']?.toString() ?? '',
    senderPhone: json['senderPhone']?.toString() ?? '',
    senderPlayerId: json['senderPlayerId']?.toString() ?? 'PLY-0001',
    senderName: json['senderName']?.toString() ?? 'Team Captain',
    senderTeamId: json['senderTeamId']?.toString() ?? '',
    senderTeamCode: json['senderTeamCode']?.toString() ?? 'TM-1001',
    senderTeamName: json['senderTeamName']?.toString() ?? 'Squad',
    senderTeamSport: json['senderTeamSport']?.toString() ?? 'Football',
    targetPlayerId: json['targetPlayerId']?.toString() ?? '',
    targetPhone: json['targetPhone']?.toString() ?? '',
    targetName: json['targetName']?.toString() ?? 'Player',
    role: json['role']?.toString() ?? 'Player',
    status: json['status']?.toString() ?? 'pending',
    createdAt: json['createdAt']?.toString() ?? '',
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

  /// Clears the previous user's teams (logout / account switch) and reloads for the current user.
  Future<void> reset() async {
    teamsNotifier.value = [];
    await _loadFromStorage();
  }

  static Future<String> _myPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('mobileNumber') ?? '').trim();
  }

  /// Shows cached teams first, then replaces them with the server's list: teams this player
  /// captains plus teams they joined (members are read from the captain's single record).
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_storageKey);
      if (str != null && str.isNotEmpty) {
        final List list = jsonDecode(str);
        teamsNotifier.value = list
            .map((item) => PlayerTeam.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      await refreshFromServer();
    } catch (e) {
      debugPrint("Error loading teams: $e");
    }
  }

  Future<void> refreshFromServer() async {
    final phone = await _myPhone();
    if (phone.isEmpty) return;
    final res = await ApiClient.get('/auth/teams/my', query: {'phone': phone});
    if (!res.ok || res.map['teams'] is! List) return;
    final remote = (res.map['teams'] as List)
        .map((item) => PlayerTeam.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    teamsNotifier.value = remote;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(remote.map((t) => t.toJson()).toList()));
  }

  /// Saves teams this player captains to the server (which assigns unique join codes and keeps
  /// members who joined by code). Memberships are not saved here: they live with the captain.
  Future<String?> _saveToStorage({Map<String, List<String>> removedMembers = const {}}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teamList = teamsNotifier.value.map((t) => t.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(teamList));

      final phone = (prefs.getString('mobileNumber') ?? '').trim();
      if (phone.isEmpty) return 'Not logged in';
      final owned = teamsNotifier.value.where((t) => t.isCaptain).map((t) {
        final json = t.toJson();
        final removed = removedMembers[t.id];
        if (removed != null && removed.isNotEmpty) json['removedMemberPhones'] = removed;
        return json;
      }).toList();

      final res = await ApiClient.post('/auth/user/teams', body: {'phone': phone, 'teams': owned});
      if (!res.ok) return res.message;
      await refreshFromServer();
      return null;
    } catch (e) {
      debugPrint("Error saving teams: $e");
      return 'Could not save your team. Please try again.';
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
      final keep = updatedMembers.map((m) => m.phone.replaceAll(RegExp(r'\D'), '')).toSet();
      // Tell the server who was removed so it does not merge them back in.
      final removed = team.members
          .map((m) => m.phone.replaceAll(RegExp(r'\D'), ''))
          .where((p) => p.isNotEmpty && !keep.contains(p))
          .toList();
      list[idx] = PlayerTeam(
        id: team.id,
        name: team.name,
        sport: team.sport,
        teamCode: team.teamCode,
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
      await _saveToStorage(removedMembers: {teamId: removed});
    }
  }

  /// Joins a real team by its code (validated on the server). Returns null on success or an
  /// error message to show.
  Future<String?> joinTeamWithCode(String code) async {
    if (code.trim().isEmpty) return 'Enter a team code';
    final prefs = await SharedPreferences.getInstance();
    final res = await ApiClient.post('/auth/teams/join', body: {
      'code': code.trim().toUpperCase(),
      'phone': (prefs.getString('mobileNumber') ?? '').trim(),
      'name': (prefs.getString('fullName') ?? 'Player').trim(),
      'playerId': prefs.getString('playerId'),
    });
    if (!res.ok) return res.message;
    await refreshFromServer();
    return null;
  }

  /// The player's id from the server (PLY-0007). Cached per session; cleared on logout.
  static Future<String> getCurrentPlayerId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('playerId');
    if (stored != null && stored.isNotEmpty) return stored;
    final phone = (prefs.getString('mobileNumber') ?? '').trim();
    if (phone.isEmpty) return '';
    final res = await ApiClient.get('/auth/user-profile', query: {'phone': phone});
    final pid = res.ok ? (res.map['playerId']?.toString() ?? '') : '';
    // Only real ids are cached; the old "PLY-<last 4 digits>" fallback could collide with
    // another player's id, so nothing is stored when the server is unreachable.
    if (pid.isNotEmpty && res.map['id'] != null && res.map['id'] != 0) {
      await prefs.setString('playerId', pid);
    }
    return pid;
  }

  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/players/search?q=${Uri.encodeComponent(query.trim())}'),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("Error searching players: $e");
    }
    return [];
  }

  Future<bool> sendTeamInvitation({
    required String senderTeamId,
    required String senderTeamName,
    required String senderTeamSport,
    String? senderTeamCode,
    required String targetPlayerId,
    String? targetPhone,
    String? targetName,
    String role = 'Player',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final senderPhone = prefs.getString('mobileNumber') ?? '';
      final senderName = prefs.getString('fullName') ?? 'Team Captain';
      final myPlayerId = await getCurrentPlayerId();

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/team-invitations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderPhone': senderPhone,
          'senderPlayerId': myPlayerId,
          'senderName': senderName,
          'senderTeamId': senderTeamId,
          'senderTeamCode': senderTeamCode ?? senderTeamId,
          'senderTeamName': senderTeamName,
          'senderTeamSport': senderTeamSport,
          'targetPlayerId': targetPlayerId.trim().toUpperCase(),
          'targetPhone': targetPhone ?? '',
          'targetName': targetName ?? 'Player',
          'role': role,
        }),
      ).timeout(const Duration(seconds: 15));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("Error sending team invitation: $e");
      return false;
    }
  }

  Future<List<TeamInvitation>> fetchMyInvitations() async {
    try {
      final myPlayerId = await getCurrentPlayerId();
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('mobileNumber') ?? '';

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/team-invitations?identifier=${Uri.encodeComponent(myPlayerId)}'),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        final invites = list.map((item) => TeamInvitation.fromJson(Map<String, dynamic>.from(item))).toList();
        if (invites.isNotEmpty || phone.isEmpty) return invites;

        // Fallback check by phone
        final res2 = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/auth/team-invitations?identifier=${Uri.encodeComponent(phone)}'),
        ).timeout(const Duration(seconds: 15));
        if (res2.statusCode == 200) {
          final List list2 = jsonDecode(res2.body);
          return list2.map((item) => TeamInvitation.fromJson(Map<String, dynamic>.from(item))).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching invitations: $e");
    }
    return [];
  }

  Future<bool> respondToInvitation(String inviteId, bool accept, {TeamInvitation? invitation}) async {
    final prefs = await SharedPreferences.getInstance();
    final res = await ApiClient.post('/auth/team-invitations/$inviteId/respond', body: {
      'action': accept ? 'accept' : 'decline',
      'playerData': {
        'phone': prefs.getString('mobileNumber') ?? '',
        'name': prefs.getString('fullName') ?? 'Player',
      },
    });
    // On accept the server adds this player to the captain's team; reload so the team appears
    // with its real members (no separate local copy that would drift out of sync).
    if (res.ok && accept) await refreshFromServer();
    return res.ok;
  }

  /// Sends a team-vs-team match request; the opposing captain gets an in-app notification.
  Future<({bool ok, String message})> scheduleTeamMatch({
    required String challengerTeamId,
    required String challengerTeamName,
    required String opponentTeamId,
    required String opponentTeamName,
    required String sport,
    String? venueName,
    String? date,
    String? timeSlot,
  }) async {
    final res = await ApiClient.post('/auth/team-match/challenge', body: {
      'challengerTeamId': challengerTeamId,
      'challengerTeamName': challengerTeamName,
      'opponentTeamId': opponentTeamId,
      'opponentTeamName': opponentTeamName,
      'sport': sport,
      'venueName': venueName ?? 'Venue to be decided',
      'date': date ?? DateTime.now().toIso8601String().substring(0, 10),
      'timeSlot': timeSlot ?? '07:00 PM - 08:00 PM',
    });
    return (ok: res.ok, message: res.message);
  }

}

