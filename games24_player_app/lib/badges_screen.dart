import 'main_layout.dart';
import 'package:flutter/material.dart';
import 'booking_manager.dart';
import 'team_manager.dart';

class BadgeItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final String progressText;
  final int points;

  BadgeItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.progressText,
    required this.points,
  });
}

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = BookingManager().allBookings;
    final teams = TeamManager().teams;

    final hasBooking = bookings.isNotEmpty;
    final hasThreeBookings = bookings.length >= 3;
    final hasTeam = teams.isNotEmpty;

    final List<BadgeItem> badges = [
      BadgeItem(
        title: 'First Kickoff',
        description: 'Book your very first turf slot on Gamez24',
        icon: Icons.sports_soccer_rounded,
        color: const Color(0xFF154D36),
        isUnlocked: hasBooking,
        progressText: hasBooking ? 'Unlocked' : '0/1 Bookings',
        points: 100,
      ),
      BadgeItem(
        title: 'Squad Leader',
        description: 'Create or lead your own team squad',
        icon: Icons.groups_rounded,
        color: const Color(0xFF0284C7),
        isUnlocked: hasTeam,
        progressText: hasTeam ? 'Unlocked' : '0/1 Teams',
        points: 150,
      ),
      BadgeItem(
        title: 'Hat-Trick Booker',
        description: 'Complete 3 turf match bookings',
        icon: Icons.military_tech_rounded,
        color: const Color(0xFFEA580C),
        isUnlocked: hasThreeBookings,
        progressText: hasThreeBookings ? 'Unlocked' : '${bookings.length}/3 Bookings',
        points: 250,
      ),
      BadgeItem(
        title: 'Night Owl',
        description: 'Play a prime evening game under floodlights after 6 PM',
        icon: Icons.nightlight_round,
        color: const Color(0xFF7C3AED),
        isUnlocked: hasBooking,
        progressText: hasBooking ? 'Unlocked' : '0/1 Evening Slots',
        points: 120,
      ),
      BadgeItem(
        title: 'Weekend Warrior',
        description: 'Book and play a match on Saturday or Sunday',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFDC2626),
        isUnlocked: false,
        progressText: '0/2 Matches',
        points: 200,
      ),
      BadgeItem(
        title: 'Tournament Challenger',
        description: 'Register and compete in a community tournament',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFD97706),
        isUnlocked: false,
        progressText: '0/1 Tournaments',
        points: 300,
      ),
      BadgeItem(
        title: 'Fair Play Champion',
        description: 'Maintain a 5.0 player rating with zero penalties',
        icon: Icons.shield_rounded,
        color: const Color(0xFF059669),
        isUnlocked: true,
        progressText: 'Unlocked',
        points: 100,
      ),
      BadgeItem(
        title: 'Grand Master',
        description: 'Unlock 5 badges to earn the exclusive Gamez24 Master badge',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFB45309),
        isUnlocked: false,
        progressText: '${(hasBooking ? 1 : 0) + (hasTeam ? 1 : 0) + 1}/5 Badges',
        points: 500,
      ),
    ];

    final unlockedCount = badges.where((b) => b.isUnlocked).length;
    final totalPoints = badges.where((b) => b.isUnlocked).fold(0, (sum, b) => sum + b.points);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Badges & Achievements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827), size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainLayout()),
              );
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header summary card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Achievement Score',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalPoints PTS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF154D36),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unlockedCount of ${badges.length} Unlocked',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: unlockedCount / badges.length,
                      backgroundColor: Colors.white24,
                      color: const Color(0xFF22C55E),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'ALL MILESTONES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            ...badges.map((badge) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: badge.isUnlocked ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
                    width: badge.isUnlocked ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: badge.isUnlocked
                            ? badge.color.withValues(alpha: 0.12)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        badge.icon,
                        color: badge.isUnlocked ? badge.color : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  badge.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (badge.isUnlocked) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle, color: Color(0xFF154D36), size: 14),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            badge.description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+${badge.points}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: badge.isUnlocked ? const Color(0xFF154D36) : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: badge.isUnlocked ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge.progressText,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: badge.isUnlocked ? const Color(0xFF154D36) : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

