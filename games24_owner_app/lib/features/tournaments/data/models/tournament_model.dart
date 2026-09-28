class TournamentSponsor {
  final String id;
  final String name;
  final String logoUrl;
  final String category; // 'Title Sponsor', 'Powered By', 'Associate'

  const TournamentSponsor({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.category,
  });
}

class LeagueStandingRow {
  final String teamName;
  final int played;
  final int won;
  final int lost;
  final int drawn;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  const LeagueStandingRow({
    required this.teamName,
    this.played = 0,
    this.won = 0,
    this.lost = 0,
    this.drawn = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.points = 0,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  LeagueStandingRow copyWith({
    int? played,
    int? won,
    int? lost,
    int? drawn,
    int? goalsFor,
    int? goalsAgainst,
    int? points,
  }) {
    return LeagueStandingRow(
      teamName: teamName,
      played: played ?? this.played,
      won: won ?? this.won,
      lost: lost ?? this.lost,
      drawn: drawn ?? this.drawn,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      points: points ?? this.points,
    );
  }
}

class MatchEvent {
  final String id;
  final String type; // 'Goal', 'Wicket', 'Six', 'Four', 'Yellow Card', 'Red Card', 'Penalty', 'Point'
  final String teamName;
  final String playerName;
  final String minute;
  final String timestamp;

  const MatchEvent({
    required this.id,
    required this.type,
    required this.teamName,
    required this.playerName,
    required this.minute,
    required this.timestamp,
  });
}

class TournamentFixture {
  final String id;
  final String matchNumber;
  final String teamA;
  final String teamB;
  final String logoA;
  final String logoB;
  final int scoreA; // Runs for Cricket, Goals for Football, Sets/Points for Badminton
  final int scoreB;
  final int wicketsA; // Cricket specific
  final int wicketsB;
  final String oversA; // Cricket specific e.g. "18.2"
  final String oversB;
  final String courtName;
  final String timeSlot;
  final String matchDate;
  final String referee;
  final String status; // 'Scheduled', 'Live', 'Completed', 'Bye'
  final String stage; // 'Round of 32', 'Round of 16', 'Quarter Final', 'Semi Final', 'Final', 'Group Stage'
  final String winnerTeam;
  final String winnerLogo;
  final String? nextMatchId;
  final String? nextMatchSlot; // 'teamA' or 'teamB'
  final bool isPaused;
  final List<MatchEvent> events;

  const TournamentFixture({
    required this.id,
    required this.matchNumber,
    required this.teamA,
    required this.teamB,
    this.logoA = 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=100&q=80',
    this.logoB = 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=100&q=80',
    this.scoreA = 0,
    this.scoreB = 0,
    this.wicketsA = 0,
    this.wicketsB = 0,
    this.oversA = '',
    this.oversB = '',
    required this.courtName,
    required this.timeSlot,
    this.matchDate = 'Today',
    this.referee = 'Official Ref',
    this.status = 'Scheduled',
    required this.stage,
    this.winnerTeam = '',
    this.winnerLogo = '',
    this.nextMatchId,
    this.nextMatchSlot,
    this.isPaused = false,
    this.events = const [],
  });

  String getFormattedScore(String sportType) {
    if (sportType == 'Cricket') {
      final strA = oversA.isNotEmpty ? '$scoreA/$wicketsA ($oversA ov)' : '$scoreA/$wicketsA';
      final strB = oversB.isNotEmpty ? '$scoreB/$wicketsB ($oversB ov)' : '$scoreB/$wicketsB';
      return '$strA vs $strB';
    } else if (sportType == 'Badminton' || sportType == 'Tennis') {
      return '$scoreA - $scoreB Sets';
    }
    return '$scoreA - $scoreB';
  }

  TournamentFixture copyWith({
    String? teamA,
    String? teamB,
    String? logoA,
    String? logoB,
    int? scoreA,
    int? scoreB,
    int? wicketsA,
    int? wicketsB,
    String? oversA,
    String? oversB,
    String? status,
    String? winnerTeam,
    String? winnerLogo,
    bool? isPaused,
    List<MatchEvent>? events,
  }) {
    return TournamentFixture(
      id: id,
      matchNumber: matchNumber,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      logoA: logoA ?? this.logoA,
      logoB: logoB ?? this.logoB,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      wicketsA: wicketsA ?? this.wicketsA,
      wicketsB: wicketsB ?? this.wicketsB,
      oversA: oversA ?? this.oversA,
      oversB: oversB ?? this.oversB,
      courtName: courtName,
      timeSlot: timeSlot,
      matchDate: matchDate,
      referee: referee,
      status: status ?? this.status,
      stage: stage,
      winnerTeam: winnerTeam ?? this.winnerTeam,
      winnerLogo: winnerLogo ?? this.winnerLogo,
      nextMatchId: nextMatchId,
      nextMatchSlot: nextMatchSlot,
      isPaused: isPaused ?? this.isPaused,
      events: events ?? this.events,
    );
  }
}

class TeamRegistrationModel {
  final String id;
  final String teamName;
  final String captainName;
  final String captainPhone;
  final String captainEmail;
  final int playerCount;
  final String paymentStatus; // 'Paid', 'Pending', 'Failed'
  final String registrationDate;
  final String logoUrl;

  const TeamRegistrationModel({
    required this.id,
    required this.teamName,
    required this.captainName,
    required this.captainPhone,
    required this.captainEmail,
    required this.playerCount,
    required this.paymentStatus,
    required this.registrationDate,
    this.logoUrl = 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=100&q=80',
  });
}

class TournamentModel {
  final String id;
  final String title;
  final String subtitle;
  final String bannerUrl;
  final String logoUrl;
  final String description;
  final String rules;
  final String organizerName;
  final String contactPerson;
  final String phone;
  final String whatsapp;
  final String email;

  final String tournamentType; // Knockout, League, Round Robin, etc.
  final String sportType; // Football, Cricket, Futsal, etc.
  final String courtAllocation; // 'Turf A', 'Entire Turf', etc.

  final String regStartDate;
  final String regEndDate;
  final String startDate;
  final String endDate;
  final String matchStartTime;
  final String matchEndTime;
  final int matchDurationMinutes;
  final int breakMinutes;

  final double teamEntryFee;
  final double individualEntryFee;
  final double earlyBirdPrice;
  final double regularPrice;
  final double discountPercent;
  final double gstPercent;
  final double platformFee;

  final int maxTeams;
  final int minTeams;
  final int playersPerTeam;
  final int substitutePlayers;

  final String championPrize;
  final String runnerUpPrize;
  final String secondRunnerUpPrize;
  final String mvpPrize;

  final String status; // 'Upcoming', 'Live', 'Completed', 'Draft'
  final int registeredTeamsCount;
  final double totalRevenue;
  final String liveScore;
  final String liveCommentary;

  final String championTeam;
  final String championLogo;

  final List<TournamentFixture> fixtures;
  final List<LeagueStandingRow> standings;
  final List<TeamRegistrationModel> registeredTeams;
  final List<TournamentSponsor> sponsors;

  const TournamentModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.bannerUrl,
    required this.logoUrl,
    required this.description,
    required this.rules,
    required this.organizerName,
    required this.contactPerson,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.tournamentType,
    required this.sportType,
    required this.courtAllocation,
    required this.regStartDate,
    required this.regEndDate,
    required this.startDate,
    required this.endDate,
    required this.matchStartTime,
    required this.matchEndTime,
    required this.matchDurationMinutes,
    required this.breakMinutes,
    required this.teamEntryFee,
    this.individualEntryFee = 0,
    this.earlyBirdPrice = 0,
    required this.regularPrice,
    this.discountPercent = 0,
    this.gstPercent = 18,
    this.platformFee = 50,
    required this.maxTeams,
    required this.minTeams,
    required this.playersPerTeam,
    required this.substitutePlayers,
    required this.championPrize,
    required this.runnerUpPrize,
    this.secondRunnerUpPrize = '',
    this.mvpPrize = '',
    required this.status,
    this.registeredTeamsCount = 0,
    this.totalRevenue = 0,
    this.liveScore = '',
    this.liveCommentary = '',
    this.championTeam = '',
    this.championLogo = '',
    this.fixtures = const [],
    this.standings = const [],
    this.registeredTeams = const [],
    this.sponsors = const [],
  });

