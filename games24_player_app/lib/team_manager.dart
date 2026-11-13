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
            .timeout(const Duration(seconds: 15));
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
        ).timeout(const Duration(seconds: 15));
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

  static Future<String> getCurrentPlayerId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('playerId');
    if (stored != null && stored.isNotEmpty) return stored;
    final phone = (prefs.getString('mobileNumber') ?? '').trim();
    if (phone.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/auth/user-profile?phone=${Uri.encodeComponent(phone)}')).timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['playerId'] != null && data['playerId'].toString().isNotEmpty) {
            final pid = data['playerId'].toString();
            await prefs.setString('playerId', pid);
            return pid;
          }
        }
      } catch (_) {}
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      final pid = 'PLY-${digits.length >= 4 ? digits.substring(digits.length - 4) : '1001'}';
      await prefs.setString('playerId', pid);
      return pid;
    }
    return 'PLY-1001';
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final myPhone = prefs.getString('mobileNumber') ?? '';
      final myName = prefs.getString('fullName') ?? 'Player';

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/team-invitations/$inviteId/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': accept ? 'accept' : 'decline',
          'playerData': {
            'phone': myPhone,
            'name': myName,
          },
        }),
      ).timeout(const Duration(seconds: 15));

      if (accept && invitation != null) {
        final joinedTeam = PlayerTeam(
          id: invitation.senderTeamId,
          name: invitation.senderTeamName,
          sport: invitation.senderTeamSport,
          teamCode: invitation.senderTeamCode,
          roleBadge: invitation.role,
          isCaptain: false,
          squadSize: 'Squad',
          membersCount: 2,
          dateText: 'Joined via Invite',
        );

        final existing = teamsNotifier.value.indexWhere((t) => t.id == joinedTeam.id);
        if (existing == -1) {
          teamsNotifier.value = [joinedTeam, ...teamsNotifier.value];
          await _saveToStorage();
        }
      }

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("Error responding to invitation: $e");
      return false;
    }
  }

  Future<bool> scheduleTeamMatch({
    required String challengerTeamId,
    required String challengerTeamName,
    required String opponentTeamId,
    required String opponentTeamName,
    required String sport,
    String? venueName,
    String? date,
    String? timeSlot,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/team-match/challenge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'challengerTeamId': challengerTeamId,
          'challengerTeamName': challengerTeamName,
          'opponentTeamId': opponentTeamId,
          'opponentTeamName': opponentTeamName,
          'sport': sport,
          'venueName': venueName ?? 'Downtown Sports Arena',
          'date': date ?? DateTime.now().toIso8601String().substring(0, 10),
          'timeSlot': timeSlot ?? '07:00 PM - 08:00 PM',
        }),
      ).timeout(const Duration(seconds: 15));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("Error scheduling team match: $e");
      return false;
    }
  }
}

