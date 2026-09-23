import '../models/team_model.dart';

class MockTeamsRepository {
  MockTeamsRepository._();

  static const List<TeamModel> teams = [
    TeamModel(
      id: 't1',
      name: 'Madurai Strikers FC',
      logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=200&q=80',
      captainName: 'Karthik Raja',
      captainAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
      sportName: 'Football',
      homeTurf: 'Madurai Turf Arena (KK Nagar)',
      membersCount: 11,
      matchesPlayed: 18,
      wins: 14,
      winRate: 77.8,
      achievements: ['KK Nagar Turf Champions 🏆', 'Best Defensive Unit 🛡️'],
    ),
    TeamModel(
      id: 't2',
      name: 'Vaigai Blasters Box Cricket',
      logoUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=200&q=80',
      captainName: 'Arun Pandian',
      captainAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
      sportName: 'Cricket',
      homeTurf: 'Madurai Turf Arena (KK Nagar)',
      membersCount: 8,
      matchesPlayed: 24,
      wins: 19,
      winRate: 79.2,
      achievements: ['Madurai League Winners 2025 🥇', 'Max Sixes Award 💥'],
    ),
    TeamModel(
      id: 't3',
      name: 'Anna Nagar Smashers',
      logoUrl: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=200&q=80',
      captainName: 'Suresh Kumar',
      captainAvatar: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=150&q=80',
      sportName: 'Badminton',
      homeTurf: 'Royal Badminton Hub (Anna Nagar)',
      membersCount: 6,
      matchesPlayed: 15,
      wins: 11,
      winRate: 73.3,
      achievements: ['Doubles Cup Semi-Finalists 🏸'],
    ),
  ];
}
