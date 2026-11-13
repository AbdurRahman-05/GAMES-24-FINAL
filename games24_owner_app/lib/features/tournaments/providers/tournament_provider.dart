import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../api_config.dart';
import '../../admin/providers/admin_providers.dart';
import '../data/models/tournament_model.dart';

import '../services/realtime_score_sync_service.dart';
import '../services/advanced_fixture_engine.dart';

class AdminTournamentState {
  final List<TournamentModel> tournaments;
  final String activeFilter; // 'All', 'Live', 'Upcoming', 'Completed'

  AdminTournamentState({
    required this.tournaments,
    this.activeFilter = 'All',
  });

  int get totalTournaments => tournaments.length;
  int get upcomingCount => tournaments.where((t) => t.status == 'Upcoming').length;
  int get liveCount => tournaments.where((t) => t.status == 'Live').length;
  int get completedCount => tournaments.where((t) => t.status == 'Completed').length;

  int get totalParticipants => tournaments.fold(0, (sum, t) => sum + (t.registeredTeamsCount * t.playersPerTeam));
  double get totalRevenue => tournaments.fold(0.0, (sum, t) => sum + t.totalRevenue);
  int get pendingApprovals => tournaments.where((t) => t.status == 'Upcoming' && t.registeredTeamsCount < t.maxTeams).length;
  int get availableSlots => tournaments.fold(0, (sum, t) => sum + (t.maxTeams - t.registeredTeamsCount));

  List<TournamentModel> get filteredTournaments {
    if (activeFilter == 'All') return tournaments;
    return tournaments.where((t) => t.status == activeFilter).toList();
  }

