import 'dart:io';
import 'dart:convert';
import 'main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'tournament_form_data.dart';
import 'core/network/api_client.dart';
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
  final _newRuleInputController = TextEditingController();
  final _externalTicketController = TextEditingController();

  // Banner Poster
  // Gallery images are uploaded right away; the server URL (not the local path) is saved.
  Future<String?>? _bannerUpload;
  static const String _fallbackBanner =
      'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800';
  String _bannerImageUrl = 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800';
  bool _isLocalBanner = false;

  // Sports & Format
  String _selectedSport = 'Football';
  String _selectedFormat = '16 Teams Knockout';
  int _maxTeams = 16;

  // Schedule & Venue
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String _selectedTimeSlot = '09:00 AM - 06:00 PM';
  String _selectedVenue = '';
  String _selectedLocation = '';
  int _selectedVenueCourts = 3;
  bool _isVenueTBA = false;
  String _selectedCity = 'Chennai';

  // Toggleable Rules (Preset + User Added)
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

  // Live Turfs Present in App
  List<Map<String, dynamic>> _liveTurfs = [];
  bool _isLoadingVenues = true;

  Future<void> _fetchLiveTurfs() async {
    setState(() => _isLoadingVenues = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/turfs')).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        if (mounted && list.isNotEmpty) {
          setState(() {
            _liveTurfs = list.map((t) {
              final courts = t['courts'] as List? ?? [];
              final sportsList = t['sports'] as List? ?? [];
              final neighborhood = (t['neighborhoodArea'] ?? '').toString();
              final street = (t['streetAddress'] ?? '').toString();
              final venueName = (t['venueName'] ?? t['name'] ?? 'Turf Arena').toString();
              final loc = t['location']?.toString() ?? (neighborhood.isNotEmpty ? '$neighborhood • $street' : street);

              return {
                'id': t['id'],
                'venue': venueName,
                'loc': loc,
                'city': street.isNotEmpty ? street : 'Madurai',
                'courts': courts.isNotEmpty ? courts.length : 2,
                'sports': sportsList.isNotEmpty ? sportsList.join(' • ') : 'Cricket • Football',
                'imageUrl': (t['imageUrl'] ?? (t['photoUrls'] is List && (t['photoUrls'] as List).isNotEmpty ? t['photoUrls'][0] : '')).toString(),
              };
            }).toList();
            _isLoadingVenues = false;

            if (_selectedVenue.isEmpty && _liveTurfs.isNotEmpty && !_isVenueTBA) {
              _selectedVenue = _liveTurfs.first['venue'] as String;
              _selectedLocation = _liveTurfs.first['loc'] as String;
              _selectedVenueCourts = _liveTurfs.first['courts'] as int;
            }
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching live turfs for tournament: $e");
    }

    if (mounted) {
      setState(() {
        if (_liveTurfs.isEmpty) {
          _liveTurfs = [
            {
              'id': 1,
              'venue': 'test turf',
              'loc': 'villapuram • madurai',
              'city': 'Madurai',
              'courts': 2,
              'sports': 'Cricket • Football',
              'imageUrl': '',
            },
            {
              'id': 2,
              'venue': 'Inno Sports Arena (KK Nagar)',
              'loc': 'KK Nagar, Madurai • KK Nagar 80 Feet Road',
              'city': 'Madurai',
              'courts': 4,
              'sports': 'Cricket • Football • Badminton',
              'imageUrl': '',
            },
          ];
          if (_selectedVenue.isEmpty && !_isVenueTBA) {
            _selectedVenue = _liveTurfs.first['venue'] as String;
            _selectedLocation = _liveTurfs.first['loc'] as String;
            _selectedVenueCourts = _liveTurfs.first['courts'] as int;
          }
        }
        _isLoadingVenues = false;
      });
    }
  }

  // Preset Poster Styles
  final List<Map<String, String>> _presetPosters = [
    {
      'title': 'Cricket Gold Trophy',
      'url': 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800',
      'desc': 'Gold & Green Stadium'
    },
    {
      'title': 'FIFA Pro Turf Arena',
      'url': 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800',
      'desc': 'Lush Green Pitch'
    },
    {
      'title': 'Night Floodlight Match',
      'url': 'https://images.unsplash.com/photo-1518091043644-c1d4457512c6?w=800',
      'desc': 'Atmospheric Lights'
    },
    {
      'title': 'Badminton Masters',
      'url': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
      'desc': 'Indoor Championship'
    },
    {
      'title': 'Cyber Neon Clash',
      'url': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800',
      'desc': 'High Voltage Esports'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserCity();
    _fetchLiveTurfs();
  }

  Future<void> _loadUserCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('userCity');
    if (savedCity != null && savedCity.isNotEmpty) {
      setState(() => _selectedCity = savedCity);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prizeController.dispose();
    _entryFeeController.dispose();
    _customRulesController.dispose();
    _newRuleInputController.dispose();
    _externalTicketController.dispose();
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
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4FF00),
              onPrimary: Colors.black,
              surface: Color(0xFF141414),
              onSurface: Colors.white,
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

  Future<void> _pickBannerFromGallery() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file != null) {
        setState(() {
          _bannerImageUrl = file.path;
          _isLocalBanner = true;
        });
        final pickedFile = file;
        _bannerUpload = pickedFile
            .readAsBytes()
            .then((bytes) => ApiClient.uploadPhoto(bytes, pickedFile.name));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load image: $e')),
        );
      }
    }
  }

  void _showPresetPostersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF262626), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('Select Championship Banner Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Pick a high-definition sports poster for your tournament pass.', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11)),
              const SizedBox(height: 16),
              ..._presetPosters.map((poster) {
                final isSelected = _bannerImageUrl == poster['url'];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(poster['url']!, width: 56, height: 40, fit: BoxFit.cover),
                  ),
                  title: Text(poster['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  subtitle: Text(poster['desc']!, style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA))),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFD4FF00)) : null,
                  onTap: () {
                    setState(() {
                      _bannerImageUrl = poster['url']!;
                      _isLocalBanner = false;
                    });
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _addNewCustomRule() {
    final text = _newRuleInputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _rulesMap[text] = true;
      _newRuleInputController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFFD4FF00), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Rule added: "$text"', style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFD4FF00)),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _proceedToStep2() async {
    if (_formKey.currentState?.validate() != true) return;

    if (!_isVenueTBA && _selectedVenue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a turf venue or choose "Decide Venue Later"')),
      );
      return;
    }

    HapticFeedback.lightImpact();

    final selectedRules = _rulesMap.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    String bannerUrl = _bannerImageUrl;
    if (_isLocalBanner) {
      final uploaded = await (_bannerUpload ?? Future<String?>.value(null));
      if (!mounted) return;
      if (uploaded == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not upload your banner, using a default poster instead.')),
        );
        bannerUrl = _fallbackBanner;
      } else {
        bannerUrl = uploaded;
      }
    }

    final data = TournamentFormData(
      title: _nameController.text.trim(),
      sport: _selectedSport,
      prizePool: _prizeController.text.trim(),
      entryFee: _entryFeeController.text.trim(),
      maxTeams: _maxTeams,
      date: _formatDate(_selectedDate),
      time: _selectedTimeSlot,
      venue: _isVenueTBA ? 'Venue To Be Announced (TBA)' : _selectedVenue,
      location: _isVenueTBA ? '$_selectedCity (Exact Arena TBA)' : _selectedLocation,
      format: _selectedFormat,
      isPrivate: false,
      rules: selectedRules,
      customRules: _customRulesController.text.trim(),
      imageUrl: bannerUrl,
      isVenueTBA: _isVenueTBA,
      externalTicketUrl: _externalTicketController.text.trim(),
      courtsCount: _isVenueTBA ? 0 : _selectedVenueCourts,
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
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
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
                color: Colors.white,
              ),
            ),
            Text(
              'Step 1 of 2 • Basic Setup & Rules',
              style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: SizedBox(
            height: 4,
            child: Row(
              children: [
                Expanded(child: Container(color: const Color(0xFFD4FF00))),
                Expanded(child: Container(color: const Color(0xFF262626))),
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
              // Hero Banner Poster Selector
              _buildBannerPosterCard(),
              const SizedBox(height: 16),

              // Tournament Name Card
              _buildSectionCard(
                title: 'Tournament Name & Branding 🏆',
                subtitle: 'Give your championship an exciting, official title',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        prefixIcon: const Icon(Icons.emoji_events_rounded, color: Color(0xFFD4FF00), size: 20),
                        labelText: 'Tournament Name',
                        labelStyle: const TextStyle(color: Color(0xFFA1A1AA)),
                        hintText: 'e.g. Madurai Super League Season 1',
                        hintStyle: const TextStyle(color: Color(0xFF71717A)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF262626))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF262626))),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD4FF00), width: 1.5),
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
                    const Text('Select Sport', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFA1A1AA))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sportsList.map((item) {
                        final name = item['name'] as String;
                        final icon = item['icon'] as IconData;
                        final isSel = _selectedSport == name;
                        return ChoiceChip(
                          avatar: Icon(icon, size: 16, color: isSel ? Colors.black : const Color(0xFFD4FF00)),
                          label: Text(name),
                          selected: isSel,
                          selectedColor: const Color(0xFFD4FF00),
                          backgroundColor: const Color(0xFF181818),
                          side: BorderSide(color: isSel ? const Color(0xFFD4FF00) : const Color(0xFF262626)),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.black : Colors.white,
                            fontWeight: isSel ? FontWeight.w900 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _selectedSport = name),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Championship Format', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFA1A1AA))),
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
                              color: isSel ? const Color(0xFF1F2916) : const Color(0xFF181818),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? const Color(0xFFD4FF00) : const Color(0xFF262626),
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
                                    color: Colors.white,
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF1E1E1E),
                              labelText: 'Prize Pool',
                              labelStyle: const TextStyle(color: Color(0xFFA1A1AA)),
                              hintText: 'e.g. ₹10,000 + Trophy',
                              hintStyle: const TextStyle(color: Color(0xFF71717A)),
                              prefixIcon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFD4FF00), size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF262626))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF262626))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4FF00), width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _entryFeeController,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF1E1E1E),
                              labelText: 'Entry Fee / Team',
                              labelStyle: const TextStyle(color: Color(0xFFA1A1AA)),
                              hintText: 'e.g. ₹500 / team',
                              hintStyle: const TextStyle(color: Color(0xFF71717A)),
                              prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Color(0xFFD4FF00), size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF262626))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF262626))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4FF00), width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _externalTicketController,
                      style: const TextStyle(fontSize: 12.5, color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        labelText: 'External Ticket / RSVP Link (Optional)',
                        labelStyle: const TextStyle(color: Color(0xFFA1A1AA)),
                        hintText: 'e.g. https://insider.in/event/... or WhatsApp Pass',
                        hintStyle: const TextStyle(color: Color(0xFF71717A)),
                        prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFFD4FF00), size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF262626))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF262626))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4FF00), width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
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
                    const Text('Max Teams Allowed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFA1A1AA))),
                    const SizedBox(height: 8),
                    Row(
                      children: [4, 8, 16, 24, 32].map((count) {
                        final isSel = _maxTeams == count;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: InkWell(
                              onTap: () => setState(() => _maxTeams = count),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFFD4FF00) : const Color(0xFF181818),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? const Color(0xFFD4FF00) : const Color(0xFF262626),
                                    width: isSel ? 1.5 : 1.0,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? Colors.black : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
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
                                color: const Color(0xFF181818),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF262626)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFD4FF00)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Match Date', style: TextStyle(fontSize: 10, color: Color(0xFFA1A1AA))),
                                        Text(
                                          _formatDate(_selectedDate),
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
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
                                color: const Color(0xFF181818),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF262626)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFD4FF00)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Time Slot', style: TextStyle(fontSize: 10, color: Color(0xFFA1A1AA))),
                                        Text(
                                          _selectedTimeSlot,
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
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

              // Venue Selection & TBA Toggle
              _buildSectionCard(
                title: 'Venue & Live Turf Grounds 🏟️',
                subtitle: 'Select live host turf ground or decide venue later',
                child: Column(
                  children: [
                    // Decide Venue Later (TBA) Switch Card
                    Material(
                      color: _isVenueTBA ? const Color(0xFF1F2916) : const Color(0xFF181818),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isVenueTBA ? const Color(0xFFD4FF00) : const Color(0xFF262626),
                            width: _isVenueTBA ? 1.5 : 1,
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: const Color(0xFFD4FF00),
                          title: const Text(
                            'Decide Venue Later 📍 (TBA)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Venue shows as "Launching Soon". Announce arena closer to match date.',
                            style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                          ),
                          value: _isVenueTBA,
                          onChanged: (val) {
                            setState(() {
                              _isVenueTBA = val;
                              if (val) {
                                _selectedVenue = 'Venue To Be Announced (TBA)';
                                _selectedLocation = '$_selectedCity (Exact Arena TBA)';
                                _selectedVenueCourts = 0;
                              } else {
                                _selectedVenue = '';
                                _selectedLocation = '';
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (!_isVenueTBA)
                      InkWell(
                        onTap: _showVenuePicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181818),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF262626)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F2916),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.stadium_rounded, color: Color(0xFFD4FF00), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedVenue.isNotEmpty ? _selectedVenue : 'Select Host Turf Arena',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: _selectedVenue.isNotEmpty ? Colors.white : const Color(0xFFA1A1AA),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedLocation.isNotEmpty
                                          ? '$_selectedLocation • $_selectedVenueCourts Courts Available'
                                          : 'Tap to browse live venues in $_selectedCity',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFA1A1AA)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.swap_horiz_rounded, color: Color(0xFFD4FF00), size: 20),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B1D08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF78350F)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline_rounded, color: Color(0xFFFBBF24), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Venue Launching Soon mode active. Registered teams will be notified automatically when venue is finalized.',
                                style: TextStyle(color: Color(0xFFFBBF24), fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Rules & Guidelines Section with Custom Add Functionality
              _buildSectionCard(
                title: 'Rules & Guidelines 📜',
                subtitle: 'Set clear expectations for fair competition and safety',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._rulesMap.keys.map((rule) {
                      final val = _rulesMap[rule] ?? false;
                      final isCustom = !_isDefaultRule(rule);

                      return Material(
                        color: Colors.transparent,
                        child: CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: const Color(0xFFD4FF00),
                          checkColor: Colors.black,
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(rule, style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1AA))),
                              ),
                              if (isCustom)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() => _rulesMap.remove(rule));
                                  },
                                ),
                            ],
                          ),
                          value: val,
                          onChanged: (checked) {
                            setState(() => _rulesMap[rule] = checked ?? false);
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    // Add Custom Rule Input with Button
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newRuleInputController,
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF1E1E1E),
                              labelText: 'Add Custom Rule (e.g. 10m halves)',
                              labelStyle: const TextStyle(color: Color(0xFFA1A1AA)),
                              hintText: 'Type rule and tap + Add',
                              hintStyle: const TextStyle(color: Color(0xFF71717A)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD4FF00), width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onSubmitted: (_) => _addNewCustomRule(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _addNewCustomRule,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4FF00),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('+ Add', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customRulesController,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        labelText: 'Additional Organizer Notes (Optional)',
                        labelStyle: const TextStyle(color: Color(0xFFA1A1AA)),
                        hintText: 'e.g. Refreshments provided, bring photo ID',
                        hintStyle: const TextStyle(color: Color(0xFF71717A)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD4FF00), width: 1.5)),
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
                    backgroundColor: const Color(0xFFD4FF00),
                    foregroundColor: Colors.black,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: const Text(
                    'Preview Championship Pass 🏆',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
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

  bool _isDefaultRule(String rule) {
    return rule == 'Players must report 15 mins prior to kickoff' ||
        rule == 'Proper turf boots/sports shoes and jerseys required' ||
        rule == 'Zero tolerance for unsportsmanlike conduct' ||
        rule == 'Up to 5 rolling substitutions allowed per match' ||
        rule == 'On-field referee decision is final and binding';
  }

  Widget _buildBannerPosterCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                _isLocalBanner
                    ? Image.file(
                        File(_bannerImageUrl),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        _bannerImageUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.7)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2916),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD4FF00).withValues(alpha: 0.35)),
                        ),
                        child: const Text(
                          'TOURNAMENT BANNER POSTER 🖼️',
                          style: TextStyle(color: Color(0xFFD4FF00), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickBannerFromGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Gallery Upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4FF00),
                      side: const BorderSide(color: Color(0xFFD4FF00)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showPresetPostersSheet,
                    icon: const Icon(Icons.palette_outlined, size: 16, color: Colors.black),
                    label: const Text('Preset Themes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4FF00),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262626)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.white)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFFA1A1AA))),
          const SizedBox(height: 14),
          child,
        ],
      ),
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
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Tournament Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 14),
            ...slots.map((s) => ListTile(
                  title: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  trailing: _selectedTimeSlot == s.split(' (').first ? const Icon(Icons.check, color: Color(0xFFD4FF00)) : null,
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
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Host Turf Arena', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2916),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD4FF00).withValues(alpha: 0.35)),
                    ),
                    child: const Text('Live App Turfs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD4FF00))),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_isLoadingVenues)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: Color(0xFFD4FF00)),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: _liveTurfs.map((v) {
                      final isSel = _selectedVenue == v['venue'];
                      final courts = v['courts'] as int;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF1F2916), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.stadium_rounded, color: Color(0xFFD4FF00)),
                        ),
                        title: Text(v['venue'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white)),
                        subtitle: Text('${v['loc']} • 🏟️ $courts Courts Available', style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA))),
                        trailing: isSel ? const Icon(Icons.check_circle, color: Color(0xFFD4FF00)) : null,
                        onTap: () {
                          setState(() {
                            _selectedVenue = v['venue'] as String;
                            _selectedLocation = v['loc'] as String;
                            _selectedVenueCourts = courts;
                            _isVenueTBA = false;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
