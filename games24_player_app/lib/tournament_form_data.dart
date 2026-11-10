import 'tournament_manager.dart';

class TournamentFormData {
  final String title;
  final String sport;
  final String prizePool;
  final String entryFee;
  final int maxTeams;
  final String date;
  final String time;
  final String venue;
  final String location;
  final String format;
  final bool isPrivate;
  final String accessCode;
  final List<String> rules;
  final String customRules;
  final String imageUrl;

  TournamentFormData({
    required this.title,
    required this.sport,
    required this.prizePool,
    required this.entryFee,
    required this.maxTeams,
    required this.date,
    required this.time,
    required this.venue,
    required this.location,
    required this.format,
    required this.isPrivate,
    this.accessCode = '',
    this.rules = const [],
    this.customRules = '',
    this.imageUrl = 'https://picsum.photos/seed/turf1/800/400',
  });

  Tournament toTournament() {
    return Tournament(
      id: 'tourney_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim().isNotEmpty ? title.trim() : (isPrivate ? 'Private Invitational Cup' : 'City Championship 2026'),
      sport: sport,
      status: TournamentStatus.upcoming,
      date: date,
      time: time,
      venue: venue,
      location: location,
      entryFee: entryFee.trim().isNotEmpty ? entryFee.trim() : 'Free Entry',
      prizePool: prizePool.trim().isNotEmpty ? prizePool.trim() : '₹10,000 + Trophy',
      grandPrize: prizePool.trim().isNotEmpty ? prizePool.trim() : '₹10,000',
      maxTeams: maxTeams,
      registeredTeams: 0,
      format: format,
      imageUrl: imageUrl,
      reportingTime: '15 mins before match',
      isPrivate: isPrivate,
      accessCode: isPrivate ? accessCode : null,
    );
  }
}
