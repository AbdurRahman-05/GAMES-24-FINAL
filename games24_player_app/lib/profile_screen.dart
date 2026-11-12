import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:games24_player_app/api_config.dart';
import 'package:games24_player_app/my_bookings_screen.dart';
import 'package:games24_player_app/teams_hub_screen.dart';
import 'package:games24_player_app/leaderboard_screen.dart';
import 'package:games24_player_app/login_screen.dart';
import 'package:games24_player_app/performance_screen.dart';
import 'package:games24_player_app/badges_screen.dart';
import 'package:games24_player_app/settings_screen.dart';
import 'package:games24_player_app/support_screen.dart';
import 'package:games24_player_app/booking_manager.dart';
import 'package:games24_player_app/match_score_manager.dart';
import 'package:games24_player_app/match_scorecard_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = 'Loading...';
  String _mobileNumber = '';
  String _preferredSport = 'Cricket';
  String _playerId = 'PLY-0001';
  String _city = 'Chennai';
  String _state = 'Tamil Nadu';
  String _role = 'All-Rounder';
  String _rank = '#1';
  String _points = '3,580';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    BookingManager().fetchBookings();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawPhone = prefs.getString('mobileNumber') ?? '';
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final fallbackId = 'PLY-${digits.length >= 4 ? digits.substring(digits.length - 4) : '0001'}';

    setState(() {
      _fullName = prefs.getString('fullName') ?? 'Active Player';
      _mobileNumber = rawPhone;
      _preferredSport = prefs.getString('preferredSport') ?? 'Cricket';
      _playerId = prefs.getString('playerId') ?? fallbackId;
      _city = prefs.getString('userCity') ?? 'Chennai';
      _state = prefs.getString('userState') ?? 'Tamil Nadu';
      _role = prefs.getString('userRole') ?? 'All-Rounder';
    });

    if (_mobileNumber.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/auth/user-profile?phone=$_mobileNumber')).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (mounted) {
            setState(() {
              if (data['fullName'] != null && data['fullName'].toString().isNotEmpty) {
                _fullName = data['fullName'].toString();
                prefs.setString('fullName', _fullName);
              }
              if (data['preferredSport'] != null) {
                _preferredSport = data['preferredSport'].toString();
                prefs.setString('preferredSport', _preferredSport);
              }
              if (data['playerId'] != null && data['playerId'].toString().isNotEmpty) {
                _playerId = data['playerId'].toString();
                prefs.setString('playerId', _playerId);
              }
            });
          }
        }
      } catch (e) {
        debugPrint("Error refreshing player profile from backend: $e");
      }

      // Also fetch rank and points from leaderboard
      try {
        final lbRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/auth/leaderboard?city=$_city&phone=$_mobileNumber&playerId=$_playerId')).timeout(const Duration(seconds: 4));
        if (lbRes.statusCode == 200) {
          final lbData = jsonDecode(lbRes.body);
          if (mounted && lbData['currentUserRank'] != null) {
            setState(() {
              _rank = '#${lbData['currentUserRank']['rank'] ?? 1}';
              _points = '${lbData['currentUserRank']['points'] ?? '3,580'}';
              if (lbData['currentUserRank']['role'] != null) {
                _role = lbData['currentUserRank']['role'];
              }
            });
          }
        }
      } catch (_) {}
    }
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'football':
        return Icons.sports_soccer;
      case 'cricket':
        return Icons.sports_cricket;
      case 'badminton':
        return Icons.sports_tennis;
      default:
        return Icons.sports_baseball;
    }
  }

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
              icon: Icons.sports_score_outlined,
              title: 'Match Center & Scorecard',
              subtitle: 'Live scoring, coin toss & squad roster',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MatchScorecardScreen(
                      bookingId: 'P-RECENT',
                      turfName: 'Community Arena',
                      sport: 'Cricket',
                      date: 'Today',
                      timeSlot: 'Live Session',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              context: context,
              icon: Icons.bar_chart_outlined,
              title: 'Performance',
              subtitle: 'Match stats, heatmaps & analytics',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PerformanceScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              context: context,
              icon: Icons.leaderboard_outlined,
              title: 'Leaderboard & Standings',
              subtitle: '$_rank in $_city • Friends, City, State & Sport rankings',
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BadgesScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('PREFERENCES & HELP'),
            const SizedBox(height: 12),
            _buildMenuItem(
              context: context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Account details, notifications & security',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              context: context,
              icon: Icons.support_agent_outlined,
              title: 'Support',
              subtitle: 'Help center & live chat assistance',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupportScreen()),
                );
              },
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
          // Avatar with Member Badge
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF166534),
                ),
                alignment: Alignment.center,
                child: Text(
                  _fullName.isNotEmpty ? _fullName.substring(0, 1).toUpperCase() : 'P',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                        'Member',
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
                    Text(
                      _fullName,
                      style: const TextStyle(
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
                      child: Icon(
                        _getSportIcon(_preferredSport),
                        color: const Color(0xFF0F6D38),
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _mobileNumber,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F5EB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBE5CA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_outlined, size: 12, color: Color(0xFF166534)),
                      const SizedBox(width: 4),
                      Text(
                        'ID: $_playerId',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _playerId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Player ID $_playerId copied!'),
                              backgroundColor: const Color(0xFF0F6D38),
                            ),
                          );
                        },
                        child: const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF166534), size: 13),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        '$_city, $_state • $_preferredSport $_role',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F6D38), Color(0xFF166534)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F6D38).withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '$_rank in $_city • $_points PTS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.star_outline, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '5.0 Player Rating',
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
    return ValueListenableBuilder<int>(
      valueListenable: MatchScoreManager().statsNotifier,
      builder: (context, statsTick, child) {
        return ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: BookingManager().bookingsNotifier,
          builder: (context, bookings, _) {
            final baseCount = bookings.length;
            final totalMatches = MatchScoreManager().getTotalMatches(baseCount);
            final wins = MatchScoreManager().getTotalWins(baseCount);
            final form = MatchScoreManager().getFormIndex(baseCount);

            return Row(
              children: [
                _buildStatCard(
                  icon: Icons.sports_soccer,
                  value: '$totalMatches',
                  label: 'Total Matches',
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.emoji_events_outlined,
                  value: '$wins',
                  label: 'Wins',
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.local_fire_department_outlined,
                  value: form,
                  label: 'Form Index',
                  isOrange: true,
                ),
              ],
            );
          },
        );
      },
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
