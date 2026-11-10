import 'main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tournament_form_data.dart';
import 'create_public_tournament_step2_screen.dart';

class CreatePublicTournamentScreen extends StatefulWidget {
  const CreatePublicTournamentScreen({super.key});

  @override
  State<CreatePublicTournamentScreen> createState() =>
      _CreatePublicTournamentScreenState();
}

class _CreatePublicTournamentScreenState
    extends State<CreatePublicTournamentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _prizeController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _customRulesController = TextEditingController();

  // Sports & Format
  String _selectedSport = 'Football';
  String _selectedFormat = '16 Teams Knockout';
  int _maxTeams = 16;

  // Schedule & Venue
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String _selectedTimeSlot = '09:00 AM - 06:00 PM';
  String _selectedVenue = 'Grand Arena Turf';
  String _selectedLocation = 'Downtown Sports Complex, Madurai';

  // Toggleable Rules
  final Map<String, bool> _rulesMap = {
    'Players must report 15 mins prior to kickoff': true,
    'Proper turf boots/sports shoes and jerseys required': true,
    'Zero tolerance for unsportsmanlike conduct': true,
    'Up to 5 rolling substitutions allowed per match': true,
    'On-field referee decision is final and binding': true,
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
  void dispose() {
    _nameController.dispose();
    _prizeController.dispose();
    _entryFeeController.dispose();
    _customRulesController.dispose();
    super.dispose();
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
              primary: Color(0xFF166534),
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
      isPrivate: false,
      rules: selectedRules,
      customRules: _customRulesController.text.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePublicTournamentStep2Screen(formData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'Create Public Tournament',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Step 1 of 2 • Basic Setup & Rules',
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
                Expanded(child: Container(color: const Color(0xFF166534))),
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
              const SizedBox(height: 20),

              // Tournament Name Card
              _buildSectionCard(
                title: 'Tournament Name & Branding 🏆',
                subtitle: 'Give your championship an exciting, official title',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.emoji_events_rounded, color: Color(0xFF166534), size: 20),
                        labelText: 'Tournament Name',
                        hintText: 'e.g. Madurai Super League Season 1',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF166534), width: 2),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sport & Format Card
              _buildSectionCard(
                title: 'Sport & Tournament Format ⚽',
                subtitle: 'Select sport discipline and match structure',
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
                          avatar: Icon(icon, size: 16, color: isSel ? Colors.white : const Color(0xFF166534)),
                          label: Text(name),
                          selected: isSel,
                          selectedColor: const Color(0xFF166534),
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
                    const Text('Championship Format', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
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
                              color: isSel ? const Color(0xFFE5F5EB) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? const Color(0xFF166534) : const Color(0xFFE2E8F0),
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSel ? const Color(0xFF166534) : const Color(0xFF94A3B8),
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
                title: 'Prize Pool & Entry Fees 💰',
                subtitle: 'Attract top teams with verified rewards',
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
                              hintText: 'e.g. ₹10,000 + Trophy',
                              prefixIcon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF166534), size: 18),
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
                              hintText: 'e.g. ₹500 / team',
                              prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF166534), size: 18),
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
                        _buildPresetChip('+ ₹5,000', () => setState(() => _prizeController.text = '₹5,000 + Trophy')),
                        _buildPresetChip('+ ₹10,000', () => setState(() => _prizeController.text = '₹10,000 + Trophy')),
                        _buildPresetChip('+ ₹25,000', () => setState(() => _prizeController.text = '₹25,000 + Trophy')),
                        _buildPresetChip('Free Entry', () => setState(() => _entryFeeController.text = 'Free Entry')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Capacity & Schedule
              _buildSectionCard(
                title: 'Capacity & Match Schedule 📅',
                subtitle: 'Team brackets and tournament kickoff',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Max Teams Allowed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Row(
                      children: [4, 8, 16, 24, 32].map((count) {
                        final isSel = _maxTeams == count;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: ChoiceChip(
                              label: Text('$count', style: const TextStyle(fontSize: 11)),
                              selected: isSel,
                              selectedColor: const Color(0xFF166534),
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
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF166534)),
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
                                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF166534)),
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

              // Venue Selection
              _buildSectionCard(
                title: 'Venue & Court 🏟️',
                subtitle: 'Select the host turf ground',
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
                            color: const Color(0xFFE5F5EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.stadium_rounded, color: Color(0xFF166534), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedVenue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              const SizedBox(height: 2),
                              Text(_selectedLocation, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        const Icon(Icons.swap_horiz_rounded, color: Color(0xFF166534), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rules & Guidelines Section
              _buildSectionCard(
                title: 'Rules & Guidelines 📜',
                subtitle: 'Set clear expectations for fair competition',
                child: Column(
                  children: [
                    ..._rulesMap.keys.map((rule) {
                      final val = _rulesMap[rule] ?? false;
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFF166534),
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
                        labelText: 'Additional Custom Rules (Optional)',
                        hintText: 'e.g. 10-minute halves, rolling yellow cards',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF166534),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
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
          colors: [Color(0xFFE5F5EB), Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF166534),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.public_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Public Championship Mode 🌐',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF166534)),
                ),
                SizedBox(height: 3),
                Text(
                  'Your tournament will be open to all players, listed on city discovery, and featured on the tournament leaderboard.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.3),
                ),
              ],
            ),
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
      label: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFFE5F5EB),
      side: const BorderSide(color: Color(0xFF86EFAC)),
      onPressed: onTap,
    );
  }

  void _showTimeSlotPicker() {
    final slots = [
      '09:00 AM - 06:00 PM (Full Day)',
      '06:00 AM - 12:00 PM (Morning)',
      '04:00 PM - 10:00 PM (Evening / Lights)',
      '02:00 PM - 08:00 PM (Afternoon)',
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
            const Text('Select Tournament Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),
            ...slots.map((s) => ListTile(
                  title: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: _selectedTimeSlot == s.split(' (').first ? const Icon(Icons.check, color: Color(0xFF166534)) : null,
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
                  leading: const Icon(Icons.stadium_rounded, color: Color(0xFF166534)),
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
