import 'main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tournament_form_data.dart';
import 'tournament_manager.dart';

class CreatePrivateTournamentStep2Screen extends StatefulWidget {
  final TournamentFormData formData;

  const CreatePrivateTournamentStep2Screen({
    super.key,
    required this.formData,
  });

  @override
  State<CreatePrivateTournamentStep2Screen> createState() =>
      _CreatePrivateTournamentStep2ScreenState();
}

class _CreatePrivateTournamentStep2ScreenState
    extends State<CreatePrivateTournamentStep2Screen> {
  bool _agreedToTerms = true;
  bool _isPublishing = false;

  void _copyPin() {
    Clipboard.setData(ClipboardData(text: widget.formData.accessCode));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text('Access PIN "${widget.formData.accessCode}" copied to clipboard! 📋'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _publishPrivateTournament() async {
    if (!_agreedToTerms) return;

    setState(() => _isPublishing = true);
    HapticFeedback.heavyImpact();

    await Future.delayed(const Duration(milliseconds: 400));

    final newTourney = widget.formData.toTournament();
    TournamentManager().addTournament(newTourney);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF166534),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.lock_open_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Private Tournament "${newTourney.title}" Created! PIN: ${widget.formData.accessCode} 🔒',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
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
      backgroundColor: const Color(0xFFF8FAFC),
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
              'Review Private Tournament',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Step 2 of 2 • Invite-Only Cup',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            color: const Color(0xFFD97706), // Amber-gold for private
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Private Championship Ticket Preview
            _buildPrivatePassPreview(d),
            const SizedBox(height: 16),

            // Share Access PIN Callout Card
            _buildAccessPinCard(d),
            const SizedBox(height: 16),

            // Tournament Parameters Card
            _buildDetailsCard(d),
            const SizedBox(height: 16),

            // Venue & Schedule Card
            _buildVenueCard(d),
            const SizedBox(height: 16),

            // Rules & Guidelines Card
            if (d.rules.isNotEmpty || d.customRules.isNotEmpty)
              _buildRulesCard(d),
            if (d.rules.isNotEmpty || d.customRules.isNotEmpty)
              const SizedBox(height: 16),

            // Host Guarantee & Terms
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
                      label: const Text('Edit Setup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                        backgroundColor: const Color(0xFF0F172A), // Dark navy slate for private
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
                          : const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFFFDE68A)),
                      label: Text(
                        _isPublishing ? 'Launching...' : 'Create Private Cup 🚀',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      onPressed: (_agreedToTerms && !_isPublishing) ? _publishPrivateTournament : null,
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

  Widget _buildPrivatePassPreview(TournamentFormData d) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tags
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock_rounded, color: Color(0xFFB45309), size: 13),
                    SizedBox(width: 5),
                    Text(
                      'PRIVATE INVITATIONAL',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${d.sport} • ${d.format}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            d.title.isNotEmpty ? d.title : 'Private Tournament',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),

          // Location & Date
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFFDE68A)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${d.venue}, ${d.location}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFFFDE68A)),
              const SizedBox(width: 6),
              Text(
                '${d.date} • ${d.time}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 16),

          // Prize Pool and Entry Fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRIZE POOL 🏆', style: TextStyle(color: Color(0xFFFDE68A), fontSize: 10.5, fontWeight: FontWeight.bold)),
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

  Widget _buildAccessPinCard(TournamentFormData d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.key_rounded, color: Color(0xFFD97706), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tournament Access PIN 🔑',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 2),
                Text(
                  d.accessCode.isNotEmpty ? d.accessCode : 'SECURE-PIN',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Color(0xFF78350F),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Share this PIN only with invited teams to enter bracket.',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.copy_rounded, size: 14),
            label: const Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: _copyPin,
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
          const Text('Private Cup Rules 📋', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          _buildParamRow('Sport Discipline', d.sport, Icons.sports_rounded),
          const Divider(height: 16),
          _buildParamRow('Cup Structure', d.format, Icons.schema_rounded),
          const Divider(height: 16),
          _buildParamRow('Max Capacity', '${d.maxTeams} Teams (Invite Only)', Icons.groups_rounded),
          const Divider(height: 16),
          _buildParamRow('Security Level', 'Private / PIN Protected', Icons.security_rounded),
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
              Icon(Icons.stadium_rounded, color: Color(0xFFD97706), size: 18),
              SizedBox(width: 8),
              Text('Reserved Court Venue 🏟️', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          Text(d.venue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(d.location, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Text('Kickoff: ${d.date} • ${d.time}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
              Icon(Icons.gavel_rounded, color: Color(0xFFD97706), size: 18),
              SizedBox(width: 8),
              Text('Match Guidelines & Conduct ⚖️', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          ...d.rules.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFFD97706), size: 15),
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
            activeColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'I confirm that this private tournament is organized for invited teams only, and I agree to the GAMES24 Host Guidelines.',
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
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }
}
