import 'main_layout.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:games24_player_app/tournament_manager.dart';

class TournamentRegistrationScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentRegistrationScreen({super.key, required this.tournament});

  @override
  State<TournamentRegistrationScreen> createState() =>
      _TournamentRegistrationScreenState();
}

class _TournamentRegistrationScreenState
    extends State<TournamentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameCtrl = TextEditingController();
  final _captainNameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _playersCountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserPrefills();
  }

  Future<void> _loadUserPrefills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = (prefs.getString('mobileNumber') ?? '').trim();
      final name = (prefs.getString('fullName') ?? prefs.getString('userName') ?? '').trim();
      final email = (prefs.getString('email') ?? '').trim();
      if (mounted) {
        if (phone.isNotEmpty && _contactCtrl.text.isEmpty) _contactCtrl.text = phone;
        if (name.isNotEmpty && _captainNameCtrl.text.isEmpty) _captainNameCtrl.text = name;
        if (email.isNotEmpty && _emailCtrl.text.isEmpty) _emailCtrl.text = email;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    _captainNameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _playersCountCtrl.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    if (_formKey.currentState!.validate()) {
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: const Color(0xFF181818),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF262626)),
          ),
          title: const Text(
            'Confirm Registration',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogRow('Tournament', widget.tournament.title),
              _dialogRow('Team', _teamNameCtrl.text),
              _dialogRow('Players', _playersCountCtrl.text),
              _dialogRow('Entry Fee', widget.tournament.entryFee),
              _dialogRow('Venue', widget.tournament.venue),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFA1A1AA))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop(); // close dialog

                final success = await TournamentManager()
                    .registerTeam(widget.tournament.id, {
                      'teamName': _teamNameCtrl.text.trim(),
                      'captainName': _captainNameCtrl.text.trim(),
                      'contact': _contactCtrl.text.trim(),
                      'email': _emailCtrl.text.trim(),
                      'playersCount': _playersCountCtrl.text.trim(),
                    });

                if (success) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Registration Successful! 🏆',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: const Color(0xFF141414),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFD4FF00)),
                      ),
                    ),
                  );
                  nav.pop(); // close registration screen
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Registration Failed. Tournament might be full or team name exists.',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF141414),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4FF00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
        title: const Text(
          'Register for Tournament',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTournamentSummary(),
            const SizedBox(height: 24),
            const Text(
              'Team Registration Form',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildForm(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          border: const Border(
            top: BorderSide(color: Color(0xFF262626)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _submitRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4FF00),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shadowColor: const Color(0xFFD4FF00).withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirm Registration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.tournament.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          _summaryRow(Icons.sports_soccer, 'Sport', widget.tournament.sport),
          _summaryRow(Icons.calendar_today, 'Date', widget.tournament.date),
          _summaryRow(Icons.access_time, 'Time', widget.tournament.time),
          _summaryRow(Icons.location_on, 'Venue', widget.tournament.venue),
          _summaryRow(
            Icons.monetization_on,
            'Entry Fee',
            widget.tournament.entryFee,
          ),
          _summaryRow(
            Icons.emoji_events,
            'Prize Pool',
            widget.tournament.prizePool,
          ),
          _summaryRow(
            Icons.group,
            'Available Slots',
            '${widget.tournament.maxTeams - widget.tournament.registeredTeams} / ${widget.tournament.maxTeams}',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFD4FF00)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _teamNameCtrl,
            label: 'Team Name',
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter team name'
                : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _captainNameCtrl,
            label: 'Captain Name',
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter captain name'
                : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _contactCtrl,
            label: 'Contact Number',
            keyboardType: TextInputType.phone,
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter contact number'
                : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailCtrl,
            label: 'Email Address',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter email address';
              }
              if (!value.contains('@')) return 'Please enter valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _playersCountCtrl,
            label: 'Number of Players',
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter number of players'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
        floatingLabelStyle: const TextStyle(color: Color(0xFFD4FF00), fontWeight: FontWeight.bold),
        filled: true,
        fillColor: const Color(0xFF141414),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF262626)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF262626)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4FF00), width: 1.5),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
    );
  }
}
