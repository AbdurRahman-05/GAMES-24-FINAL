import 'main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tournament_form_data.dart';
import 'tournament_manager.dart';

class CreatePublicTournamentStep2Screen extends StatefulWidget {
  final TournamentFormData formData;

  const CreatePublicTournamentStep2Screen({
    super.key,
    required this.formData,
  });

  @override
  State<CreatePublicTournamentStep2Screen> createState() =>
      _CreatePublicTournamentStep2ScreenState();
}

class _CreatePublicTournamentStep2ScreenState
    extends State<CreatePublicTournamentStep2Screen> {
  bool _agreedToTerms = true;
  bool _isPublishing = false;

  void _publishTournament() async {
    if (!_agreedToTerms) return;

    setState(() => _isPublishing = true);
    HapticFeedback.heavyImpact();

    final prefs = await SharedPreferences.getInstance();
    final userPhone = (prefs.getString('mobileNumber') ?? '').trim();
    final userName = (prefs.getString('fullName') ?? prefs.getString('userName') ?? 'Gamez24 Player').trim();
    final backendPayload = widget.formData.toBackendJson(
      organizerName: userName.isNotEmpty ? userName : 'Gamez24 Player',
      organizerPhone: userPhone.isNotEmpty ? userPhone : '9876543210',
    );
    final success = await TournamentManager().createTournamentInBackend(backendPayload);

    if (!success) {
      // Fallback: also ensure local entry exists
      final newTourney = widget.formData.toTournament();
      TournamentManager().addTournament(newTourney);
    }

    if (mounted) {
      final tournamentTitle = widget.formData.title.trim().isNotEmpty
          ? widget.formData.title.trim()
          : 'City Championship 2026';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF166534),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.celebration_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tournament "$tournamentTitle" Published Successfully! 🏆',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Return back to Tournaments screen
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.formData;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Review & Launch',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Step 2 of 2 • Public Tournament',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            color: const Color(0xFF166534), // 100% complete
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Championship Ticket Preview
            _buildTournamentPassPreview(d),
            const SizedBox(height: 20),

            // Financial & Format Breakdown
            _buildDetailsCard(d),
            const SizedBox(height: 16),

            // Venue & Facilities Card
            _buildVenueCard(d),
            const SizedBox(height: 16),

            // Rules & Guidelines Card
            if (d.rules.isNotEmpty || d.customRules.isNotEmpty)
              _buildRulesCard(d),
            if (d.rules.isNotEmpty || d.customRules.isNotEmpty)
              const SizedBox(height: 16),

            // Terms & Host Guarantee
            _buildTermsCard(),
            const SizedBox(height: 24),

            // Bottom Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF166534),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isPublishing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.rocket_launch_rounded, size: 18, color: Color(0xFF86EFAC)),
                      label: Text(
                        _isPublishing ? 'Publishing...' : 'Launch Tournament 🚀',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      onPressed: (_agreedToTerms && !_isPublishing) ? _publishTournament : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentPassPreview(TournamentFormData d) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B),
        image: d.imageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(d.imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.65),
                  BlendMode.darken,
                ),
              )
            : null,
        gradient: d.imageUrl.isEmpty
            ? const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF065F46)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF065F46).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Tags (Responsive wrap prevents overflow on all mobile widths)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.public_rounded, color: Colors.white, size: 13),
                    SizedBox(width: 5),
                    Text(
                      'PUBLIC CHAMPIONSHIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE68A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${d.sport} • ${d.format}',
                    style: const TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            d.title.isNotEmpty ? d.title : 'City Championship 2026',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),

          // Location & Date Rows
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF86EFAC)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  d.isVenueTBA ? '📍 Venue Details Launching Soon (TBA)' : '${d.venue}, ${d.location}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF86EFAC)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${d.date} • ${d.time}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Divider dash
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),

          // Prize Pool and Entry Fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRIZE POOL 🏆', style: TextStyle(color: Color(0xFF86EFAC), fontSize: 10.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    d.prizePool.isNotEmpty ? d.prizePool : '₹10,000 + Trophy',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('ENTRY FEE 🎟️', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    d.entryFee.isNotEmpty ? d.entryFee : 'Free Entry',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(TournamentFormData d) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tournament Parameters 📋', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          _buildParamRow('Sport Category', d.sport, Icons.sports_rounded),
          const Divider(height: 16),
          _buildParamRow('Match Format', d.format, Icons.schema_rounded),
          const Divider(height: 16),
          _buildParamRow('Max Capacity', '${d.maxTeams} Teams Knockout', Icons.groups_rounded),
          const Divider(height: 16),
          _buildParamRow('Discovery Status', 'Public (Open to all)', Icons.public_rounded),
          if (d.courtsCount > 0) ...[
            const Divider(height: 16),
            _buildParamRow('Turf Facilities', '${d.courtsCount} Courts / Pitches', Icons.stadium_rounded),
          ],
          if (d.externalTicketUrl.isNotEmpty) ...[
            const Divider(height: 16),
            _buildParamRow('External Ticket Link', d.externalTicketUrl, Icons.confirmation_number_outlined),
          ],
        ],
      ),
    );
  }

  Widget _buildVenueCard(TournamentFormData d) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.stadium_rounded, color: Color(0xFF166534), size: 18),
              SizedBox(width: 8),
              Text('Venue & Court Schedule 🏟️', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          if (d.isVenueTBA) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Venue Details Launching Soon (TBA) — Exact turf & court arena will be announced prior to kickoff.',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(d.venue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(d.location, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          if (d.courtsCount > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.grid_view_rounded, size: 13, color: Color(0xFF166534)),
                const SizedBox(width: 6),
                Text('${d.courtsCount} Dedicated Courts / Pitches', style: const TextStyle(fontSize: 11.5, color: Color(0xFF166534), fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF166534)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Schedule: ${d.date} • ${d.time}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard(TournamentFormData d) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.gavel_rounded, color: Color(0xFF166534), size: 18),
              SizedBox(width: 8),
              Text('Rules & Organizer Guidelines ⚖️', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          ...d.rules.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF166534), size: 15),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                  ],
                ),
              )),
          if (d.customRules.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                'Note: ${d.customRules}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTermsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _agreedToTerms,
            activeColor: const Color(0xFF166534),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'I confirm that the venue booking is reserved for this tournament date, and I agree to abide by GAMEZ24 Tournament Organizer Policies.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: _agreedToTerms ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
