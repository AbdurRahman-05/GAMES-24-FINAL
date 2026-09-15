import 'package:flutter/material.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSegmentedControl(),
            const SizedBox(height: 24),
            _buildTournamentCard(
              sport: 'Football',
              status: 'Live Now',
              title: 'City Apex Super Cup 2024',
              location: 'Grand Royale Turf, Sector 4',
              timeLabel: 'Day 2 of 4',
              prizeValue: '\$5,000 + Trophy',
              statsLabel: 'Slots Left',
              statsValue: '2 / 16 Teams',
              imageUrl: 'https://picsum.photos/seed/tourn1/800/400',
              buttonText: 'View Live Standings',
            ),
            const SizedBox(height: 20),
            _buildTournamentCard(
              sport: 'Cricket Box',
              status: 'Quarter Finals',
              title: 'Weekend Box Cricket League',
              location: 'Urban Arena, Downtown',
              timeLabel: 'Match 12/15',
              prizeValue: '\$2,500',
              statsLabel: 'Status',
              statsValue: 'Knockouts',
              imageUrl: 'https://picsum.photos/seed/tourn2/800/400',
              buttonText: 'View Live Standings',
            ),
            const SizedBox(height: 80), // padding for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F1), // Light green-grey
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegmentTab('Ongoing', 0),
          _buildSegmentTab('Upcoming', 1),
          _buildSegmentTab('My\nTournaments', 2),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F6D38) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentCard({
    required String sport,
    required String status,
    required String title,
    required String location,
    required String timeLabel,
    required String prizeValue,
    required String statsLabel,
    required String statsValue,
    required String imageUrl,
    required String buttonText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F9F3), // Very light green tint
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Image Header
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              // Top Badges
              Positioned(
                top: 16,
                left: 16,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F6D38),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        sport,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom Text (Title & Location)
              Positioned(
                bottom: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom Right Time Badge
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Stats & Action Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // White Stats Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Trophy Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events_outlined,
                          color: Color(0xFF0F6D38),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Prize Pool Texts
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prize Pool',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            prizeValue,
                            style: const TextStyle(
                              color: Color(0xFF0F6D38),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Slots / Status Texts
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            statsLabel,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statsValue,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F6D38),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.remove_red_eye_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
