import 'package:flutter/material.dart';
import 'package:games24_player_app/team_roster_screen.dart';

class TeamsHubScreen extends StatelessWidget {
  const TeamsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildCreateTeamCard(),
              const SizedBox(height: 16),
              _buildJoinTeamCard(),
              const SizedBox(height: 24),
              _buildYourTeamsSection(context),
              const SizedBox(height: 24),
              _buildRecruitingSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Teams Hub',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage squads & match rosters',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(Icons.search, size: 18, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FDF9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5F5EB)),
                ),
                child: const Icon(Icons.qr_code_scanner, size: 18, color: Color(0xFF166534)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTeamCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FDF9),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(120),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F5F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.group_add_outlined, color: Color(0xFF166534), size: 24),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF86EFAC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Fast Setup',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14532D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Create New Team',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Form your squad, pick home turf & lead tournaments',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Text('Create Squad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      label: const Icon(Icons.arrow_forward, size: 16),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6D38),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinTeamCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.key_outlined, color: Colors.black54, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Join with PIN / Code',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Got a 6-digit squad passcode?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.key, size: 16, color: Color(0xFF6B7280)),
                        SizedBox(width: 8),
                        Text(
                          'E.G. STRK-24',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    label: const Icon(Icons.arrow_forward, size: 16, color: Colors.black87),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5E7EB), // Light grey
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourTeamsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Your Teams',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '2',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF166534),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTeamCard(
          context: context,
          logoUrl: 'https://picsum.photos/seed/team1/150/150',
          sportIcon: Icons.sports_soccer,
          teamName: 'Blazing Strikers FC',
          roleBadge: 'Captain',
          isCaptain: true,
          sportDetail: 'Football • 7v7 Squad',
          membersCount: '11',
          winsCount: '14',
          rating: '4.9',
          avatarsCount: '+7',
          dateText: 'Sat, Oct 12',
          nextMatchText: 'Weekend Turf Clash vs Red Hawks',
          nextMatchTime: '19:30',
          buttonText: 'View Roster & Strategy',
          onTapDetails: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TeamRosterScreen()),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildTeamCard(
          context: context,
          logoUrl: 'https://picsum.photos/seed/team2/150/150',
          sportIcon: Icons.sports_cricket,
          teamName: 'Thunder Smashers',
          roleBadge: 'Vice Captain',
          isCaptain: false,
          sportDetail: 'Cricket • Box Cricket\nSquad', // Adding newline to match design
          membersCount: '8',
          winsCount: '8',
          rating: '4.7',
          avatarsCount: '+4',
          dateText: 'Practice: Thu 8 PM',
          nextMatchText: null, // No match bar for this one
          nextMatchTime: null,
          buttonText: 'View Roster & Details',
          onTapDetails: () {},
        ),
      ],
    );
  }

  Widget _buildTeamCard({
    required BuildContext context,
    required String logoUrl,
    required IconData sportIcon,
    required String teamName,
    required String roleBadge,
    required bool isCaptain,
    required String sportDetail,
    required String membersCount,
    required String winsCount,
    required String rating,
    required String avatarsCount,
    required String dateText,
    String? nextMatchText,
    String? nextMatchTime,
    required String buttonText,
    required VoidCallback onTapDetails,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            // Top Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        image: DecorationImage(
                          image: NetworkImage(logoUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F6D38),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(sportIcon, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              teamName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCaptain ? const Color(0xFFF7FDF9) : const Color(0xFFF3F4F6),
                              border: Border.all(color: isCaptain ? const Color(0xFFE5F5EB) : const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                if (isCaptain) ...[
                                  const Icon(Icons.emoji_events, size: 10, color: Color(0xFF166534)),
                                  const SizedBox(width: 4),
                                ] else ...[
                                  const Icon(Icons.shield_outlined, size: 10, color: Colors.black54),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  roleBadge,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isCaptain ? const Color(0xFF166534) : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sportDetail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(membersCount, 'Members'),
                  _buildStatItem(winsCount, 'Wins', valueColor: const Color(0xFF166534)),
                  _buildStatItem(rating, 'Rating', isRating: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Avatars and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildAvatarStack(),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        avatarsCount,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (nextMatchText != null) ...[
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF166534)),
                      const SizedBox(width: 4),
                      Text(
                        dateText,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                      ),
                    ] else ...[
                      Text(
                        dateText,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (nextMatchText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F1), // Light green tint
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined, size: 16, color: Color(0xFF166534)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nextMatchText,
                        style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      nextMatchTime!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onTapDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F5F1),
                  foregroundColor: const Color(0xFF0F6D38),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {Color valueColor = Colors.black87, bool isRating = false}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isRating ? const Color(0xFFD97706) : valueColor, // Orange for rating
              ),
            ),
            if (isRating) ...[
              const SizedBox(width: 2),
              const Icon(Icons.star_outline, size: 14, color: Color(0xFFD97706)),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarStack() {
    return SizedBox(
      width: 70,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: _buildAvatarItem('https://picsum.photos/seed/p1/50/50'),
          ),
          Positioned(
            left: 20,
            child: _buildAvatarItem('https://picsum.photos/seed/p2/50/50'),
          ),
          Positioned(
            left: 40,
            child: _buildAvatarItem('https://picsum.photos/seed/p3/50/50'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarItem(String url) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildRecruitingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Recruiting Near You',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Teams looking for players tonight',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const Text(
                'View All (5)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F6D38),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F1), // Light green tint
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.sports_soccer, size: 24, color: Color(0xFF166534)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Metro Eagles',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2), // Light red
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '2 Slots',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB91C1C), // Dark red
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Seeking: Striker / Midfielder',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F1), // Light green
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.stadium_outlined, size: 16, color: Color(0xFF166534)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Grand Arena • Turf A',
                          style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        'Tonight, 21:00',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.black87),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text('Request to Join', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F6D38),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
