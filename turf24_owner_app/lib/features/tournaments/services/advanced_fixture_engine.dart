import '../data/models/tournament_model.dart';

class AdvancedFixtureEngine {
  AdvancedFixtureEngine._();

  /// 1. SEEDED KNOCKOUT FIXTURES (Top Seed Protection)
  static List<TournamentFixture> generateSeededKnockoutFixtures(
    TournamentModel t,
    List<TeamRegistrationModel> registeredList,
  ) {
    if (registeredList.isEmpty) return const [];

    List<String> teamNames = registeredList.map((tr) => tr.teamName).toList();
    List<String> teamLogos = registeredList.map((tr) => tr.logoUrl).toList();

    int count = teamNames.length;
    int targetSize = 4;
    if (count > 4) targetSize = 8;
    if (count > 8) targetSize = 16;

    // Fill BYE slots if needed
    while (teamNames.length < targetSize) {
      teamNames.add('BYE');
      teamLogos.add('https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=100&q=80');
    }

    // Seeding pair indices for Top Seed Protection
    List<int> seededOrder = _calculateSeededPairs(targetSize);

    List<String> seededNames = [];
    List<String> seededLogos = [];

    for (int idx in seededOrder) {
      final seedNum = idx + 1;
      final name = teamNames[idx];
      if (name == 'BYE') {
        seededNames.add('BYE');
      } else {
        seededNames.add('[#$seedNum] $name');
      }
      seededLogos.add(teamLogos[idx]);
    }

    if (targetSize == 4) {
      final finalId = 'fix_${t.id}_final';
      final isBye1 = seededNames[1] == 'BYE';
      final isBye2 = seededNames[3] == 'BYE';

      return [
        TournamentFixture(
          id: 'fix_${t.id}_sf1',
          matchNumber: 'Semi Final #1 (Seeded)',
          teamA: seededNames[0],
          teamB: seededNames[1],
          logoA: seededLogos[0],
          logoB: seededLogos[1],
          courtName: t.courtAllocation,
          timeSlot: '09:00 AM - 10:00 AM',
          stage: 'Semi Final',
          nextMatchId: finalId,
          nextMatchSlot: 'teamA',
          winnerTeam: isBye1 ? seededNames[0] : '',
          status: isBye1 ? 'Completed' : 'Scheduled',
        ),
        TournamentFixture(
          id: 'fix_${t.id}_sf2',
          matchNumber: 'Semi Final #2 (Seeded)',
          teamA: seededNames[2],
          teamB: seededNames[3],
          logoA: seededLogos[2],
          logoB: seededLogos[3],
          courtName: t.courtAllocation,
          timeSlot: '10:15 AM - 11:15 AM',
          stage: 'Semi Final',
          nextMatchId: finalId,
          nextMatchSlot: 'teamB',
          winnerTeam: isBye2 ? seededNames[2] : '',
          status: isBye2 ? 'Completed' : 'Scheduled',
        ),
        TournamentFixture(
          id: finalId,
          matchNumber: 'GRAND FINAL 🏆',
          teamA: isBye1 ? seededNames[0] : 'TBD (Winner SF1)',
          teamB: isBye2 ? seededNames[2] : 'TBD (Winner SF2)',
          courtName: t.courtAllocation,
          timeSlot: '04:00 PM - 05:30 PM',
          stage: 'Final',
        ),
      ];
    } else {
      // 8 Teams Seeded
      final sf1Id = 'fix_${t.id}_sf1';
      final sf2Id = 'fix_${t.id}_sf2';
      final finalId = 'fix_${t.id}_final';

      final isBye1 = seededNames[1] == 'BYE';
      final isBye2 = seededNames[3] == 'BYE';
      final isBye3 = seededNames[5] == 'BYE';
      final isBye4 = seededNames[7] == 'BYE';

      return [
        TournamentFixture(
          id: 'fix_${t.id}_qf1',
          matchNumber: 'Quarter Final #1 (Seed 1 vs 8)',
          teamA: seededNames[0],
          teamB: seededNames[1],
          logoA: seededLogos[0],
          logoB: seededLogos[1],
          courtName: t.courtAllocation,
          timeSlot: '09:00 AM - 10:00 AM',
          stage: 'Quarter Final',
          nextMatchId: sf1Id,
          nextMatchSlot: 'teamA',
          winnerTeam: isBye1 ? seededNames[0] : '',
          status: isBye1 ? 'Completed' : 'Scheduled',
        ),
        TournamentFixture(
          id: 'fix_${t.id}_qf2',
          matchNumber: 'Quarter Final #2 (Seed 4 vs 5)',
          teamA: seededNames[2],
          teamB: seededNames[3],
          logoA: seededLogos[2],
          logoB: seededLogos[3],
          courtName: t.courtAllocation,
          timeSlot: '10:15 AM - 11:15 AM',
          stage: 'Quarter Final',
          nextMatchId: sf1Id,
          nextMatchSlot: 'teamB',
          winnerTeam: isBye2 ? seededNames[2] : '',
          status: isBye2 ? 'Completed' : 'Scheduled',
        ),
        TournamentFixture(
          id: 'fix_${t.id}_qf3',
          matchNumber: 'Quarter Final #3 (Seed 3 vs 6)',
          teamA: seededNames[4],
          teamB: seededNames[5],
          logoA: seededLogos[4],
          logoB: seededLogos[5],
          courtName: t.courtAllocation,
          timeSlot: '11:30 AM - 12:30 PM',
          stage: 'Quarter Final',
          nextMatchId: sf2Id,
          nextMatchSlot: 'teamA',
          winnerTeam: isBye3 ? seededNames[4] : '',
          status: isBye3 ? 'Completed' : 'Scheduled',
        ),
        TournamentFixture(
          id: 'fix_${t.id}_qf4',
          matchNumber: 'Quarter Final #4 (Seed 2 vs 7)',
          teamA: seededNames[6],
          teamB: seededNames[7],
          logoA: seededLogos[6],
          logoB: seededLogos[7],
          courtName: t.courtAllocation,
          timeSlot: '01:30 PM - 02:30 PM',
          stage: 'Quarter Final',
          nextMatchId: sf2Id,
          nextMatchSlot: 'teamB',
          winnerTeam: isBye4 ? seededNames[6] : '',
          status: isBye4 ? 'Completed' : 'Scheduled',
        ),
        TournamentFixture(
          id: sf1Id,
          matchNumber: 'Semi Final #1',
          teamA: isBye1 ? seededNames[0] : 'TBD (Winner QF1)',
          teamB: isBye2 ? seededNames[2] : 'TBD (Winner QF2)',
          courtName: t.courtAllocation,
          timeSlot: '03:30 PM - 04:30 PM',
          stage: 'Semi Final',
          nextMatchId: finalId,
          nextMatchSlot: 'teamA',
        ),
        TournamentFixture(
          id: sf2Id,
          matchNumber: 'Semi Final #2',
          teamA: isBye3 ? seededNames[4] : 'TBD (Winner QF3)',
          teamB: isBye4 ? seededNames[6] : 'TBD (Winner QF4)',
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

  /// Helper to calculate standard tournament seeding pairs (1 vs N, 2 vs N-1, etc.)
  static List<int> _calculateSeededPairs(int size) {
    if (size == 4) return [0, 3, 1, 2];
    if (size == 8) return [0, 7, 3, 4, 2, 5, 1, 6];
    return List.generate(size, (i) => i);
  }

  /// 2. DOUBLE ELIMINATION FIXTURES (Winners & Losers Brackets)
  static List<TournamentFixture> generateDoubleEliminationFixtures(
    TournamentModel t,
    List<TeamRegistrationModel> registeredList,
  ) {
    final teamNames = registeredList.map((tr) => tr.teamName).toList();
    final teamLogos = registeredList.map((tr) => tr.logoUrl).toList();

    while (teamNames.length < 4) {
      teamNames.add('BYE');
      teamLogos.add('https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=100&q=80');
    }

    final wbFinalId = 'fix_${t.id}_wb_final';
    final lbSemiId = 'fix_${t.id}_lb_semi';
    final lbFinalId = 'fix_${t.id}_lb_final';
    final grandFinalId = 'fix_${t.id}_grand_final';

    return [
      // Winners Bracket Round 1
      TournamentFixture(
        id: 'fix_${t.id}_wb_sf1',
        matchNumber: 'WB Match #1',
        teamA: teamNames[0],
        teamB: teamNames[1],
        logoA: teamLogos[0],
        logoB: teamLogos[1],
        courtName: t.courtAllocation,
        timeSlot: '09:00 AM - 10:00 AM',
        stage: 'Quarter Final',
        nextMatchId: wbFinalId,
        nextMatchSlot: 'teamA',
      ),
      TournamentFixture(
        id: 'fix_${t.id}_wb_sf2',
        matchNumber: 'WB Match #2',
        teamA: teamNames[2],
        teamB: teamNames[3],
        logoA: teamLogos[2],
        logoB: teamLogos[3],
        courtName: t.courtAllocation,
        timeSlot: '10:15 AM - 11:15 AM',
        stage: 'Quarter Final',
        nextMatchId: wbFinalId,
        nextMatchSlot: 'teamB',
      ),

      // Winners Bracket Final
      TournamentFixture(
        id: wbFinalId,
        matchNumber: 'WB Final (Winners Bracket)',
        teamA: 'TBD (Winner WB1)',
        teamB: 'TBD (Winner WB2)',
        courtName: t.courtAllocation,
        timeSlot: '12:00 PM - 01:00 PM',
        stage: 'Semi Final',
        nextMatchId: grandFinalId,
        nextMatchSlot: 'teamA',
      ),

      // Losers Bracket Semi Final (Revival match for losers of WB Match 1 & 2)
      TournamentFixture(
        id: lbSemiId,
        matchNumber: 'LB Match #1 (Revival Stage)',
        teamA: 'TBD (Loser WB1)',
        teamB: 'TBD (Loser WB2)',
        courtName: t.courtAllocation,
        timeSlot: '02:00 PM - 03:00 PM',
        stage: 'Quarter Final',
        nextMatchId: lbFinalId,
        nextMatchSlot: 'teamA',
      ),

      // Losers Bracket Final (Winner LB Match 1 vs Loser WB Final)
      TournamentFixture(
        id: lbFinalId,
        matchNumber: 'LB Final (Losers Bracket Champion)',
        teamA: 'TBD (Winner LB1)',
        teamB: 'TBD (Loser WB Final)',
        courtName: t.courtAllocation,
        timeSlot: '04:00 PM - 05:00 PM',
        stage: 'Semi Final',
        nextMatchId: grandFinalId,
        nextMatchSlot: 'teamB',
      ),

      // Grand Final (Winners Bracket Champion vs Losers Bracket Champion)
      TournamentFixture(
        id: grandFinalId,
        matchNumber: 'GRAND FINAL 🏆 (WB Champ vs LB Champ)',
        teamA: 'TBD (WB Champion)',
        teamB: 'TBD (LB Champion)',
        courtName: t.courtAllocation,
        timeSlot: '06:30 PM - 08:00 PM',
        stage: 'Final',
      ),
    ];
  }

  /// 3. GROUP STAGE + KNOCKOUT HYBRID FIXTURES (UEFA Style Groups + Knockout)
  static List<TournamentFixture> generateGroupStageAndKnockoutFixtures(
    TournamentModel t,
    List<TeamRegistrationModel> registeredList,
  ) {
    List<TeamRegistrationModel> teams = List.from(registeredList);
    if (teams.length < 4) {
      teams = const [
        TeamRegistrationModel(id: 'reg_1', teamName: 'Super Strikers', captainName: 'Rajesh', captainPhone: '9876543210', captainEmail: 'raj@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-01', logoUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=100&q=80'),
        TeamRegistrationModel(id: 'reg_2', teamName: 'Royal Kings', captainName: 'Karthik', captainPhone: '9876543211', captainEmail: 'karthik@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-02', logoUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=100&q=80'),
        TeamRegistrationModel(id: 'reg_3', teamName: 'Madurai Panthers', captainName: 'Suresh', captainPhone: '9876543212', captainEmail: 'suresh@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-03', logoUrl: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=100&q=80'),
        TeamRegistrationModel(id: 'reg_4', teamName: 'KK Nagar XI', captainName: 'Vijay', captainPhone: '9876543213', captainEmail: 'vijay@gmail.com', playerCount: 8, paymentStatus: 'Paid', registrationDate: '2026-08-04', logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=100&q=80'),
      ];
    }

    List<TournamentFixture> fixtures = [];

    // Dynamically split registered teams into Group A & Group B
    final half = (teams.length + 1) ~/ 2;
    final groupATeams = teams.sublist(0, half);
    final groupBTeams = teams.sublist(half);

    int matchIndex = 1;

    // Group A Round Robin Matches
    for (int i = 0; i < groupATeams.length; i++) {
      for (int j = i + 1; j < groupATeams.length; j++) {
        fixtures.add(
          TournamentFixture(
            id: 'fix_${t.id}_ga_$matchIndex',
            matchNumber: 'Group A - Match #$matchIndex',
            teamA: groupATeams[i].teamName,
            teamB: groupATeams[j].teamName,
            logoA: groupATeams[i].logoUrl,
            logoB: groupATeams[j].logoUrl,
            courtName: t.courtAllocation,
            timeSlot: '${(09 + matchIndex).toString().padLeft(2, '0')}:00 AM - ${(10 + matchIndex).toString().padLeft(2, '0')}:00 AM',
            stage: 'Group Stage',
            status: matchIndex == 1 ? 'Live' : 'Scheduled',
            scoreA: matchIndex == 1 ? 2 : 0,
            scoreB: matchIndex == 1 ? 1 : 0,
          ),
        );
        matchIndex++;
      }
    }

    // Group B Round Robin Matches
    int bMatchIndex = 1;
    for (int i = 0; i < groupBTeams.length; i++) {
      for (int j = i + 1; j < groupBTeams.length; j++) {
        fixtures.add(
          TournamentFixture(
            id: 'fix_${t.id}_gb_$bMatchIndex',
            matchNumber: 'Group B - Match #$bMatchIndex',
            teamA: groupBTeams[i].teamName,
            teamB: groupBTeams[j].teamName,
            logoA: groupBTeams[i].logoUrl,
            logoB: groupBTeams[j].logoUrl,
            courtName: t.courtAllocation,
            timeSlot: '${(01 + bMatchIndex).toString().padLeft(2, '0')}:00 PM - ${(02 + bMatchIndex).toString().padLeft(2, '0')}:00 PM',
            stage: 'Group Stage',
            status: 'Scheduled',
          ),
        );
        bMatchIndex++;
      }
    }

    // Knockout Stage: Semi Finals (Top 2 from Group A and Group B)
    final finalId = 'fix_${t.id}_hybrid_final';
    final sf1Id = 'fix_${t.id}_hybrid_sf1';
    final sf2Id = 'fix_${t.id}_hybrid_sf2';

    fixtures.add(
      TournamentFixture(
        id: sf1Id,
        matchNumber: 'Semi Final #1 (1st Group A vs 2nd Group B)',
        teamA: groupATeams.isNotEmpty ? '1st Group A (${groupATeams[0].teamName})' : '1st Group A',
        teamB: groupBTeams.length > 1 ? '2nd Group B (${groupBTeams[1].teamName})' : '2nd Group B',
        courtName: t.courtAllocation,
        timeSlot: '05:00 PM - 06:00 PM',
        stage: 'Semi Final',
        nextMatchId: finalId,
        nextMatchSlot: 'teamA',
      ),
    );

    fixtures.add(
      TournamentFixture(
        id: sf2Id,
        matchNumber: 'Semi Final #2 (1st Group B vs 2nd Group A)',
        teamA: groupBTeams.isNotEmpty ? '1st Group B (${groupBTeams[0].teamName})' : '1st Group B',
        teamB: groupATeams.length > 1 ? '2nd Group A (${groupATeams[1].teamName})' : '2nd Group A',
        courtName: t.courtAllocation,
        timeSlot: '06:15 PM - 07:15 PM',
        stage: 'Semi Final',
        nextMatchId: finalId,
        nextMatchSlot: 'teamB',
      ),
    );

    // Grand Final
    fixtures.add(
      TournamentFixture(
        id: finalId,
        matchNumber: 'GRAND FINAL 🏆',
        teamA: 'TBD (Winner SF1)',
        teamB: 'TBD (Winner SF2)',
        courtName: t.courtAllocation,
        timeSlot: '07:30 PM - 09:00 PM',
        stage: 'Final',
      ),
    );

    return fixtures;
  }
}
