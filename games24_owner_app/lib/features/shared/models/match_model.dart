class MatchModel {
  final String id;
  final String sportId;
  final String sportName;
  final String hostName;
  final String hostAvatar;
  final String hostPhone;
  final String venueId;
  final String venueName;
  final String area;
  final String date;
  final String time;
  final String skillLevel;
  final int totalPlayersNeeded;
  final int joinedPlayersCount;
  final List<String> playerAvatars;
  final double pricePerPlayer;
  final String description;

  const MatchModel({
    required this.id,
    required this.sportId,
    required this.sportName,
    required this.hostName,
    required this.hostAvatar,
    required this.hostPhone,
    required this.venueId,
    required this.venueName,
    required this.area,
    required this.date,
    required this.time,
    required this.skillLevel,
    required this.totalPlayersNeeded,
    required this.joinedPlayersCount,
    required this.playerAvatars,
    required this.pricePerPlayer,
    required this.description,
  });

  bool get isFull => joinedPlayersCount >= totalPlayersNeeded;
}
