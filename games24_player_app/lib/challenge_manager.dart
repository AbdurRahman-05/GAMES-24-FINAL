import 'package:flutter/material.dart';

class JoinRequest {
  final String id;
  final String teamName;
  final String contactDetails;

  JoinRequest({
    required this.id,
    required this.teamName,
    required this.contactDetails,
  });
}

class Challenge {
  final String id;
  final String turfName;
  final String date;
  final String time;
  final String sport;
  final String challengerName;
  final String challengerTeamInitials;
  final Color challengerColor;
  
  bool isCreator; 
  bool isJoined;
  String? opponentName;
  List<JoinRequest> joinRequests;
  bool userHasRequested;

  Challenge({
    required this.id,
    required this.turfName,
    required this.date,
    required this.time,
    required this.sport,
    required this.challengerName,
    required this.challengerTeamInitials,
    required this.challengerColor,
    this.isCreator = false,
    this.isJoined = false,
    this.opponentName,
    this.joinRequests = const [],
    this.userHasRequested = false,
  });
}

class ChallengeManager {
  static final ChallengeManager _instance = ChallengeManager._internal();
  factory ChallengeManager() => _instance;
  ChallengeManager._internal();

  final ValueNotifier<List<Challenge>> challengesNotifier = ValueNotifier([
    Challenge(
      id: '1',
      turfName: 'Green Valley Arena',
      date: 'Today',
      time: '06:00 PM',
      sport: 'Football',
      challengerName: 'Eagles FC',
      challengerTeamInitials: 'EA',
      challengerColor: Colors.blue.shade800,
      isCreator: false,
    ),
  ]);

  void addChallenge(Challenge challenge) {
    challengesNotifier.value = List.from(challengesNotifier.value)..add(challenge);
  }

  void requestToJoin(String id, String teamName, String contactDetails) {
    final list = List<Challenge>.from(challengesNotifier.value);
    final index = list.indexWhere((c) => c.id == id);
    if (index != -1) {
      final req = JoinRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        teamName: teamName,
        contactDetails: contactDetails,
      );
      final updatedRequests = List<JoinRequest>.from(list[index].joinRequests)..add(req);
      
      list[index] = Challenge(
        id: list[index].id,
        turfName: list[index].turfName,
        date: list[index].date,
        time: list[index].time,
        sport: list[index].sport,
        challengerName: list[index].challengerName,
        challengerTeamInitials: list[index].challengerTeamInitials,
        challengerColor: list[index].challengerColor,
        isCreator: list[index].isCreator,
        isJoined: list[index].isJoined,
        opponentName: list[index].opponentName,
        joinRequests: updatedRequests,
        userHasRequested: true,
      );
      
      challengesNotifier.value = list;
    }
  }

  void acceptRequest(String challengeId, JoinRequest request) {
    final list = List<Challenge>.from(challengesNotifier.value);
    final index = list.indexWhere((c) => c.id == challengeId);
    if (index != -1) {
      list[index] = Challenge(
        id: list[index].id,
        turfName: list[index].turfName,
        date: list[index].date,
        time: list[index].time,
        sport: list[index].sport,
        challengerName: list[index].challengerName,
        challengerTeamInitials: list[index].challengerTeamInitials,
        challengerColor: list[index].challengerColor,
        isCreator: list[index].isCreator,
        isJoined: true,
        opponentName: request.teamName,
        joinRequests: [],
        userHasRequested: list[index].userHasRequested,
      );
      challengesNotifier.value = list;
    }
  }
  
  void rejectRequest(String challengeId, String requestId) {
    final list = List<Challenge>.from(challengesNotifier.value);
    final index = list.indexWhere((c) => c.id == challengeId);
    if (index != -1) {
      final updatedRequests = list[index].joinRequests.where((r) => r.id != requestId).toList();
      list[index] = Challenge(
        id: list[index].id,
        turfName: list[index].turfName,
        date: list[index].date,
        time: list[index].time,
        sport: list[index].sport,
        challengerName: list[index].challengerName,
        challengerTeamInitials: list[index].challengerTeamInitials,
        challengerColor: list[index].challengerColor,
        isCreator: list[index].isCreator,
        isJoined: list[index].isJoined,
        opponentName: list[index].opponentName,
        joinRequests: updatedRequests,
        userHasRequested: list[index].userHasRequested,
      );
      challengesNotifier.value = list;
    }
  }
}