  TournamentModel copyWith({
    String? status,
    String? tournamentType,
    int? registeredTeamsCount,
    double? totalRevenue,
    String? liveScore,
    String? liveCommentary,
    String? championTeam,
    String? championLogo,
    List<TournamentFixture>? fixtures,
    List<LeagueStandingRow>? standings,
    List<TeamRegistrationModel>? registeredTeams,
  }) {
    return TournamentModel(
      id: id,
      title: title,
      subtitle: subtitle,
      bannerUrl: bannerUrl,
      logoUrl: logoUrl,
      description: description,
      rules: rules,
      organizerName: organizerName,
      contactPerson: contactPerson,
      phone: phone,
      whatsapp: whatsapp,
      email: email,
      tournamentType: tournamentType ?? this.tournamentType,
      sportType: sportType,
      courtAllocation: courtAllocation,
      regStartDate: regStartDate,
      regEndDate: regEndDate,
      startDate: startDate,
      endDate: endDate,
      matchStartTime: matchStartTime,
      matchEndTime: matchEndTime,
      matchDurationMinutes: matchDurationMinutes,
      breakMinutes: breakMinutes,
      teamEntryFee: teamEntryFee,
      individualEntryFee: individualEntryFee,
      earlyBirdPrice: earlyBirdPrice,
      regularPrice: regularPrice,
      discountPercent: discountPercent,
      gstPercent: gstPercent,
      platformFee: platformFee,
      maxTeams: maxTeams,
      minTeams: minTeams,
      playersPerTeam: playersPerTeam,
      substitutePlayers: substitutePlayers,
      championPrize: championPrize,
      runnerUpPrize: runnerUpPrize,
      secondRunnerUpPrize: secondRunnerUpPrize,
      mvpPrize: mvpPrize,
      status: status ?? this.status,
      registeredTeamsCount: registeredTeamsCount ?? this.registeredTeamsCount,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      liveScore: liveScore ?? this.liveScore,
      liveCommentary: liveCommentary ?? this.liveCommentary,
      championTeam: championTeam ?? this.championTeam,
      championLogo: championLogo ?? this.championLogo,
      fixtures: fixtures ?? this.fixtures,
      standings: standings ?? this.standings,
      registeredTeams: registeredTeams ?? this.registeredTeams,
      sponsors: sponsors,
    );
  }
}
