class TeamModel {
  final String id;
  final String name;
  final String logoUrl;
  final String captainName;
  final String captainAvatar;
  final String sportName;
  final String homeTurf;
  final int membersCount;
  final int matchesPlayed;
  final int wins;
  final double winRate;
  final List<String> achievements;

  const TeamModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.captainName,
    required this.captainAvatar,
    required this.sportName,
    required this.homeTurf,
    required this.membersCount,
    required this.matchesPlayed,
    required this.wins,
    required this.winRate,
    required this.achievements,
  });
}
