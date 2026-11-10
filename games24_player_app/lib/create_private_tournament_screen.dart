import 'main_layout.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tournament_form_data.dart';
import 'create_private_tournament_step2_screen.dart';

class CreatePrivateTournamentScreen extends StatefulWidget {
  const CreatePrivateTournamentScreen({super.key});

  @override
  State<CreatePrivateTournamentScreen> createState() =>
      _CreatePrivateTournamentScreenState();
}

class _CreatePrivateTournamentScreenState
    extends State<CreatePrivateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _prizeController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _customRulesController = TextEditingController();

  // Sports & Format
  String _selectedSport = 'Football';
  String _selectedFormat = 'Single Elimination Knockout';
  int _maxTeams = 8;

  // Schedule & Venue
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 5));
  String _selectedTimeSlot = '06:00 PM - 10:00 PM';
  String _selectedVenue = '';
  String _selectedLocation = '';

  // Toggleable Rules
  final Map<String, bool> _rulesMap = {
    'Strict invite-only: Valid access PIN required': true,
    'Teams must report 15 mins prior to kickoff': true,
    'Standard turf cleats and matching team jerseys': true,
    'Rolling substitutions allowed with referee approval': true,
    'Host organizer decisions are binding': true,
  };

  final List<Map<String, dynamic>> _sportsList = [
    {'name': 'Football', 'icon': Icons.sports_soccer_rounded},
    {'name': 'Cricket', 'icon': Icons.sports_cricket_rounded},
    {'name': 'Badminton', 'icon': Icons.sports_tennis_rounded},
    {'name': 'Pickleball', 'icon': Icons.sports_baseball_rounded},
    {'name': 'Tennis', 'icon': Icons.sports_tennis_outlined},
    {'name': 'Volleyball', 'icon': Icons.sports_volleyball_rounded},
  ];

  final List<String> _formatsList = [
    'Single Elimination Knockout',
    'Round Robin (Points Table)',
    'Group Stage + Knockout',
  ];

  final List<Map<String, String>> _turfVenues = [
    {'venue': 'Grand Arena Turf', 'loc': 'Downtown Sports Complex, Madurai'},
    {'venue': 'Madurai Turf City', 'loc': 'Villapuram Main Road, Madurai'},
    {'venue': 'Legends Box Cricket & Turf', 'loc': 'KK Nagar, Madurai'},
    {'venue': 'Ace Badminton & Turf Club', 'loc': 'Bypass Road, Madurai'},
  ];

  @override
  void initState() {
    super.initState();
    _generateRandomPin();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _prizeController.dispose();
    _entryFeeController.dispose();
    _customRulesController.dispose();
    super.dispose();
  }

  void _generateRandomPin() {
    final rand = Random().nextInt(9000) + 1000;
    setState(() {
      _pinController.text = 'G24-$rand';
    });
  }

  String _formatDate(DateTime dt) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F172A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _proceedToStep2() {
    if (_formKey.currentState?.validate() != true) return;

    if (_selectedVenue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tournament venue')),
      );
      return;
    }

    HapticFeedback.lightImpact();

    final selectedRules = _rulesMap.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final data = TournamentFormData(
      title: _nameController.text.trim(),
      sport: _selectedSport,
      prizePool: _prizeController.text.trim(),
      entryFee: _entryFeeController.text.trim(),
      maxTeams: _maxTeams,
      date: _formatDate(_selectedDate),
      time: _selectedTimeSlot,
      venue: _selectedVenue,
      location: _selectedLocation,
      format: _selectedFormat,
      isPrivate: true,
      accessCode: _pinController.text.trim(),
      rules: selectedRules,
      customRules: _customRulesController.text.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePrivateTournamentStep2Screen(formData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'Create Private Tournament',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Step 1 of 2 • Invite-Only Cup Setup',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: SizedBox(
            height: 4,
            child: Row(
              children: [
                Expanded(child: Container(color: const Color(0xFFD97706))),
                Expanded(child: Container(color: const Color(0xFFE2E8F0))),
              ],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              _buildHeroBadge(),
              const SizedBox(height: 16),

              // Access PIN Security Card (Primary feature of private tournament)
              _buildPinCard(),
              const SizedBox(height: 16),

              // Tournament Title
              _buildSectionCard(
                title: 'Tournament Name 🏆',
                subtitle: 'Name your private championship or cup',
                child: TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 20),
                    labelText: 'Tournament Name',
                    hintText: 'e.g. Alumni Badminton Cup 2026',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD97706), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a tournament name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Sport & Format
              _buildSectionCard(
                title: 'Sport & Match Structure 🏅',
                subtitle: 'Choose your sport discipline and tournament format',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Sport', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sportsList.map((item) {
                        final name = item['name'] as String;
                        final icon = item['icon'] as IconData;
                        final isSel = _selectedSport == name;
                        return ChoiceChip(
                          avatar: Icon(icon, size: 16, color: isSel ? Colors.white : const Color(0xFFD97706)),
                          label: Text(name),
                          selected: isSel,
                          selectedColor: const Color(0xFF0F172A),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _selectedSport = name),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Format', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    ..._formatsList.map((fmt) {
                      final isSel = _selectedFormat == fmt;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: InkWell(
                          onTap: () => setState(() => _selectedFormat = fmt),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? const Color(0xFFD97706) : const Color(0xFFE2E8F0),
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSel ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  fmt,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Financials: Prize Pool & Entry Fee
              _buildSectionCard(
                title: 'Prize & Entry Fee 💵',
                subtitle: 'Set custom rewards and registration fee for private teams',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _prizeController,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Prize Pool',
                              hintText: 'e.g. ₹15,000 + Trophy',
                              prefixIcon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFD97706), size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _entryFeeController,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Entry Fee / Team',
                              hintText: 'e.g. ₹1,000 / team',
                              prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Color(0xFFD97706), size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: [
                        _buildPresetChip('+ ₹10,000', () => setState(() => _prizeController.text = '₹10,000 + Trophy')),
                        _buildPresetChip('+ ₹20,000', () => setState(() => _prizeController.text = '₹20,000 + Trophy')),
                        _buildPresetChip('Free Entry', () => setState(() => _entryFeeController.text = 'Free Entry')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Capacity & Schedule
              _buildSectionCard(
                title: 'Team Count & Timing 📅',
                subtitle: 'Invite capacity and court time',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Invited Teams Count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Row(
                      children: [4, 8, 12, 16, 24].map((count) {
                        final isSel = _maxTeams == count;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: ChoiceChip(
                              label: Text('$count', style: const TextStyle(fontSize: 11)),
                              selected: isSel,
                              selectedColor: const Color(0xFF0F172A),
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) => setState(() => _maxTeams = count),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFD97706)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Match Date', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                        Text(
                                          _formatDate(_selectedDate),
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: _showTimeSlotPicker,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFD97706)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Time Slot', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                        Text(
                                          _selectedTimeSlot,
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Venue
              _buildSectionCard(
                title: 'Host Turf Venue 🏟️',
                subtitle: 'Venue for private matches',
                child: InkWell(
                  onTap: _showVenuePicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.stadium_rounded, color: Color(0xFFD97706), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedVenue.isNotEmpty ? _selectedVenue : 'Select Venue / Turf Ground',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: _selectedVenue.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedLocation.isNotEmpty ? _selectedLocation : 'Tap to choose tournament venue',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.swap_horiz_rounded, color: Color(0xFFD97706), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rules
              _buildSectionCard(
                title: 'Rules & Access Policy 📜',
                subtitle: 'Tournament guidelines for invited squads',
                child: Column(
                  children: [
                    ..._rulesMap.keys.map((rule) {
                      final val = _rulesMap[rule] ?? false;
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFFD97706),
                        title: Text(rule, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                        value: val,
                        onChanged: (checked) {
                          setState(() => _rulesMap[rule] = checked ?? false);
                        },
                      );
                    }),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _customRulesController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'Custom Host Notes (Optional)',
                        hintText: 'e.g. Strict company ID verification at gate',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Next Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A), // Premium navy slate
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20, color: Color(0xFFFDE68A)),
                  label: const Text(
                    'Continue to Review (Step 2) ➔',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  onPressed: _proceedToStep2,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFD97706),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Private Invite-Only Cup 🔒',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFDE68A)),
                ),
                SizedBox(height: 3),
                Text(
                  'Only teams with your unique Access PIN can find and register for this tournament. Hidden from public discovery.',
                  style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.key_rounded, color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Tournament Security PIN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                  ),
                ],
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFFD97706),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Generate New', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: _generateRandomPin,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pinController,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: Color(0xFF78350F)),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'e.g. G24-5821',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFDE68A))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD97706), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFFD97706)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _pinController.text.trim()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      content: Text('PIN "${_pinController.text.trim()}" copied! 📋'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please generate or enter a security PIN';
              }
              if (val.trim().length < 4) {
                return 'PIN must be at least 4 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 6),
          const Text(
            'Teams will be prompted to enter this PIN when accepting your invitation.',
            style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFFFFFBEB),
      side: const BorderSide(color: Color(0xFFFDE68A)),
      onPressed: onTap,
    );
  }

  void _showTimeSlotPicker() {
    final slots = [
      '06:00 PM - 10:00 PM (Night / Lights)',
      '09:00 AM - 01:00 PM (Morning)',
      '02:00 PM - 06:00 PM (Afternoon)',
      '08:00 AM - 05:00 PM (Full Day Cup)',
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Private Match Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),
            ...slots.map((s) => ListTile(
                  title: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: _selectedTimeSlot == s.split(' (').first ? const Icon(Icons.check, color: Color(0xFFD97706)) : null,
                  onTap: () {
                    setState(() => _selectedTimeSlot = s.split(' (').first);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showVenuePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Host Turf Venue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),
            ..._turfVenues.map((v) => ListTile(
                  leading: const Icon(Icons.stadium_rounded, color: Color(0xFFD97706)),
                  title: Text(v['venue']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: Text(v['loc']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  onTap: () {
                    setState(() {
                      _selectedVenue = v['venue']!;
                      _selectedLocation = v['loc']!;
                    });
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
