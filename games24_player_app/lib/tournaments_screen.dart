import 'package:flutter/material.dart';
import 'package:games24_player_app/tournament_manager.dart';
import 'package:games24_player_app/tournament_details_screen.dart';

class TournamentsScreen extends StatefulWidget {
  final bool isStandalone;
  const TournamentsScreen({super.key, this.isStandalone = false});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    TournamentManager().addListener(_onTournamentUpdate);
    TournamentManager().fetchTournaments();
  }

  @override
  void dispose() {
    TournamentManager().removeListener(_onTournamentUpdate);
    super.dispose();
  }

  void _onTournamentUpdate() {
    setState(() {}); // Rebuild when tournaments are added/registered
  }

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final isPushRoute = widget.isStandalone || canPop;

    final Widget content = Material(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSegmentedControl(),
              const SizedBox(height: 24),
              _buildContent(),
              const SizedBox(height: 80), // padding for FAB
            ],
          ),
        ),
      ),
    );

    if (isPushRoute) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF154D36)),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'Tournaments',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: content,
      );
    }

    return content;
  }

  Widget _buildContent() {
    List<Tournament> displayList = [];
    if (_selectedTabIndex == 0) {
      displayList = TournamentManager().ongoingTournaments;
    } else if (_selectedTabIndex == 1) {
      displayList = TournamentManager().upcomingTournaments;
    } else {
      displayList = TournamentManager().myTournaments;
    }

    if (displayList.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: displayList
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _buildTournamentCard(t),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyState() {
    String title = 'No tournaments yet';
    String subtitle = 'Check out upcoming tournaments to participate!';
    if (_selectedTabIndex == 0) {
      title = 'No Live Tournaments Running';
      subtitle = 'Check the Upcoming tab to find and register for new tournaments.';
    } else if (_selectedTabIndex == 1) {
      title = 'No Upcoming Tournaments';
      subtitle = 'New tournaments will appear here soon. Create one to get started!';
    } else if (_selectedTabIndex == 2) {
      title = 'No Registered Tournaments';
      subtitle = 'You have not joined any tournaments yet. Join one or create your own!';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 48,
                color: Color(0xFF154D36),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedTabIndex == 2)
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedTabIndex = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF154D36),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.explore_outlined, size: 18),
                label: const Text(
                  'Explore Upcoming Tournaments',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
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
          _buildSegmentTab('My Tournaments', 2),
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
            color: isSelected ? const Color(0xFF154D36) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentCard(Tournament tournament) {
    String statusText = '';
    Color statusColor = Colors.white;
    Color statusTextColor = Colors.black87;

    if (tournament.status == TournamentStatus.ongoing) {
      statusText = 'Live Now';
      statusColor = const Color(0xFFDC2626);
      statusTextColor = Colors.white;
    } else if (tournament.status == TournamentStatus.upcoming) {
      statusText = 'Upcoming';
    } else {
      statusText = 'Completed';
    }

    String timeLabel = tournament.matchDay;
    if (tournament.status == TournamentStatus.upcoming) {
      timeLabel = tournament.date;
    }

    String statsLabel = 'Slots Left';
    String statsValue =
        '${tournament.maxTeams - tournament.registeredTeams} / ${tournament.maxTeams}';
    if (tournament.status == TournamentStatus.ongoing) {
      statsLabel = 'Status';
      statsValue = tournament.tournamentProgress;
    }

    String buttonText = 'View Tournament';
    if (tournament.status == TournamentStatus.ongoing) {
      buttonText = 'View Live Standings';
    } else if (tournament.status == TournamentStatus.upcoming) {
      buttonText = 'Register / Join Tournament';
    }
    if (_selectedTabIndex == 2) {
      buttonText = 'View Details';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TournamentDetailsScreen(tournament: tournament),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A0F172A),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image Header
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    tournament.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF154D36),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tournament.sport,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tournament.isVenueTBA
                            ? 'Venue Details Launching Soon (TBA)'
                            : '${tournament.venue}, ${tournament.location}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 14,
                        ),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0FDF4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events_outlined,
                            color: Color(0xFF154D36),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                              tournament.prizePool,
                              style: const TextStyle(
                                color: Color(0xFF154D36),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
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
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TournamentDetailsScreen(tournament: tournament),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154D36),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_forward_ios, size: 16),
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
      ),
    );
  }
}
