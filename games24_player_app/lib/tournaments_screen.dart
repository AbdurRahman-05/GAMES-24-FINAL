import 'package:flutter/material.dart';
import 'package:games24_player_app/tournament_manager.dart';
import 'package:games24_player_app/tournament_details_screen.dart';
import 'package:games24_player_app/create_tournament_dialog.dart';

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
    _pinController.dispose();
    super.dispose();
  }

  void _onTournamentUpdate() {
    if (mounted) {
      if (_selectedTabIndex == 0 &&
          TournamentManager().ongoingTournaments.isEmpty &&
          TournamentManager().upcomingTournaments.isNotEmpty) {
        _selectedTabIndex = 1;
      }
      setState(() {}); // Rebuild when tournaments are added/registered
    }
  }

  final TextEditingController _pinController = TextEditingController();
  bool _isLookingUpPin = false;

  /// Private tournaments are hidden from the public list; players open them with the PIN the
  /// organizer shared.
  Future<void> _openPrivateTournament() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the access PIN shared by the organizer.')),
      );
      return;
    }
    setState(() => _isLookingUpPin = true);
    final result = await TournamentManager().findPrivateTournament(pin);
    if (!mounted) return;
    setState(() => _isLookingUpPin = false);
    final tournament = result.tournament;
    if (tournament == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text(result.error ?? 'No tournament found for this PIN.'),
        ),
      );
      return;
    }
    _pinController.clear();
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TournamentDetailsScreen(tournament: tournament)),
    );
  }

  Widget _buildPrivatePinCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: Color(0xFFD4FF00), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _pinController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1.2),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Have a private tournament PIN?',
                hintStyle: TextStyle(color: Color(0xFF71717A), fontSize: 13, letterSpacing: 0),
              ),
              onSubmitted: (_) => _openPrivateTournament(),
            ),
          ),
          TextButton(
            onPressed: _isLookingUpPin ? null : _openPrivateTournament,
            child: _isLookingUpPin
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4FF00)),
                  )
                : const Text('Open', style: TextStyle(color: Color(0xFFD4FF00), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final isPushRoute = widget.isStandalone || canPop;

    final Widget content = Material(
      color: const Color(0xFF080808),
      child: RefreshIndicator(
        color: const Color(0xFFD4FF00),
        backgroundColor: const Color(0xFF141414),
        onRefresh: () async {
          await TournamentManager().fetchTournaments();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSegmentedControl(),
                const SizedBox(height: 16),
                _buildPrivatePinCard(),
                const SizedBox(height: 20),
                _buildContent(),
                const SizedBox(height: 80), // padding for FAB
              ],
            ),
          ),
        ),
      ),
    );

    if (isPushRoute) {
      return Scaffold(
        backgroundColor: const Color(0xFF080808),
        appBar: AppBar(
          backgroundColor: const Color(0xFF080808),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFD4FF00),
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'Tournaments',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: content,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showCreateTournamentDialog(context);
          },
          backgroundColor: const Color(0xFFD4FF00),
          elevation: 4,
          icon: const Icon(Icons.add_rounded, color: Colors.black, size: 20),
          label: const Text(
            'Create Tournament',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
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
      subtitle =
          'Check the Upcoming tab to find and register for new tournaments.';
    } else if (_selectedTabIndex == 1) {
      title = 'No Upcoming Tournaments';
      subtitle =
          'New tournaments will appear here soon. Create one to get started!';
    } else if (_selectedTabIndex == 2) {
      title = 'No Registered Tournaments';
      subtitle =
          'You have not joined any tournaments yet. Join one or create your own!';
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
                color: const Color(0xFF141A0A),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4FF00).withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 48,
                color: Color(0xFFD4FF00),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFA1A1AA),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedTabIndex == 0 && TournamentManager().upcomingTournaments.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedTabIndex = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4FF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: Colors.black,
                ),
                label: const Text(
                  'Explore Upcoming Tournaments',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: Colors.black,
                  ),
                ),
              ),
            if (_selectedTabIndex == 1)
              ElevatedButton.icon(
                onPressed: () => showCreateTournamentDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4FF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: Colors.black,
                ),
                label: const Text(
                  'Create Tournament',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: Colors.black,
                  ),
                ),
              ),
            if (_selectedTabIndex == 2)
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _selectedTabIndex = 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4FF00),
                      side: const BorderSide(color: Color(0xFFD4FF00)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.explore_outlined, size: 18),
                    label: const Text(
                      'Browse Upcoming',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => showCreateTournamentDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4FF00),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'Create Tournament',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Colors.black,
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

  Widget _buildSegmentedControl() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF262626)),
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
        onTap: () {
          setState(() => _selectedTabIndex = index);
          if (index == 2) {
            TournamentManager().fetchTournaments();
          }
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4FF00) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4FF00).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : const Color(0xFFA1A1AA),
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentCard(Tournament tournament) {
    final bool isCancelled = tournament.status == TournamentStatus.cancelled;
    final bool isRegistered = TournamentManager().isUserRegistered(tournament);
    final bool isFull = tournament.registeredTeams >= tournament.maxTeams;

    String statusText = '';
    Color statusColor = Colors.white;
    Color statusTextColor = Colors.black87;

    if (tournament.status == TournamentStatus.ongoing) {
      statusText = 'Live Now';
      statusColor = const Color(0xFFDC2626);
      statusTextColor = Colors.white;
    } else if (isCancelled) {
      statusText = 'CANCELLED';
      statusColor = const Color(0xFFEF4444);
      statusTextColor = Colors.white;
    } else if (tournament.status == TournamentStatus.upcoming) {
      statusText = 'Upcoming';
      statusColor = Colors.white;
      statusTextColor = Colors.black87;
    } else {
      statusText = 'Completed';
      statusColor = const Color(0xFF71717A);
      statusTextColor = Colors.white;
    }

    String timeLabel = tournament.matchDay;
    if (tournament.status == TournamentStatus.upcoming || isCancelled) {
      timeLabel = tournament.date;
    }

    String statsLabel = 'Slots Left';
    String statsValue =
        '${tournament.maxTeams - tournament.registeredTeams} / ${tournament.maxTeams}';
    if (isCancelled) {
      statsLabel = 'Match Status';
      statsValue = 'Cancelled';
    } else if (tournament.status == TournamentStatus.ongoing) {
      statsLabel = 'Status';
      statsValue = tournament.tournamentProgress;
    }

    String buttonText = 'View Tournament';
    Color buttonBgColor = const Color(0xFFD4FF00);
    Color buttonTextColor = Colors.black;
    Color buttonBorderColor = Colors.transparent;
    IconData buttonIcon = Icons.arrow_forward_ios;

    if (isCancelled) {
      buttonBgColor = const Color(0xFF2C1515);
      buttonBorderColor = const Color(0xFFEF4444);
      buttonTextColor = const Color(0xFFFCA5A5);
      buttonIcon = Icons.block_rounded;
      buttonText = isRegistered
          ? 'Registered • Cancelled (View)'
          : 'Tournament Cancelled';
    } else if (isRegistered) {
      buttonBgColor = const Color(0xFF142918);
      buttonBorderColor = const Color(0xFF22C55E);
      buttonTextColor = const Color(0xFF86EFAC);
      buttonIcon = Icons.check_circle_rounded;
      buttonText = 'Registered • View Details';
    } else if (tournament.status == TournamentStatus.ongoing) {
      buttonText = 'View Live Standings';
      buttonIcon = Icons.play_circle_fill_rounded;
    } else if (tournament.status == TournamentStatus.upcoming) {
      buttonText = isFull ? 'Tournament Full (View)' : 'Register / Join Tournament';
    } else if (_selectedTabIndex == 2) {
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
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF262626)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
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
                          color: const Color(0xFFD4FF00),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tournament.sport,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
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
                      if (isRegistered) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isCancelled
                                ? const Color(0xFF7F1D1D)
                                : const Color(0xFF166534),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCancelled
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.8)
                                  : const Color(0xFF22C55E).withValues(alpha: 0.8),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCancelled
                                    ? Icons.cancel_outlined
                                    : Icons.check_circle_rounded,
                                color: isCancelled
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFF86EFAC),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCancelled
                                    ? 'Registration Cancelled'
                                    : 'Registered Team',
                                style: TextStyle(
                                  color: isCancelled
                                      ? const Color(0xFFFCA5A5)
                                      : const Color(0xFF86EFAC),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: tournament.isOwnerCreated
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141F0A).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD4FF00), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4FF00).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 13, color: Color(0xFFD4FF00)),
                              SizedBox(width: 4),
                              Text(
                                'TURF OWNER',
                                style: TextStyle(
                                  color: Color(0xFFD4FF00),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF3F3F46), width: 1.0),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.groups_rounded, size: 12, color: Color(0xFFA1A1AA)),
                              SizedBox(width: 4),
                              Text(
                                'COMMUNITY',
                                style: TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 130,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tournament.isVenueTBA
                            ? 'Venue Details Launching Soon (TBA)'
                            : (tournament.courtAllocation != null &&
                                    tournament.courtAllocation!.isNotEmpty &&
                                    tournament.courtAllocation != tournament.venue)
                                ? '${tournament.venue} (${tournament.courtAllocation}), ${tournament.location}'
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
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2E2E2E)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF141A0A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFD4FF00),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prize Pool',
                              style: TextStyle(
                                color: Color(0xFFA1A1AA),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tournament.prizePool,
                              style: const TextStyle(
                                color: Color(0xFFD4FF00),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
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
                                color: Color(0xFFA1A1AA),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statsValue,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isCancelled) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C1515),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tournament cancelled by host turf. Tap to view status & organizer contact for refund.',
                              style: TextStyle(
                                color: Color(0xFFFCA5A5),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                        backgroundColor: buttonBgColor,
                        foregroundColor: buttonTextColor,
                        elevation: 0,
                        side: buttonBorderColor != Colors.transparent
                            ? BorderSide(color: buttonBorderColor, width: 1.2)
                            : BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            buttonIcon,
                            size: 16,
                            color: buttonTextColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            buttonText,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: buttonTextColor,
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
