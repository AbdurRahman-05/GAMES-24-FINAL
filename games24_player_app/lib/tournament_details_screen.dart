import 'main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:games24_player_app/tournament_manager.dart';
import 'package:games24_player_app/tournament_registration_screen.dart';

class TournamentDetailsScreen extends StatelessWidget {
  final Tournament tournament;

  const TournamentDetailsScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
        title: Text(
          tournament.title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroImage(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFinancials(),
                  if (tournament.externalTicketUrl != null && tournament.externalTicketUrl!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildExternalTicketCard(context),
                  ],
                  const SizedBox(height: 24),
                  _buildRules(),
                  const SizedBox(height: 24),
                  _buildRegistrationInfo(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(tournament.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.bottomLeft,
        child: Text(
          tournament.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tournament.status == TournamentStatus.ongoing
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tournament.status == TournamentStatus.ongoing
                    ? 'Live Now'
                    : (tournament.status == TournamentStatus.upcoming
                          ? 'Upcoming'
                          : 'Completed'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _detailRow(Icons.calendar_today, 'Date', tournament.date),
        _detailRow(Icons.access_time, 'Time', tournament.time),
        if (tournament.isVenueTBA)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: const [
                Icon(Icons.location_searching_rounded, color: Color(0xFFD97706), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Venue Details Launching Soon (TBA)\nExact arena and court schedule will be announced closer to kickoff.',
                    style: TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
              ],
            ),
          )
        else
          _detailRow(
            Icons.location_on,
            'Venue',
            '${tournament.venue}, ${tournament.location}',
          ),
        if (tournament.courtsCount > 0)
          _detailRow(Icons.stadium_rounded, 'Facilities', '${tournament.courtsCount} Dedicated Courts / Pitches Allocated'),
        _detailRow(Icons.sports, 'Format', tournament.format),
      ],
    );
  }

  Widget _buildFinancials() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial & Prize Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _financeItem(
                'Entry Fee',
                tournament.entryFee,
                Icons.monetization_on,
              ),
              _financeItem(
                'Prize Pool',
                tournament.prizePool,
                Icons.emoji_events,
              ),
              _financeItem('Grand Prize', tournament.grandPrize, Icons.star),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExternalTicketCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.confirmation_number_rounded, color: Color(0xFF154D36), size: 18),
              SizedBox(width: 8),
              Text(
                'External Ticket / Registration Pass',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF154D36)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'The tournament organizer provided an external registration/pass URL:',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tournament.externalTicketUrl ?? '',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF154D36)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF154D36)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: tournament.externalTicketUrl ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ticket link copied to clipboard! 📋'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _financeItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF154D36), size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRules() {
    final rulesList = tournament.rules;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rules & Guidelines 📜',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _ruleItem('Reporting Time', tournament.reportingTime),
        if (rulesList.isNotEmpty)
          ...rulesList.map((r) => _ruleCheckItem(r))
        else ...[
          _ruleItem(
            'Equipment',
            'Standard kits required. Non-marking shoes mandatory for indoor.',
          ),
          _ruleItem(
            'Match Rules',
            'Referee decisions are final. Yellow/Red card penalties apply.',
          ),
        ],
      ],
    );
  }

  Widget _ruleCheckItem(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF154D36), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rule,
              style: const TextStyle(color: Color(0xFF374151), fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF154D36), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF374151), fontSize: 13),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registration Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${tournament.registeredTeams} / ${tournament.maxTeams} Teams Registered',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
          CircularProgressIndicator(
            value: tournament.registeredTeams / tournament.maxTeams,
            backgroundColor: Colors.white,
            color: const Color(0xFF154D36),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    if (tournament.status == TournamentStatus.upcoming) {
      bool isFull = tournament.registeredTeams >= tournament.maxTeams;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isFull
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TournamentRegistrationScreen(
                          tournament: tournament,
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF154D36),
              disabledBackgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isFull ? 'Tournament Full' : 'Register / Join Tournament',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live Standings coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF154D36),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'View Live Standings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }
  }
}