  AdminTournamentState copyWith({
    List<TournamentModel>? tournaments,
    String? activeFilter,
  }) {
    return AdminTournamentState(
      tournaments: tournaments ?? this.tournaments,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

class AdminTournamentNotifier extends Notifier<AdminTournamentState> {
  @override
  AdminTournamentState build() {
    Future.microtask(() => fetchTournamentsFromBackend());
    return AdminTournamentState(
      tournaments: const [],
    );
  }

  Future<void> fetchTournamentsFromBackend({
    int? turfId,
    String? phone,
    String? venue,
  }) async {
    try {
      final profile = ref.read(turfProfileProvider);
      final targetTurfId = turfId ?? (profile.turfId > 0 ? profile.turfId : null);
      final targetPhone = (phone ?? profile.ownerPhone).trim();
      final targetVenue = (venue ?? profile.venueName).trim();

      final List<String> queryParts = ['ownerOnly=true'];
      if (targetTurfId != null) queryParts.add('turfId=$targetTurfId');
      if (targetPhone.isNotEmpty) queryParts.add('phone=${Uri.encodeComponent(targetPhone)}');
      if (targetVenue.isNotEmpty) queryParts.add('venue=${Uri.encodeComponent(targetVenue)}');

      final url = '${ApiConfig.baseUrl}/turfs/tournaments?${queryParts.join('&')}';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(res.body);
        if (decoded is List) {
          final items = decoded
              .map((item) => TournamentModel.fromJson(Map<String, dynamic>.from(item)))
              .where((t) {
                // Owner-only filter: only tournaments created by / for this turf owner
                if (targetTurfId != null && t.verifiedAdminId != null) {
                  if (t.verifiedAdminId == targetTurfId) return true;
                }
                final cleanTargetPhone = targetPhone.replaceAll(RegExp(r'[^0-9]'), '');
                final cleanTournPhone = t.phone.replaceAll(RegExp(r'[^0-9]'), '');
                if (cleanTargetPhone.isNotEmpty && cleanTournPhone.isNotEmpty) {
                  final targetEnd = cleanTargetPhone.length >= 10 ? cleanTargetPhone.substring(cleanTargetPhone.length - 10) : cleanTargetPhone;
                  final tournEnd = cleanTournPhone.length >= 10 ? cleanTournPhone.substring(cleanTournPhone.length - 10) : cleanTournPhone;
                  if (targetEnd == tournEnd) return true;
                }
                if (targetVenue.isNotEmpty) {
                  if (t.courtAllocation.toLowerCase().contains(targetVenue.toLowerCase()) ||
                      targetVenue.toLowerCase().contains(t.courtAllocation.toLowerCase())) {
                    return true;
                  }
                }
                return targetTurfId == null && targetPhone.isEmpty && targetVenue.isEmpty;
              })
              .toList();
          state = state.copyWith(tournaments: items);
          return;
        }
      }
    } catch (e) {
      // Silently fall back to cached/default
    }
  }

  void filterStatus(String status) {
    state = state.copyWith(activeFilter: status);
  }

  void addTournament(TournamentModel tournament) {
    final updatedList = [tournament, ...state.tournaments];
    state = state.copyWith(tournaments: updatedList);
  }

  void updateLiveScore(String tournamentId, String newScore, String commentary) {
    final updatedList = state.tournaments.map((t) {
      if (t.id == tournamentId) {
        return t.copyWith(
          liveScore: newScore,
          liveCommentary: commentary,
          status: 'Live',
        );
      }
      return t;
    }).toList();
    state = state.copyWith(tournaments: updatedList);

    // Emit Real-Time Score Broadcast Event
    RealtimeScoreSyncService.instance.emitEvent(
      MatchScoreSyncEvent(
        tournamentId: tournamentId,
        fixtureId: '',
        liveScore: newScore,
        liveCommentary: commentary,
        eventType: ScoreSyncEventType.liveCommentary,
      ),
    );
  }

  void generateAdvancedFixtures(String tournamentId, String format) {
    final updatedList = state.tournaments.map((t) {
      if (t.id != tournamentId) return t;

      List<TeamRegistrationModel> registeredList = List.from(t.registeredTeams);
      if (registeredList.isEmpty) {
        registeredList = const [
          TeamRegistrationModel(id: 'reg_1', teamName: 'Super Strikers', captainName: 'Rajesh', captainPhone: '9876543210', captainEmail: 'raj@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-01', logoUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=100&q=80'),
          TeamRegistrationModel(id: 'reg_2', teamName: 'Royal Kings', captainName: 'Karthik', captainPhone: '9876543211', captainEmail: 'karthik@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-02', logoUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=100&q=80'),
          TeamRegistrationModel(id: 'reg_3', teamName: 'Madurai Panthers', captainName: 'Suresh', captainPhone: '9876543212', captainEmail: 'suresh@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-03', logoUrl: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=100&q=80'),
          TeamRegistrationModel(id: 'reg_4', teamName: 'KK Nagar XI', captainName: 'Vijay', captainPhone: '9876543213', captainEmail: 'vijay@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-04', logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=100&q=80'),
          TeamRegistrationModel(id: 'reg_5', teamName: 'Anna Nagar Titans', captainName: 'Anand', captainPhone: '9876543214', captainEmail: 'anand@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-04', logoUrl: 'https://images.unsplash.com/photo-1518091043644-c1d4457512c6?auto=format&fit=crop&w=100&q=80'),
          TeamRegistrationModel(id: 'reg_6', teamName: 'Chola Warriors', captainName: 'Mano', captainPhone: '9876543215', captainEmail: 'mano@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-05', logoUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=100&q=80'),
        ];
      }

      List<TournamentFixture> generated = [];

      if (format == 'Seeded Knockout') {
        generated = AdvancedFixtureEngine.generateSeededKnockoutFixtures(t, registeredList);
      } else if (format == 'Double Elimination') {
        generated = AdvancedFixtureEngine.generateDoubleEliminationFixtures(t, registeredList);
      } else if (format == 'Group Stage + Knockout') {
        generated = AdvancedFixtureEngine.generateGroupStageAndKnockoutFixtures(t, registeredList);
      } else {
        return t;
      }

      RealtimeScoreSyncService.instance.emitEvent(
        MatchScoreSyncEvent(
          tournamentId: tournamentId,
          fixtureId: '',
          stage: format,
          eventType: ScoreSyncEventType.fixtureGenerated,
        ),
      );

      return t.copyWith(
        registeredTeams: registeredList,
        registeredTeamsCount: registeredList.length,
        fixtures: generated,
        tournamentType: format,
      );
    }).toList();

    state = state.copyWith(tournaments: updatedList);
  }

  void generateFixtures(String tournamentId) {
    final updatedList = state.tournaments.map((t) {
      if (t.id == tournamentId) {
        // Collect team models from registrations or provide default mock registered teams
        List<TeamRegistrationModel> registeredList = List.from(t.registeredTeams);
        if (registeredList.isEmpty) {
          registeredList = const [
            TeamRegistrationModel(id: 'reg_1', teamName: 'Super Strikers', captainName: 'Rajesh', captainPhone: '9876543210', captainEmail: 'raj@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-01', logoUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=100&q=80'),
            TeamRegistrationModel(id: 'reg_2', teamName: 'Royal Kings', captainName: 'Karthik', captainPhone: '9876543211', captainEmail: 'karthik@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-02', logoUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=100&q=80'),
            TeamRegistrationModel(id: 'reg_3', teamName: 'Madurai Panthers', captainName: 'Suresh', captainPhone: '9876543212', captainEmail: 'suresh@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-03', logoUrl: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=100&q=80'),
            TeamRegistrationModel(id: 'reg_4', teamName: 'KK Nagar XI', captainName: 'Vijay', captainPhone: '9876543213', captainEmail: 'vijay@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-04', logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=100&q=80'),
            TeamRegistrationModel(id: 'reg_5', teamName: 'Anna Nagar Titans', captainName: 'Anand', captainPhone: '9876543214', captainEmail: 'anand@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-04', logoUrl: 'https://images.unsplash.com/photo-1518091043644-c1d4457512c6?auto=format&fit=crop&w=100&q=80'),
          ];
        }

        List<TournamentFixture> generatedFixtures = [];
        List<LeagueStandingRow> standings = [];
        final isLeague = t.tournamentType == 'League' || t.tournamentType == 'Round Robin';

        if (isLeague) {
          standings = registeredList.map((tr) => LeagueStandingRow(teamName: tr.teamName)).toList();
          int matchIndex = 1;
          for (int i = 0; i < registeredList.length; i++) {
            for (int j = i + 1; j < registeredList.length; j++) {
              int startHour = 9 + ((matchIndex - 1) % 10);
              String timeStr = "${startHour.toString().padLeft(2, '0')}:00 ${startHour >= 12 ? 'PM' : 'AM'}";

              generatedFixtures.add(
                TournamentFixture(
                  id: 'fix_${t.id}_rr_$matchIndex',
                  matchNumber: 'Match #$matchIndex',
                  teamA: registeredList[i].teamName,
                  teamB: registeredList[j].teamName,
                  logoA: registeredList[i].logoUrl,
                  logoB: registeredList[j].logoUrl,
                  courtName: t.courtAllocation,
                  timeSlot: timeStr,
                  stage: 'Group Stage',
                  status: 'Scheduled',
                ),
              );
              matchIndex++;
            }
          }
        } else {
          // Knockout Format with Dynamic Bye Assignment for 4, 8, 16, 32, 64 teams
          List<String> teamNames = registeredList.map((tr) => tr.teamName).toList();
          List<String> teamLogos = registeredList.map((tr) => tr.logoUrl).toList();

          int count = teamNames.length;
          int targetSize = 4;
          if (count > 4) targetSize = 8;
          if (count > 8) targetSize = 16;
          if (count > 16) targetSize = 32;

          // Fill Bye slots up to targetSize
          while (teamNames.length < targetSize) {
            teamNames.add('BYE');
            teamLogos.add('https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=100&q=80');
          }

          if (targetSize == 4) {
            final finalId = 'fix_${t.id}_final';
            generatedFixtures = [
              TournamentFixture(
                id: 'fix_${t.id}_sf1',
                matchNumber: 'Semi Final #1',
                teamA: teamNames[0],
                teamB: teamNames[1],
                logoA: teamLogos[0],
                logoB: teamLogos[1],
                courtName: t.courtAllocation,
                timeSlot: '09:00 AM - 10:00 AM',
                stage: 'Semi Final',
                nextMatchId: finalId,
                nextMatchSlot: 'teamA',
                winnerTeam: teamNames[1] == 'BYE' ? teamNames[0] : '',
                status: teamNames[1] == 'BYE' ? 'Completed' : 'Scheduled',
              ),
              TournamentFixture(
                id: 'fix_${t.id}_sf2',
                matchNumber: 'Semi Final #2',
                teamA: teamNames[2],
                teamB: teamNames[3],
                logoA: teamLogos[2],
                logoB: teamLogos[3],
                courtName: t.courtAllocation,
                timeSlot: '10:15 AM - 11:15 AM',
                stage: 'Semi Final',
                nextMatchId: finalId,
                nextMatchSlot: 'teamB',
                winnerTeam: teamNames[3] == 'BYE' ? teamNames[2] : '',
                status: teamNames[3] == 'BYE' ? 'Completed' : 'Scheduled',
              ),
              TournamentFixture(
                id: finalId,
                matchNumber: 'GRAND FINAL 🏆',
                teamA: teamNames[1] == 'BYE' ? teamNames[0] : 'TBD (Winner SF1)',
                teamB: teamNames[3] == 'BYE' ? teamNames[2] : 'TBD (Winner SF2)',
                courtName: t.courtAllocation,
                timeSlot: '04:00 PM - 05:30 PM',
                stage: 'Final',
              ),
            ];
          } else {
            // 8 Teams Tree
            final sf1Id = 'fix_${t.id}_sf1';
            final sf2Id = 'fix_${t.id}_sf2';
            final finalId = 'fix_${t.id}_final';

            final isBye1 = teamNames[1] == 'BYE';
            final isBye2 = teamNames[3] == 'BYE';
            final isBye3 = teamNames[5] == 'BYE';
            final isBye4 = teamNames[7] == 'BYE';

            generatedFixtures = [
              TournamentFixture(
                id: 'fix_${t.id}_qf1',
                matchNumber: 'Quarter Final #1',
                teamA: teamNames[0],
                teamB: teamNames[1],
                logoA: teamLogos[0],
                logoB: teamLogos[1],
                courtName: t.courtAllocation,
                timeSlot: '09:00 AM - 10:00 AM',
                stage: 'Quarter Final',
                nextMatchId: sf1Id,
                nextMatchSlot: 'teamA',
                winnerTeam: isBye1 ? teamNames[0] : '',
                status: isBye1 ? 'Completed' : 'Scheduled',
              ),
              TournamentFixture(
                id: 'fix_${t.id}_qf2',
                matchNumber: 'Quarter Final #2',
                teamA: teamNames[2],
                teamB: teamNames[3],
                logoA: teamLogos[2],
                logoB: teamLogos[3],
                courtName: t.courtAllocation,
                timeSlot: '10:15 AM - 11:15 AM',
                stage: 'Quarter Final',
                nextMatchId: sf1Id,
                nextMatchSlot: 'teamB',
                winnerTeam: isBye2 ? teamNames[2] : '',
                status: isBye2 ? 'Completed' : 'Scheduled',
              ),
              TournamentFixture(
                id: 'fix_${t.id}_qf3',
                matchNumber: 'Quarter Final #3',
                teamA: teamNames[4],
                teamB: teamNames[5],
                logoA: teamLogos[4],
                logoB: teamLogos[5],
                courtName: t.courtAllocation,
                timeSlot: '11:30 AM - 12:30 PM',
                stage: 'Quarter Final',
                nextMatchId: sf2Id,
                nextMatchSlot: 'teamA',
                winnerTeam: isBye3 ? teamNames[4] : '',
                status: isBye3 ? 'Completed' : 'Scheduled',
              ),
              TournamentFixture(
                id: 'fix_${t.id}_qf4',
                matchNumber: 'Quarter Final #4',
                teamA: teamNames[6],
                teamB: teamNames[7],
                logoA: teamLogos[6],
                logoB: teamLogos[7],
                courtName: t.courtAllocation,
                timeSlot: '01:30 PM - 02:30 PM',
                stage: 'Quarter Final',
                nextMatchId: sf2Id,
                nextMatchSlot: 'teamB',
                winnerTeam: isBye4 ? teamNames[6] : '',
                status: isBye4 ? 'Completed' : 'Scheduled',
              ),
              TournamentFixture(
                id: sf1Id,
                matchNumber: 'Semi Final #1',
                teamA: isBye1 ? teamNames[0] : 'TBD (Winner QF1)',
                teamB: isBye2 ? teamNames[2] : 'TBD (Winner QF2)',
                courtName: t.courtAllocation,
                timeSlot: '03:30 PM - 04:30 PM',
                stage: 'Semi Final',
                nextMatchId: finalId,
                nextMatchSlot: 'teamA',
              ),
              TournamentFixture(
                id: sf2Id,
                matchNumber: 'Semi Final #2',
                teamA: isBye3 ? teamNames[4] : 'TBD (Winner QF3)',
                teamB: isBye4 ? teamNames[6] : 'TBD (Winner QF4)',
                courtName: t.courtAllocation,
                timeSlot: '04:45 PM - 05:45 PM',
                stage: 'Semi Final',
                nextMatchId: finalId,
                nextMatchSlot: 'teamB',
              ),
              TournamentFixture(
                id: finalId,
                matchNumber: 'GRAND FINAL 🏆',
                teamA: 'TBD (Winner SF1)',
                teamB: 'TBD (Winner SF2)',
                courtName: t.courtAllocation,
                timeSlot: '07:00 PM - 08:30 PM',
                stage: 'Final',
              ),
            ];
          }
        }

        return t.copyWith(
          registeredTeams: registeredList,
          registeredTeamsCount: registeredList.length,
          fixtures: generatedFixtures,
          standings: standings,
        );
      }
      return t;
    }).toList();
    state = state.copyWith(tournaments: updatedList);
  }

  void addMatchEvent(String tournamentId, String fixtureId, MatchEvent event) {
    final updatedList = state.tournaments.map((t) {
      if (t.id != tournamentId) return t;

      List<TournamentFixture> updatedFixtures = t.fixtures.map((fix) {
        if (fix.id == fixtureId) {
          int newScoreA = fix.scoreA;
          int newScoreB = fix.scoreB;
          if (event.type == 'Goal') {
            if (event.teamName == fix.teamA) newScoreA++;
            if (event.teamName == fix.teamB) newScoreB++;
          }
          final newEvents = [...fix.events, event];
          return fix.copyWith(
            scoreA: newScoreA,
            scoreB: newScoreB,
            events: newEvents,
            status: 'Live',
          );
        }
        return fix;
      }).toList();

      final liveMsg = '${event.teamName}: ${event.type} by ${event.playerName} (${event.minute}\')';

      RealtimeScoreSyncService.instance.emitEvent(
        MatchScoreSyncEvent(
          tournamentId: tournamentId,
          fixtureId: fixtureId,
          liveScore: liveMsg,
          liveCommentary: liveMsg,
          eventType: ScoreSyncEventType.scoreUpdate,
        ),
      );

      return t.copyWith(
        fixtures: updatedFixtures,
        liveScore: liveMsg,
        status: 'Live',
      );
    }).toList();
    state = state.copyWith(tournaments: updatedList);
  }

  void togglePauseMatch(String tournamentId, String fixtureId) {
    final updatedList = state.tournaments.map((t) {
      if (t.id != tournamentId) return t;
      List<TournamentFixture> updatedFixtures = t.fixtures.map((fix) {
        if (fix.id == fixtureId) {
          return fix.copyWith(isPaused: !fix.isPaused);
        }
        return fix;
      }).toList();
      return t.copyWith(fixtures: updatedFixtures);
    }).toList();
    state = state.copyWith(tournaments: updatedList);
  }

  void finishMatchAndAdvanceWinner(
    String tournamentId,
    String fixtureId,
    int scoreA,
    int scoreB,
    String winnerTeam, {
    int wicketsA = 0,
    int wicketsB = 0,
    String oversA = '',
    String oversB = '',
  }) {
    final updatedList = state.tournaments.map((t) {
      if (t.id != tournamentId) return t;

      TournamentFixture? targetFixture;
      for (final fix in t.fixtures) {
        if (fix.id == fixtureId) {
          targetFixture = fix;
          break;
        }
      }
      if (targetFixture == null) return t;

      final winnerLogo = winnerTeam == targetFixture.teamA ? targetFixture.logoA : targetFixture.logoB;

      final updatedFixture = targetFixture.copyWith(
        scoreA: scoreA,
        scoreB: scoreB,
        wicketsA: wicketsA,
        wicketsB: wicketsB,
        oversA: oversA,
        oversB: oversB,
        winnerTeam: winnerTeam,
        winnerLogo: winnerLogo,
        status: 'Completed',
      );

      List<TournamentFixture> updatedFixtures = t.fixtures.map((fix) {
        if (fix.id == fixtureId) return updatedFixture;
        return fix;
      }).toList();

      // Automatic Winner Progression into nextMatchId
      if (winnerTeam.isNotEmpty && targetFixture.nextMatchId != null && targetFixture.nextMatchSlot != null) {
        final nextId = targetFixture.nextMatchId!;
        final nextSlot = targetFixture.nextMatchSlot!;

        updatedFixtures = updatedFixtures.map((fix) {
          if (fix.id == nextId) {
            if (nextSlot == 'teamA') {
              return fix.copyWith(teamA: winnerTeam, logoA: winnerLogo);
            } else if (nextSlot == 'teamB') {
              return fix.copyWith(teamB: winnerTeam, logoB: winnerLogo);
            }
          }
          return fix;
        }).toList();
      }

      // If Grand Final match completed -> Declare Champion!
      String newChampionTeam = t.championTeam;
      String newChampionLogo = t.championLogo;
      String newTournamentStatus = t.status;

      if (targetFixture.stage == 'Final' && winnerTeam.isNotEmpty) {
        newChampionTeam = winnerTeam;
        newChampionLogo = winnerLogo;
        newTournamentStatus = 'Completed';
      }

      final summaryMsg = newChampionTeam.isNotEmpty
          ? '🏆 CHAMPION DECLARED: $newChampionTeam'
          : '${targetFixture.matchNumber}: $winnerTeam WON ($scoreA-$scoreB)';

      RealtimeScoreSyncService.instance.emitEvent(
        MatchScoreSyncEvent(
          tournamentId: tournamentId,
          fixtureId: fixtureId,
          scoreA: scoreA,
          scoreB: scoreB,
          winnerTeam: winnerTeam,
          liveScore: summaryMsg,
          eventType: winnerTeam.isNotEmpty ? ScoreSyncEventType.winnerAdvanced : ScoreSyncEventType.matchCompleted,
        ),
      );

      return t.copyWith(
        fixtures: updatedFixtures,
        championTeam: newChampionTeam,
        championLogo: newChampionLogo,
        status: newTournamentStatus,
        liveScore: summaryMsg,
      );
    }).toList();

    state = state.copyWith(tournaments: updatedList);
  }

  void updateMatchResult(String tournamentId, String fixtureId, int scoreA, int scoreB, String winnerTeam) {
    finishMatchAndAdvanceWinner(tournamentId, fixtureId, scoreA, scoreB, winnerTeam);
  }

  void registerTeam(String tournamentId, TeamRegistrationModel team) {
    final updatedList = state.tournaments.map((t) {
      if (t.id == tournamentId) {
        final newTeams = [...t.registeredTeams, team];
        final newCount = t.registeredTeamsCount + 1;
        final newRevenue = t.totalRevenue + t.teamEntryFee;
        return t.copyWith(
          registeredTeams: newTeams,
          registeredTeamsCount: newCount,
          totalRevenue: newRevenue,
        );
      }
      return t;
    }).toList();
    state = state.copyWith(tournaments: updatedList);
  }

  void deleteTournament(String tournamentId) {
    final updatedList = state.tournaments.where((t) => t.id != tournamentId).toList();
    state = state.copyWith(tournaments: updatedList);
  }
}

final adminTournamentProvider =
    NotifierProvider<AdminTournamentNotifier, AdminTournamentState>(
  () => AdminTournamentNotifier(),
);
