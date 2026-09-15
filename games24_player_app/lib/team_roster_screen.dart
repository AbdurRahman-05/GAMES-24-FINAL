import 'package:flutter/material.dart';

class TeamRosterScreen extends StatelessWidget {
  const TeamRosterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 160), // padding for bottom buttons
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildTeamOverviewCard(),
                  const SizedBox(height: 16),
                  _buildFormationBanner(),
                  const SizedBox(height: 24),
                  _buildSquadMembersSection(),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildBottomActions(),
            ),
          ],
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
                    'Team Roster',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Squad Management & Tactics',
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
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_outlined, size: 18, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings_outlined, size: 18, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamOverviewCard() {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                        image: const DecorationImage(
                          image: NetworkImage('https://picsum.photos/seed/team1/150/150'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F6D38),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.settings, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Expanded(
                            child: Text(
                              'Blazing Strikers FC',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.verified, size: 16, color: Color(0xFF0F6D38)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Football • 7-a-side • Premier Tier',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FDF9),
                              border: Border.all(color: const Color(0xFFE5F5EB)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.circle, size: 6, color: Color(0xFF166534)),
                                SizedBox(width: 4),
                                Text(
                                  'Division 1',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '• South Turf Arena',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatBox('11', 'Players'),
                const SizedBox(width: 8),
                _buildStatBox('18', 'Matches'),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FDF9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5F5EB)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              '14',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                            ),
                            SizedBox(width: 2),
                            Text(
                              '(78%)',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text('Wins', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEF3C7)),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          '#3',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                        SizedBox(height: 2),
                        Text('City Rank', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key, size: 20, color: Color(0xFF0F6D38)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Squad Invite PIN', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                        Text(
                          'BSTRIKE-2024',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.copy, size: 14, color: Color(0xFF0F6D38)),
                        SizedBox(width: 4),
                        Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(Icons.send_outlined, size: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  Widget _buildFormationBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE5F5EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_mosaic_outlined, size: 20, color: Color(0xFF0F6D38)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Formation: 2-3-1 Classic',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Next Match: Friday vs Thunder Strikers',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5F5EB)),
              ),
              child: const Text(
                'Ready 8/7',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F6D38)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadMembersSection() {
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
                    'Squad Members',
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
                      color: const Color(0xFFE5F5EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '11',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F6D38),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.person_add_alt_1, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Add Member', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPlayerRow(
          number: '10',
          imageUrl: 'https://picsum.photos/seed/p1/50/50',
          name: 'Alex Rivera',
          isYou: true,
          roleBadge: 'Captain',
          roleBadgeColor: const Color(0xFFFFFBEB),
          roleBadgeTextColor: const Color(0xFFD97706),
          position: 'Striker',
          statIcon: Icons.bolt,
          statText: 'Pro 94',
          statColor: const Color(0xFF166534),
          actionIcon: Icons.query_stats,
          statusColor: const Color(0xFF10B981),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
        ),
        _buildPlayerRow(
          number: '1',
          imageUrl: 'https://picsum.photos/seed/p2/50/50',
          name: 'Marcus Vance',
          roleBadge: 'Key Player',
          roleBadgeColor: const Color(0xFFF3F4F6),
          roleBadgeTextColor: const Color(0xFF4B5563),
          position: 'Goalkeeper',
          statText: 'Clean Sheets: 6',
          actionIcon: Icons.chat_outlined,
          statusColor: const Color(0xFF10B981),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
        ),
        _buildPlayerRow(
          number: '4',
          imageUrl: 'https://picsum.photos/seed/p3/50/50',
          name: 'Rahul Sharma',
          roleBadge: 'Vice Captain',
          roleBadgeColor: const Color(0xFFECFDF5),
          roleBadgeTextColor: const Color(0xFF047857),
          position: 'Center Back',
          statText: 'Tackles: 42',
          actionIcon: Icons.chat_outlined,
          statusColor: const Color(0xFF10B981),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
        ),
        _buildPlayerRow(
          number: '7',
          imageUrl: 'https://picsum.photos/seed/p4/50/50',
          name: 'David Kim',
          roleBadge: 'Member',
          roleBadgeColor: Colors.transparent,
          roleBadgeTextColor: const Color(0xFF6B7280),
          position: 'Left Winger',
          statText: 'Assists: 9',
          actionIcon: Icons.chat_outlined,
          statusColor: const Color(0xFF10B981),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
        ),
        _buildPlayerRow(
          number: '8',
          imageUrl: 'https://picsum.photos/seed/p5/50/50',
          name: 'Tariq Al-Mansoor',
          roleBadge: 'Member',
          roleBadgeColor: Colors.transparent,
          roleBadgeTextColor: const Color(0xFF6B7280),
          position: 'Central Midfielder',
          statText: 'Pass Acc: 89%',
          actionIcon: Icons.chat_outlined,
          statusColor: const Color(0xFF10B981),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
        ),
        _buildPlayerRow(
          number: '11',
          imageUrl: 'https://picsum.photos/seed/p6/50/50',
          name: 'Lucas Silva',
          roleBadge: 'Pending RSVP',
          roleBadgeColor: const Color(0xFFFEF3C7),
          roleBadgeTextColor: const Color(0xFFD97706),
          position: 'Right Winger',
          positionColor: const Color(0xFFFFFBEB),
          positionTextColor: const Color(0xFFD97706),
          statText: 'Sub Option',
          statColor: const Color(0xFFD97706),
          actionIcon: Icons.notifications_active_outlined,
          actionIconColor: const Color(0xFFD97706),
          statusColor: const Color(0xFFF59E0B),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
        ),
        _buildPlayerRow(
          number: '3',
          imageUrl: 'https://picsum.photos/seed/p7/50/50',
          name: 'Carlos Mendez',
          roleBadge: 'Member',
          roleBadgeColor: Colors.transparent,
          roleBadgeTextColor: const Color(0xFF6B7280),
          position: 'Defender',
          statText: 'Interceptions: 19',
          actionIcon: Icons.chat_outlined,
          statusColor: const Color(0xFF10B981),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.people_outline, size: 18, color: Color(0xFF6B7280)),
                  SizedBox(width: 8),
                  Text(
                    '4 additional reserves registered',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              Row(
                children: const [
                  Text(
                    'View All',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F6D38)),
                  ),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF0F6D38)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRow({
    required String number,
    required String imageUrl,
    required String name,
    bool isYou = false,
    required String roleBadge,
    required Color roleBadgeColor,
    required Color roleBadgeTextColor,
    required String position,
    Color positionColor = const Color(0xFFF3F4F6),
    Color positionTextColor = const Color(0xFF4B5563),
    IconData? statIcon,
    required String statText,
    Color statColor = const Color(0xFF6B7280),
    required IconData actionIcon,
    Color actionIconColor = Colors.black87,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -4,
                left: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '#$number',
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
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
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '(You)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                    ],
                    const SizedBox(width: 6),
                    if (roleBadgeColor != Colors.transparent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleBadgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            if (roleBadge == 'Captain') ...[
                              Icon(Icons.emoji_events, size: 10, color: roleBadgeTextColor),
                              const SizedBox(width: 2),
                            ],
                            Text(
                              roleBadge,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: roleBadgeTextColor),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        roleBadge,
                        style: TextStyle(fontSize: 11, color: roleBadgeTextColor),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: positionColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        position,
                        style: TextStyle(fontSize: 10, color: positionTextColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (statIcon != null) ...[
                      Icon(statIcon, size: 12, color: statColor),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      statText,
                      style: TextStyle(fontSize: 11, fontWeight: statIcon != null ? FontWeight.bold : FontWeight.normal, color: statColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(actionIcon, size: 16, color: actionIconColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.sports_soccer, size: 18),
            label: const Text('Schedule Team Match / Book Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F6D38),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.sports_kabaddi, size: 18, color: Color(0xFF0F6D38)), // closely resembling crossed swords
            label: const Text('Challenge Other Squads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3F5F1),
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
