import 'package:flutter/material.dart';
import 'package:games24_player_app/my_bookings_screen.dart';
import 'package:games24_player_app/teams_hub_screen.dart';
import 'package:games24_player_app/leaderboard_screen.dart';
import 'package:games24_player_app/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildSectionTitle('ACTIVITY & MANAGEMENT'),
            const SizedBox(height: 12),
            _buildMenuItem(
              context: context,
              icon: Icons.calendar_month_outlined,
              title: 'My Bookings',
              subtitle: 'Upcoming turf slots & history',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              context: context,
              icon: Icons.groups_outlined,
              title: 'Teams',
              subtitle: 'Manage squads & rosters',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TeamsHubScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              context: context,
              icon: Icons.bar_chart_outlined,
              title: 'Performance',
              subtitle: 'Match stats, heatmaps & analytics',
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              context: context,
              icon: Icons.leaderboard_outlined,
              title: 'Leaderboard',
              subtitle: 'City rankings & tournament standings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              context: context,
              icon: Icons.military_tech_outlined,
              title: 'Badges',
              subtitle: 'Achievements & milestone rewards',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('PREFERENCES & HELP'),
            const SizedBox(height: 12),
            _buildMenuItem(
              context: context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Account details, notifications & security',
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              context: context,
              icon: Icons.support_agent_outlined,
              title: 'Support',
              subtitle: 'Help center & live chat assistance',
            ),
            const SizedBox(height: 32),
            _buildLogOutButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with Pro Badge
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage('https://picsum.photos/seed/user1/150/150'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F6D38),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 10),
                      SizedBox(width: 2),
                      Text(
                        'Pro',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Alex Rivera',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBE5CA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Turf Master',
                        style: TextStyle(
                          color: Color(0xFF0F6D38),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Member since Oct 2023 • Delhi NCR',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.star_outline, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '4.92 Player Rating',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(icon: Icons.sports_soccer, value: '142', label: 'Total Matches'),
        const SizedBox(width: 12),
        _buildStatCard(icon: Icons.emoji_events_outlined, value: '98', label: 'Wins'),
        const SizedBox(width: 12),
        _buildStatCard(icon: Icons.local_fire_department_outlined, value: '8.4', label: 'Form Index', isOrange: true),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required String value, required String label, bool isOrange = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isOrange ? Colors.orange : const Color(0xFF0F6D38), size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF9CA3AF),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildMenuItem({required BuildContext context, required IconData icon, required String title, required String subtitle, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0F6D38), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        ],
      ),
      ),
    );
  }

  Widget _buildLogOutButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.logout, color: Color(0xFFDC2626), size: 20),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
