import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ScoreSyncEventType {
  scoreUpdate,
  liveCommentary,
  matchCompleted,
  winnerAdvanced,
  fixtureGenerated,
}

class MatchScoreSyncEvent {
  final String tournamentId;
  final String fixtureId;
  final String teamA;
  final String teamB;
  final int scoreA;
  final int scoreB;
  final int wicketsA;
  final int wicketsB;
  final String oversA;
  final String oversB;
  final String liveScore;
  final String liveCommentary;
  final String winnerTeam;
  final String stage;
  final ScoreSyncEventType eventType;
  final DateTime timestamp;

  MatchScoreSyncEvent({
    required this.tournamentId,
    required this.fixtureId,
    this.teamA = '',
    this.teamB = '',
    this.scoreA = 0,
    this.scoreB = 0,
    this.wicketsA = 0,
    this.wicketsB = 0,
    this.oversA = '',
    this.oversB = '',
    this.liveScore = '',
    this.liveCommentary = '',
    this.winnerTeam = '',
    this.stage = '',
    required this.eventType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class RealtimeScoreSyncService {
  RealtimeScoreSyncService._privateConstructor();
  static final RealtimeScoreSyncService instance = RealtimeScoreSyncService._privateConstructor();

  final _controller = StreamController<MatchScoreSyncEvent>.broadcast();

  Stream<MatchScoreSyncEvent> get scoreStream => _controller.stream;

  void emitEvent(MatchScoreSyncEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}

final realtimeScoreStreamProvider = StreamProvider<MatchScoreSyncEvent>((ref) {
  return RealtimeScoreSyncService.instance.scoreStream;
});
