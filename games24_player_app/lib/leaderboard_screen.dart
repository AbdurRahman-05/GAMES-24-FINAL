import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedTab = 'Global (Universal)';
  String _selectedSport = 'All Sports';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Leaderboard',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F6D38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Season 4',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Text(
              'Universal Player Rankings • Live Standings',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeasonBanner(),
            _buildTabs(),
            _buildFilters(),
            _buildPodium(),
            _buildCurrentUserCard(),
            _buildRankingsList(),
            _buildInfoCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonBanner() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F6D38),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Season 4 Final Lap',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.circle, size: 6, color: Colors.red),
                      const SizedBox(width: 4),
                      const Text(
                        '12d left',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Top 3 earn ₹25,000 Vouchers + Golden Jersey',
                    style: TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            _buildTabItem('Global (Universal)'),
            _buildTabItem('Delhi NCR'),
            _buildTabItem('Squads'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String title) {
    bool isSelected = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: isSelected ? Border.all(color: Colors.grey[300]!) : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF0F6D38) : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          _buildFilterChip('All Sports', Icons.all_inclusive, isSelected: _selectedSport == 'All Sports'),
          const SizedBox(width: 8),
          _buildFilterChip('Football', Icons.sports_soccer, isSelected: _selectedSport == 'Football'),
          const SizedBox(width: 8),
          _buildFilterChip('Cricket', Icons.sports_cricket, isSelected: _selectedSport == 'Cricket'),
          const SizedBox(width: 8),
          _buildFilterChip('Badminton', Icons.sports_tennis, isSelected: _selectedSport == 'Badminton'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData icon, {
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedSport = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F6D38) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F6D38) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPodiumItem(
            rank: 2,
            name: 'Alex R.',
            location: 'Delhi NCR',
            points: '3,150',
            winRate: '88% W',
            imageUrl: 'https://picsum.photos/seed/user1/150/150',
            isYou: true,
          ),
          const SizedBox(width: 16),
          _buildPodiumItem(
            rank: 1,
            name: 'Vikram Sethi',
            location: 'Delhi NCR',
            points: '3,420',
            winRate: '94% W',
            imageUrl: 'https://picsum.photos/seed/user2/150/150',
            isCenter: true,
          ),
          const SizedBox(width: 16),
          _buildPodiumItem(
            rank: 3,
            name: 'Sameer K.',
            location: 'Mumbai',
            points: '2,980',
            winRate: '82% W',
            imageUrl: 'https://picsum.photos/seed/user3/150/150',
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem({
    required int rank,
    required String name,
    required String location,
    required String points,
    required String winRate,
    required String imageUrl,
    bool isCenter = false,
    bool isYou = false,
  }) {
    double avatarSize = isCenter ? 80 : 64;
    Color medalColor = isCenter
        ? Colors.amber
        : (rank == 2 ? Colors.grey[400]! : Colors.brown[300]!);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isCenter
                      ? [Colors.orange, Colors.amber]
                      : [Colors.grey[300]!, Colors.grey[100]!],
                ),
              ),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            if (isCenter)
              Positioned(
                top: -16,
                child: Icon(
                  Icons.workspace_premium,
                  color: Colors.amber,
                  size: 32,
                ),
              )
            else
              Positioned(
                top: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: medalColor, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '$rank${rank == 2 ? "nd" : "rd"}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (isCenter || isYou)
              Positioned(
                bottom: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isCenter ? Colors.orange : const Color(0xFF0F6D38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCenter ? '#1 Universal' : 'YOU',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isCenter ? 14 : 12,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCenter)
              const Icon(Icons.sports_soccer, size: 10, color: Colors.grey),
            if (isCenter) const SizedBox(width: 2),
            Text(
              location,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                points,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCenter
                      ? Colors.orange[800]
                      : const Color(0xFF0F6D38),
                ),
              ),
              Text(
                'PTS • $winRate',
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentUserCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5F5EB)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F6D38).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://picsum.photos/seed/user1/150/150',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F6D38),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Text(
                          '#2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
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
                          const Text(
                            'Alex Rivera',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBBE5CA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Turf Master',
                              style: TextStyle(
                                color: Color(0xFF0F6D38),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Top 0.5% Globally • Delhi NCR',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      '3,150',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0F6D38),
                      ),
                    ),
                    Text(
                      'universal pts',
                      style: TextStyle(color: Colors.grey, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Color(0xFF0F6D38),
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text(
                  '270 pts to take #1 from Vikram',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
                const Spacer(),
                const Text(
                  '92%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F6D38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.92,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0F6D38),
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Universal Rankings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Updated every 15 mins • 4,820 Active Contenders',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.tune, size: 14, color: Colors.black87),
                    SizedBox(width: 4),
                    Text(
                      'Filter',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        _buildRankRow(
          rank: 4,
          name: 'Arjun Kapoor',
          change: '+ 2',
          location: 'Bangalore',
          sport: 'Cricket',
          points: '2,840',
          wins: '46 Wins',
          imageUrl: 'https://picsum.photos/seed/user4/150/150',
          isVerified: true,
        ),
        _buildDivider(),
        _buildRankRow(
          rank: 5,
          name: 'Elena Rostova',
          change: '-',
          location: 'Mumbai',
          sport: 'Badminton',
          points: '2,710',
          wins: '52 Wins',
          imageUrl: 'https://picsum.photos/seed/user5/150/150',
          isVerified: true,
        ),
        _buildDivider(),
        _buildRankRow(
          rank: 6,
          name: 'Tariq Al-Mansoor',
          change: '+ 1',
          location: 'Delhi NCR',
          sport: 'Football',
          points: '2,630',
          wins: '38 Wins',
          imageUrl: 'https://picsum.photos/seed/user6/150/150',
        ),
        _buildDivider(),
        _buildRankRow(
          rank: 7,
          name: 'David Kim',
          change: '- 1',
          location: 'Chennai',
          sport: 'Football',
          points: '2,510',
          wins: '35 Wins',
          imageUrl: 'https://picsum.photos/seed/user7/150/150',
          isChangeNegative: true,
        ),
        _buildDivider(),
        _buildRankRow(
          rank: 8,
          name: 'Pooja Reddy',
          change: '- 3',
          location: 'Hyderabad',
          sport: 'Badminton',
          points: '2,420',
          wins: '40 Wins',
          imageUrl: 'https://picsum.photos/seed/user8/150/150',
          isVerified: true,
          isChangeNegative: true,
        ),
        _buildDivider(),
        _buildRankRow(
          rank: 9,
          name: 'Rohan Deshmukh',
          change: '-',
          location: 'Pune',
          sport: 'Cricket',
          points: '2,350',
          wins: '31 Wins',
          imageUrl: 'https://picsum.photos/seed/user9/150/150',
        ),
        _buildDivider(),
        _buildRankRow(
          rank: 10,
          name: 'Marcus Vance',
          change: '+ 1',
          location: 'Delhi NCR',
          sport: '14 Clean Sheets',
          sportColor: const Color(0xFFE5F5EB),
          sportTextColor: const Color(0xFF0F6D38),
          points: '2,280',
          wins: '29 Wins',
          imageUrl: 'https://picsum.photos/seed/user10/150/150',
          sportIcon: Icons.shield_outlined,
        ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F5F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'View All 500+ Ranked Players',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F6D38),
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF0F6D38),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(height: 1, color: Color(0xFFF3F4F6)),
    );
  }

  Widget _buildRankRow({
    required int rank,
    required String name,
    required String change,
    required String location,
    required String sport,
    required String points,
    required String wins,
    required String imageUrl,
    bool isVerified = false,
    bool isChangeNegative = false,
    Color? sportColor,
    Color? sportTextColor,
    IconData? sportIcon,
  }) {
    IconData defaultSportIcon = Icons.sports_soccer;
    if (sport == 'Cricket') defaultSportIcon = Icons.sports_cricket;
    if (sport == 'Badminton') defaultSportIcon = Icons.sports_tennis;

    Color changeColor = change == '-'
        ? Colors.grey
        : (isChangeNegative ? Colors.red : const Color(0xFF0F6D38));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              rank.toString(),
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (isVerified)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 14,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (change == '-')
                      const Text(
                        '—',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Row(
                        children: [
                          Icon(
                            isChangeNegative
                                ? Icons.arrow_drop_down
                                : Icons.arrow_drop_up,
                            color: changeColor,
                            size: 16,
                          ),
                          Text(
                            change.replaceAll(RegExp(r'[+-]\s'), ''),
                            style: TextStyle(
                              color: changeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      location,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '•',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: sportColor ?? Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            sportIcon ?? defaultSportIcon,
                            size: 10,
                            color: sportTextColor ?? Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sport,
                            style: TextStyle(
                              color: sportTextColor ?? Colors.grey[800],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                points,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                wins,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.stars, color: Color(0xFF0F6D38), size: 18),
                SizedBox(width: 8),
                Text(
                  'How Universal Points Work',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Earn points by winning official GAMES24 booked turf matches (+50 pts), scoring tournament MVPs (+120 pts), and maintaining clean play ratings. Seasons reset bi-monthly.',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoBadge(Colors.green[700]!, 'Turf Matches'),
                const SizedBox(width: 12),
                _buildInfoBadge(Colors.green[700]!, 'Verified Tournaments'),
                const SizedBox(width: 12),
                _buildInfoBadge(Colors.orange, 'Fair Play'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(Color color, String label) {
    return Row(
      children: [
        Icon(Icons.circle, size: 6, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
