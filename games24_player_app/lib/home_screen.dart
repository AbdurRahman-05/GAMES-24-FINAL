import 'package:flutter/material.dart';
import 'package:games24_player_app/booking_screen.dart';
import 'package:games24_player_app/challenge_manager.dart';class HomeScreen extends StatefulWidget {
  final VoidCallback? onExploreTap;

  const HomeScreen({super.key, this.onExploreTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSearchBar(),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSectionHeader('Categories', ''),
          ),
          const SizedBox(height: 16),
          _buildCategories(),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSectionHeader('Upcoming Matches', 'View Schedule', hasLiveBadge: true),
          ),
          const SizedBox(height: 16),
          _buildUpcomingMatches(),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSectionHeader('Your Active Bookings', 'History'),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildActiveBookings(),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSectionHeader('Join Team / Open Challenges', 'View All'),
          ),
          const SizedBox(height: 16),
          _buildOpenChallenges(),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSectionHeader(
              'Nearby Turfs',
              'See all',
              trailingIcon: Icons.near_me_outlined,
              onActionTap: widget.onExploreTap,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildNearbyTurfs(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.search, color: Color(0xFF6B7280)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search turfs, matches, or sports...',
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF166534),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.tune, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String actionText, {bool hasLiveBadge = false, IconData? trailingIcon, VoidCallback? onActionTap}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        if (hasLiveBadge) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF166534),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Live',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const Spacer(),
        GestureDetector(
          onTap: onActionTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              if (trailingIcon != null) ...[
                Icon(trailingIcon, size: 14, color: const Color(0xFF166534)),
                const SizedBox(width: 4),
              ],
              if (actionText.isNotEmpty)
                Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'name': 'Football', 'icon': Icons.sports_soccer, 'isSelected': true},
      {'name': 'Cricket', 'icon': Icons.sports_cricket, 'isSelected': false},
      {'name': 'Tennis', 'icon': Icons.sports_tennis, 'isSelected': false},
      {'name': 'Basketball', 'icon': Icons.sports_basketball, 'isSelected': false},
      {'name': 'Go-Kart', 'icon': Icons.directions_car, 'isSelected': false},
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat['isSelected'] as bool;
          return Container(
            width: 88,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF166534) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: isSelected ? null : Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  cat['name'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4B5563),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingMatches() {
    final matches = [
      {
        'time': 'Today, 7:00 PM',
        'slots': '5 slots left',
        't1Initials': 'FC',
        't1Name': 'Strikers',
        't1Color': const Color(0xFF166534),
        't2Initials': 'UN',
        't2Name': 'United',
        't2Color': const Color(0xFFBE123C),
        'location': 'Elite Arena, Turf 2',
      },
      {
        'time': 'Tomorrow, 6:00 PM',
        'slots': '2 slots left',
        't1Initials': 'KN',
        't1Name': 'Knights',
        't1Color': Colors.blue.shade800,
        't2Initials': 'TI',
        't2Name': 'Titans',
        't2Color': Colors.orange.shade800,
        'location': 'City Sports Club, Turf 1',
      },
    ];

    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: matches.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final match = matches[index];
          return Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        match['time'] as String,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                      ),
                    ),
                    Text(
                      match['slots'] as String,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTeamAvatar(match['t1Initials'] as String, match['t1Name'] as String, match['t1Color'] as Color),
                    const SizedBox(width: 16),
                    const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 16),
                    _buildTeamAvatar(match['t2Initials'] as String, match['t2Name'] as String, match['t2Color'] as Color),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      match['location'] as String,
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF166534),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Join', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeamAvatar(String initials, String name, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 10, color: Color(0xFF111827))),
      ],
    );
  }

  Widget _buildActiveBookings() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://picsum.photos/seed/booking/250/250',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Green Valley Arena',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Confirmed',
                        style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Today, 5:00 PM - 6:30 PM',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    const Text('Turf 1 (5v5)', style: TextStyle(fontSize: 12, color: Color(0xFF111827))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenChallenges() {
    return ValueListenableBuilder<List<Challenge>>(
      valueListenable: ChallengeManager().challengesNotifier,
      builder: (context, challenges, child) {
        if (challenges.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('No open challenges available.'),
          );
        }
        return SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: challenges.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildChallengeCard(challenges[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF166534).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  challenge.sport,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                ),
              ),
              Text(
                '${challenge.date}, ${challenge.time}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTeamAvatar(challenge.challengerTeamInitials, challenge.challengerName, challenge.challengerColor),
              const SizedBox(width: 16),
              const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 16),
              if (challenge.isJoined)
                _buildTeamAvatar(
                  challenge.opponentName != null && challenge.opponentName!.length >= 2 
                      ? challenge.opponentName!.substring(0, 2).toUpperCase() 
                      : 'VS', 
                  challenge.opponentName ?? 'Opponent', 
                  const Color(0xFFBE123C)
                )
              else
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid),
                      ),
                      child: const Center(
                        child: Icon(Icons.help_outline, color: Color(0xFF9CA3AF), size: 20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Open Slot', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                  ],
                ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  challenge.turfName,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (challenge.isJoined)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Matched', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else if (challenge.isCreator)
                GestureDetector(
                  onTap: () {
                    if (challenge.joinRequests.isNotEmpty) {
                      _showRequestsDialog(challenge);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No requests yet.')));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: challenge.joinRequests.isNotEmpty ? const Color(0xFFBE123C) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      challenge.joinRequests.isNotEmpty ? '${challenge.joinRequests.length} Requests' : 'Waiting',
                      style: TextStyle(
                        color: challenge.joinRequests.isNotEmpty ? Colors.white : Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (challenge.userHasRequested)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Requested', style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else
                GestureDetector(
                  onTap: () {
                    _showJoinChallengeDialog(challenge);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF166534),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Join', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showJoinChallengeDialog(Challenge challenge) {
    final teamNameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Join Challenge'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: teamNameCtrl,
                decoration: const InputDecoration(labelText: 'Your Team Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: 'Contact Details (Phone/Email)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (teamNameCtrl.text.trim().isEmpty || contactCtrl.text.trim().isEmpty) return;
                ChallengeManager().requestToJoin(
                  challenge.id,
                  teamNameCtrl.text.trim(),
                  contactCtrl.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Join request sent!')));
              },
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );
  }

  void _showRequestsDialog(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Join Requests'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: challenge.joinRequests.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final req = challenge.joinRequests[index];
                return ListTile(
                  title: Text(req.teamName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Contact: ${req.contactDetails}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () {
                          ChallengeManager().acceptRequest(challenge.id, req);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Accepted ${req.teamName}!')));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          ChallengeManager().rejectRequest(challenge.id, req.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected.')));
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNearbyTurfs() {
    return Column(
      children: [
        _buildTurfCard(
          name: 'Apex Sports Club',
          price: '₹1,200',
          location: 'Koramangala • 1.2 km away',
          imageUrl: 'https://picsum.photos/seed/turf1/800/400',
          rating: '4.9',
          reviews: '128',
          sports: 'Football • Cricket',
          tags: ['Floodlights', 'Parking', 'Changing Room'],
        ),
        const SizedBox(height: 20),
        _buildTurfCard(
          name: 'Metro Arena Indoor',
          price: '₹950',
          location: 'Indiranagar • 2.5 km away',
          imageUrl: 'https://picsum.photos/seed/turf2/800/400', // badminton
          rating: '4.7',
          reviews: '94',
          sports: 'Badminton • Tennis',
          tags: ['Indoor AC', 'Cafeteria'],
        ),
      ],
    );
  }

  Widget _buildTurfCard({
    required String name,
    required String price,
    required String location,
    required String imageUrl,
    required String rating,
    required String reviews,
    required String sports,
    required List<String> tags,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        ' ($reviews)',
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    sports,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      price,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Text(location, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                    const Text('/ hour', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF4B5563)),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingScreen(
                              turfName: name,
                              imageUrl: imageUrl,
                              price: price,
                              location: location,
                              sports: sports.split(' • '), // Convert string to list
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF166534),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Book Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
}
