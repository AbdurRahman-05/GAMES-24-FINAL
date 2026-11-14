import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../../api_config.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../tournaments/data/models/tournament_model.dart';
import '../../../tournaments/presentation/widgets/tournament_bracket_view.dart';
import '../../../tournaments/providers/tournament_provider.dart';
import '../../providers/admin_providers.dart';

class AdminTournamentManagerScreen extends ConsumerStatefulWidget {
  const AdminTournamentManagerScreen({super.key});

  @override
  ConsumerState<AdminTournamentManagerScreen> createState() =>
      _AdminTournamentManagerScreenState();
}

class _AdminTournamentManagerScreenState
    extends ConsumerState<AdminTournamentManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Controllers for Create Tournament Wizard
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();
  final _organizerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _entryFeeCtrl = TextEditingController();
  final _maxTeamsCtrl = TextEditingController();
  final _playersPerTeamCtrl = TextEditingController();
  final _championPrizeCtrl = TextEditingController();
  final _runnerUpPrizeCtrl = TextEditingController();

  String _selectedSport = 'Cricket';
  String _selectedType = 'Knockout';
  String _selectedCourt = 'Turf A (Football / Cricket)';

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 10));
  DateTime _regEndDate = DateTime.now().add(const Duration(days: 5));

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Live Score Controllers
  final _liveScoreCtrl = TextEditingController();
  final _liveCommentaryCtrl = TextEditingController();

  // Active status filter for Tab 1
  String _activeFilter = 'All';

  final List<Map<String, String>> _sportsList = const [
    {'name': 'Cricket', 'emoji': '🏏'},
    {'name': 'Football', 'emoji': '⚽'},
    {'name': 'Futsal', 'emoji': '🥅'},
    {'name': 'Badminton', 'emoji': '🏸'},
    {'name': 'Tennis', 'emoji': '🎾'},
    {'name': 'Volleyball', 'emoji': '🏐'},
    {'name': 'Basketball', 'emoji': '🏀'},
  ];

  final List<Map<String, String>> _formatsList = const [
    {'name': 'Knockout', 'desc': 'Single loss elimination'},
    {'name': 'Seeded Knockout', 'desc': 'Top seeds protected in early rounds'},
    {'name': 'Double Elimination', 'desc': 'Winners & Losers brackets'},
    {'name': 'Group Stage + Knockout', 'desc': 'Pool play into final brackets'},
    {'name': 'Round Robin', 'desc': 'All teams face each other'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(turfProfileProvider);
      ref.read(adminTournamentProvider.notifier).fetchTournamentsFromBackend(
            turfId: profile.turfId > 0 ? profile.turfId : null,
            phone: profile.ownerPhone,
            venue: profile.venueName,
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _descCtrl.dispose();
    _rulesCtrl.dispose();
    _organizerCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _entryFeeCtrl.dispose();
    _maxTeamsCtrl.dispose();
    _playersPerTeamCtrl.dispose();
    _championPrizeCtrl.dispose();
    _runnerUpPrizeCtrl.dispose();
    _liveScoreCtrl.dispose();
    _liveCommentaryCtrl.dispose();
    super.dispose();
  }

  void _submitCreateTournament() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ToastUtils.showError(context, "Please enter Tournament Name");
      return;
    }

    final todayStr =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    final venueProfile = ref.read(turfProfileProvider);
    final verifiedAdminId = venueProfile.turfId;
    final venueName = venueProfile.venueName.isNotEmpty ? venueProfile.venueName : 'Champions Arena';

    final newTournament = TournamentModel(
      id: 'tourn_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      subtitle: _subtitleCtrl.text.trim().isEmpty
          ? 'Open Championship'
          : _subtitleCtrl.text.trim(),
      bannerUrl:
          'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=800&q=80',
      logoUrl:
          'https://images.unsplash.com/photo-1531415074968-036ba1b575da?auto=format&fit=crop&w=150&q=80',
      description: _descCtrl.text.trim().isEmpty
          ? 'Official Gamez24 Tournament'
          : _descCtrl.text.trim(),
      rules: _rulesCtrl.text.trim().isEmpty
          ? '1. Standard tournament rules apply.'
          : _rulesCtrl.text.trim(),
      organizerName: _organizerCtrl.text.trim().isNotEmpty ? _organizerCtrl.text.trim() : venueProfile.ownerName,
      contactPerson: 'Venue Manager',
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : venueProfile.ownerPhone,
      whatsapp: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : venueProfile.ownerPhone,
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : venueProfile.ownerEmail,
      tournamentType: _selectedType,
      sportType: _selectedSport,
      courtAllocation: _selectedCourt,
      regStartDate: todayStr,
      regEndDate: _formatDate(_regEndDate),
      startDate: _formatDate(_startDate),
      endDate: _formatDate(_endDate),
      matchStartTime: '08:00 AM',
      matchEndTime: '08:00 PM',
      matchDurationMinutes: 40,
      breakMinutes: 10,
      teamEntryFee: double.tryParse(_entryFeeCtrl.text.trim()) ?? 1500,
      regularPrice: double.tryParse(_entryFeeCtrl.text.trim()) ?? 1500,
      maxTeams: int.tryParse(_maxTeamsCtrl.text.trim()) ?? 12,
      minTeams: 6,
      playersPerTeam: int.tryParse(_playersPerTeamCtrl.text.trim()) ?? 8,
      substitutePlayers: 2,
      championPrize: _championPrizeCtrl.text.trim().isNotEmpty ? _championPrizeCtrl.text.trim() : '₹15,000 Cash',
      runnerUpPrize: _runnerUpPrizeCtrl.text.trim(),
      status: 'Upcoming',
    );

    // 1. Immediately persist tournament to backend database
    try {
      final payload = {
        'title': newTournament.title,
        'sport': newTournament.sportType,
        'format': newTournament.tournamentType,
        'date': newTournament.startDate.isNotEmpty ? newTournament.startDate : todayStr,
        'time': newTournament.matchStartTime,
        'venueName': venueName,
        'location': venueProfile.area.isNotEmpty ? venueProfile.area : 'Madurai',
        'entryFee': newTournament.teamEntryFee,
        'prizePool': newTournament.championPrize,
        'maxTeams': newTournament.maxTeams,
        'organizerName': newTournament.organizerName,
        'organizerPhone': newTournament.phone,
        'bannerUrl': newTournament.bannerUrl,
        'verifiedAdminId': verifiedAdminId,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/turfs/tournaments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh from backend for this owner
        await ref.read(adminTournamentProvider.notifier).fetchTournamentsFromBackend(
              turfId: verifiedAdminId,
              phone: venueProfile.ownerPhone,
              venue: venueName,
            );
      } else {
        ref.read(adminTournamentProvider.notifier).addTournament(newTournament);
      }
    } catch (e) {
      debugPrint("Error creating tournament on backend: $e");
      ref.read(adminTournamentProvider.notifier).addTournament(newTournament);
    }

    // Auto Lock Court Slots in Admin Slot Provider
    ref.read(adminSlotProvider.notifier).reserveTournamentSlots(
      todayStr,
      [
        '08:00 AM - 09:00 AM',
        '09:00 AM - 10:00 AM',
        '10:00 AM - 11:00 AM',
        '05:00 PM - 06:00 PM'
      ],
      newTournament.title,
    );

    _titleCtrl.clear();
    _subtitleCtrl.clear();
    _descCtrl.clear();
    _rulesCtrl.clear();

    _tabController.animateTo(0);

    if (mounted) {
      ToastUtils.showSuccess(
        context,
        'Tournament "${newTournament.title}" created & published across Gamez24 platform!',
      );
    }
  }

  void _showRegisteredTeamsDialog(TournamentModel t) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final teams = t.registeredTeams;
        final totalFees = teams.length * t.teamEntryFee;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            children: [
              // Modal Handle & Header
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.groups_rounded, color: Color(0xFF15803D), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Registered Squads: ${teams.length} / ${t.maxTeams} Teams • Fee: ₹${t.teamEntryFee.toInt()}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Summary Stats Strip
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Slots Filled', '${teams.length}/${t.maxTeams}', const Color(0xFF154D36)),
                    Container(width: 1, height: 26, color: const Color(0xFFCBD5E1)),
                    _buildStatCol('Collected Fees', '₹${totalFees.toInt()}', const Color(0xFF15803D)),
                    Container(width: 1, height: 26, color: const Color(0xFFCBD5E1)),
                    _buildStatCol('Slots Left', '${(t.maxTeams - teams.length).clamp(0, t.maxTeams)} Open', const Color(0xFFD97706)),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 16),

              // Teams List
              Expanded(
                child: teams.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.groups_outlined, size: 48, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Squads Registered Yet',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'When players register for this tournament from the Gamez24 app, their squad name, captain phone, roster count, and payment info will appear here immediately.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: teams.length,
                        itemBuilder: (context, idx) {
                          final team = teams[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF154D36),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '#${idx + 1}',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        team.teamName,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF86EFAC)),
                                      ),
                                      child: Text(
                                        team.paymentStatus.isNotEmpty ? team.paymentStatus : 'Paid',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Details Grid
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.person_rounded, size: 14, color: Color(0xFF154D36)),
                                          const SizedBox(width: 6),
                                          const Text('Captain: ', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                          Expanded(
                                            child: Text(
                                              team.captainName.isNotEmpty ? team.captainName : 'Captain',
                                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE2E8F0),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '👥 ${team.playerCount} Players',
                                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (team.captainPhone.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF154D36)),
                                            const SizedBox(width: 6),
                                            const Text('Phone: ', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                            Expanded(
                                              child: Text(
                                                team.captainPhone,
                                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                Clipboard.setData(ClipboardData(text: team.captainPhone));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Phone ${team.captainPhone} copied!'),
                                                    backgroundColor: const Color(0xFF154D36),
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.copy_rounded, size: 13, color: Color(0xFF154D36)),
                                                    SizedBox(width: 3),
                                                    Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF154D36))),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (team.captainEmail.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.email_outlined, size: 14, color: Color(0xFF154D36)),
                                            const SizedBox(width: 6),
                                            const Text('Email: ', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                            Expanded(
                                              child: Text(
                                                team.captainEmail,
                                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (team.registrationDate.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                                            const SizedBox(width: 6),
                                            const Text('Registered: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                            Expanded(
                                              child: Text(
                                                team.registrationDate.contains('T') ? team.registrationDate.split('T')[0] : team.registrationDate,
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showLiveScoreDialog(TournamentModel t) {
    _liveScoreCtrl.text = t.liveScore;
    _liveCommentaryCtrl.text = t.liveCommentary;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Live Control • ${t.title}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _liveScoreCtrl,
              decoration: InputDecoration(
                labelText: 'Live Score / Current Status',
                hintText: 'e.g. 142/3 (16.2 ov) or 2 - 1 (68\')',
                prefixIcon: const Icon(Icons.sports_score_rounded, color: Color(0xFF154D36)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _liveCommentaryCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Match Commentary Update',
                hintText: 'e.g. Huge six over long on! Need 14 runs from 12 balls.',
                prefixIcon: const Icon(Icons.record_voice_over_rounded, color: Color(0xFF154D36)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF154D36),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.cell_tower_rounded, size: 18),
                label: const Text(
                  'Broadcast Live Update (Real-time)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  ref.read(adminTournamentProvider.notifier).updateLiveScore(
                        t.id,
                        _liveScoreCtrl.text.trim(),
                        _liveCommentaryCtrl.text.trim(),
                      );
                  Navigator.pop(ctx);
                  ToastUtils.showSuccess(context, "Live score updated on user app!");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateMatchResultDialog(TournamentModel t, TournamentFixture fix) {
    final isCricket = t.sportType == 'Cricket';
    final isBadminton = t.sportType == 'Badminton' || t.sportType == 'Tennis';

    final scoreACtrl = TextEditingController(text: '${fix.scoreA}');
    final scoreBCtrl = TextEditingController(text: '${fix.scoreB}');
    final wicketsACtrl = TextEditingController(text: '${fix.wicketsA}');
    final wicketsBCtrl = TextEditingController(text: '${fix.wicketsB}');
    final oversACtrl = TextEditingController(text: fix.oversA.isEmpty ? '0.0' : fix.oversA);
    final oversBCtrl = TextEditingController(text: fix.oversB.isEmpty ? '0.0' : fix.oversB);

    final playerCtrl = TextEditingController();
    final minuteCtrl = TextEditingController(text: isCricket ? '14.2 ov' : '14\'');

    List<String> eventOptions = isCricket
        ? ['Wicket', 'Six', 'Four', 'Fifty', 'Century', 'Wide', 'No Ball']
        : (isBadminton
            ? ['Ace', 'Smash Winner', 'Unforced Error', 'Set Point']
            : ['Goal', 'Yellow Card', 'Red Card', 'Penalty']);

    String selectedEventType = eventOptions.first;
    String selectedEventTeam = fix.teamA;
    String selectedWinner = fix.winnerTeam.isNotEmpty ? fix.winnerTeam : fix.teamA;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${fix.matchNumber} (${fix.stage})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF154D36),
                                ),
                              ),
                              Text(
                                '${fix.teamA} vs ${fix.teamB}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Scores Section
                    Text(
                      isCricket ? 'Batting & Innings Scores' : 'Current Match Score',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fix.teamA, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: scoreACtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: isCricket ? 'Runs' : 'Score',
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                ),
                                if (isCricket) ...[
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: wicketsACtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Wickets',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: oversACtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Overs (e.g. 15.2)',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fix.teamB, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: scoreBCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: isCricket ? 'Runs' : 'Score',
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                ),
                                if (isCricket) ...[
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: wicketsBCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Wickets',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: oversBCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Overs (e.g. 15.2)',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Winner Selection
                    const Text('Declare Winner Team (Advances in Bracket):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedWinner,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      items: [fix.teamA, fix.teamB, 'Match Drawn / Tied']
                          .map((team) => DropdownMenuItem(value: team, child: Text(team)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedWinner = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Match Event Logger
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚡ Log Key Match Event (Real-time)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF154D36))),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedEventType,
                                  decoration: const InputDecoration(labelText: 'Event', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                                  items: eventOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 11)))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setSheetState(() => selectedEventType = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedEventTeam,
                                  decoration: const InputDecoration(labelText: 'Team', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                                  items: [fix.teamA, fix.teamB].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setSheetState(() => selectedEventTeam = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: playerCtrl,
                                  decoration: const InputDecoration(labelText: 'Player Name', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextFormField(
                                  controller: minuteCtrl,
                                  decoration: const InputDecoration(labelText: 'Time / Over', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add_circle_outline, size: 14),
                              label: const Text('Add Event to Match Feed', style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                if (playerCtrl.text.trim().isEmpty) {
                                  ToastUtils.showError(context, "Enter player name");
                                  return;
                                }
                                final ev = MatchEvent(
                                  id: 'ev_${DateTime.now().millisecondsSinceEpoch}',
                                  type: selectedEventType,
                                  teamName: selectedEventTeam,
                                  playerName: playerCtrl.text.trim(),
                                  minute: minuteCtrl.text.trim(),
                                  timestamp: DateFormat('hh:mm a').format(DateTime.now()),
                                );
                                ref.read(adminTournamentProvider.notifier).addMatchEvent(t.id, fix.id, ev);
                                playerCtrl.clear();
                                ToastUtils.showSuccess(context, "Match event logged!");
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(fix.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 16),
                            label: Text(fix.isPaused ? 'Resume' : 'Pause Match'),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () {
                              ref.read(adminTournamentProvider.notifier).togglePauseMatch(t.id, fix.id);
                              Navigator.pop(ctx);
                              ToastUtils.showInfo(context, fix.isPaused ? "Match resumed" : "Match paused");
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.done_all_rounded, size: 16),
                            label: const Text('Save Result & Advance', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF154D36),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              final scA = int.tryParse(scoreACtrl.text.trim()) ?? fix.scoreA;
                              final scB = int.tryParse(scoreBCtrl.text.trim()) ?? fix.scoreB;
                              final wA = int.tryParse(wicketsACtrl.text.trim()) ?? fix.wicketsA;
                              final wB = int.tryParse(wicketsBCtrl.text.trim()) ?? fix.wicketsB;

                              ref.read(adminTournamentProvider.notifier).finishMatchAndAdvanceWinner(
                                    t.id,
                                    fix.id,
                                    scA,
                                    scB,
                                    selectedWinner,
                                    wicketsA: wA,
                                    wicketsB: wB,
                                    oversA: oversACtrl.text.trim(),
                                    oversB: oversBCtrl.text.trim(),
                                  );
                              Navigator.pop(ctx);
                              ToastUtils.showSuccess(context, "Match completed! Winner $selectedWinner advanced.");
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournState = ref.watch(adminTournamentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildExecutiveAppBar(context),
      body: Column(
        children: [
          // Custom Segmented Capsule Navigation Tabs
          _buildSegmentedTabCapsules(tournState),

          // Main View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTournamentDashboardTab(tournState),
                _buildCreateTournamentTab(),
                _buildLiveAndFixturesTab(tournState),
                _buildAnalyticsTab(tournState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. PRO EXECUTIVE APP BAR ---
  PreferredSizeWidget _buildExecutiveAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            context.go('/admin/dashboard');
          }
        },
        tooltip: 'Back to Dashboard',
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Championship & Leagues',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Flexible(
                child: Text(
                  'Live Fixture & Bracket Engine',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF154D36),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text(
              'New Tourney',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _tabController.animateTo(1),
          ),
        ),
      ],
    );
  }

  // --- 2. CUSTOM SEGMENTED CAPSULE TAB BAR ---
  Widget _buildSegmentedTabCapsules(AdminTournamentState tournState) {
    final tabs = [
      {'label': 'Tournaments (${tournState.tournaments.length})', 'icon': Icons.emoji_events_rounded},
      {'label': 'Create Tourney', 'icon': Icons.add_circle_outline_rounded},
      {'label': 'Live & Fixtures', 'icon': Icons.live_tv_rounded},
      {'label': 'Financials', 'icon': Icons.bar_chart_rounded},
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _tabController.index == index;
            final item = tabs[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  _tabController.animateTo(index);
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF154D36) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF154D36).withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 14,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // --- TAB 1: TOURNAMENT DASHBOARD & CARDS ---
  Widget _buildTournamentDashboardTab(AdminTournamentState tournState) {
    final filteredList = tournState.tournaments.where((t) {
      if (_activeFilter == 'Live Now') return t.status == 'Live';
      if (_activeFilter == 'Upcoming') return t.status == 'Upcoming';
      if (_activeFilter == 'Completed') return t.status == 'Completed';
      return true; // 'All'
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Bento Operations Card
          _buildHeroBentoOperations(tournState),
          const SizedBox(height: 16),

          // Filter Pills Bar
          _buildFilterPillsBar(tournState),
          const SizedBox(height: 14),

          // Tournaments List
          if (filteredList.isEmpty)
            _buildEmptyTournamentsState()
          else
            ...filteredList.map((t) => _buildProTournamentCard(t)),
        ],
      ),
    );
  }

  Widget _buildHeroBentoOperations(AdminTournamentState tournState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C2B1E), Color(0xFF154D36)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF154D36).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Tournament Command Hub',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE2E8F0),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                fit: FlexFit.loose,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'FIFA / ICC Standard',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${NumberFormat('#,##,###').format(tournState.totalRevenue.toInt())}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Gross Tournament Revenue • ${tournState.tournaments.length} Active Competitions',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),

          // Mini Metric Counter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeroMiniStat('Total', '${tournState.totalTournaments}', const Color(0xFFE2E8F0)),
                _buildStatDivider(),
                _buildHeroMiniStat('Live Now', '${tournState.liveCount}', const Color(0xFFF87171)),
                _buildStatDivider(),
                _buildHeroMiniStat('Upcoming', '${tournState.upcomingCount}', const Color(0xFF60A5FA)),
                _buildStatDivider(),
                _buildHeroMiniStat('Completed', '${tournState.completedCount}', const Color(0xFF4ADE80)),
                _buildStatDivider(),
                _buildHeroMiniStat('Teams', '${tournState.totalParticipants}', const Color(0xFFFBBF24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMiniStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 18, color: Colors.white.withValues(alpha: 0.15));
  }

  Widget _buildFilterPillsBar(AdminTournamentState tournState) {
    final filters = [
      {'label': 'All', 'count': tournState.totalTournaments, 'color': const Color(0xFF154D36)},
      {'label': 'Live Now', 'count': tournState.liveCount, 'color': const Color(0xFFDC2626)},
      {'label': 'Upcoming', 'count': tournState.upcomingCount, 'color': const Color(0xFF2563EB)},
      {'label': 'Completed', 'count': tournState.completedCount, 'color': const Color(0xFF16A34A)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f['label'];
          final color = f['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _activeFilter = f['label'] as String),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (f['label'] == 'Live Now' && isSelected) ...[
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      f['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${f['count']}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyTournamentsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF154D36).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_outlined, size: 36, color: Color(0xFF154D36)),
          ),
          const SizedBox(height: 12),
          Text(
            'No $_activeFilter Tournaments Found',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create your next championship or tournament to start accepting team registrations.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF154D36),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Create Tournament Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => _tabController.animateTo(1),
          ),
        ],
      ),
    );
  }

  Widget _buildProTournamentCard(TournamentModel t) {
    final isLive = t.status == 'Live';
    final progress = t.maxTeams > 0 ? (t.registeredTeamsCount / t.maxTeams).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLive ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0), width: isLive ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image & Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  t.bannerUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: const Color(0xFF154D36),
                    child: const Center(child: Icon(Icons.stadium_rounded, color: Colors.white, size: 40)),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Top Badges
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(t.sportType == 'Cricket' ? '🏏' : '⚽', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${t.sportType} • ${t.tournamentType}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLive ? const Color(0xFFDC2626) : const Color(0xFF154D36),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (isLive) ...[
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isLive ? 'LIVE NOW' : t.status.toUpperCase(),
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Title inside banner
              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${t.courtAllocation} • ${t.startDate} to ${t.endDate}',
                      style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Content Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prize Pool & Entry Fee Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 13),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                t.championPrize,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${t.teamEntryFee.toInt()} / Team',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Team Registration Progress (Interactive to inspect registered teams)
                InkWell(
                  onTap: () => _showRegisteredTeamsDialog(t),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.groups_rounded, size: 14, color: Color(0xFF154D36)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Registrations: ${t.registeredTeamsCount}/${t.maxTeams} Teams',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF154D36)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Squads (${t.registeredTeams.length})',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, size: 12, color: Color(0xFF15803D)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 0.8 ? const Color(0xFF16A34A) : const Color(0xFF154D36),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Action Bar - Row 1: Live Scores & Team Squads
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLive ? const Color(0xFFDC2626) : const Color(0xFF154D36),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.live_tv_rounded, size: 14),
                        label: Text(
                          isLive ? 'Live Controller' : 'Manage Live',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => _showLiveScoreDialog(t),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.groups_rounded, size: 14, color: Color(0xFF4ADE80)),
                        label: Text(
                          'Teams (${t.registeredTeams.length})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => _showRegisteredTeamsDialog(t),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Quick Action Bar - Row 2: Match Fixtures Engine & Delete Action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF154D36),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.account_tree_rounded, size: 14),
                        label: const Text(
                          'Match Fixtures & Brackets',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          _tabController.animateTo(2);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        ref.read(adminTournamentProvider.notifier).deleteTournament(t.id);
                        ToastUtils.showInfo(context, 'Tournament "${t.title}" deleted');
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(7.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: CREATE TOURNAMENT WIZARD ---
  Widget _buildCreateTournamentTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Basic Information
            _buildWizardCard(
              title: '1. Basic Tournament Information',
              icon: Icons.info_outline_rounded,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: _inputDecoration('Tournament Name *', 'e.g. Madurai Super Cup 2026', Icons.emoji_events_outlined),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subtitleCtrl,
                  decoration: _inputDecoration('Subtitle / Tagline', 'e.g. Under-19 League Championship', Icons.subtitles_outlined),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: _inputDecoration('Description', 'Provide details about the tournament...', Icons.description_outlined),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _rulesCtrl,
                  maxLines: 2,
                  decoration: _inputDecoration('Rules & Regulations', 'e.g. 8 overs per side, standard ICC rules...', Icons.gavel_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Section 2: Sport & Format Selection
            _buildWizardCard(
              title: '2. Sport & Format Setup',
              icon: Icons.sports_soccer_rounded,
              children: [
                const Text('Choose Sport Type:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _sportsList.map((s) {
                      final isSelected = _selectedSport == s['name'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          avatar: Text(s['emoji']!, style: const TextStyle(fontSize: 13)),
                          label: Text(s['name']!, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF154D36),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155)),
                          backgroundColor: const Color(0xFFF1F5F9),
                          onSelected: (val) {
                            if (val) setState(() => _selectedSport = s['name']!);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Tournament Format:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  isExpanded: true,
                  decoration: _inputDecoration('Select Format', '', Icons.alt_route_rounded),
                  items: _formatsList.map((f) {
                    return DropdownMenuItem(
                      value: f['name'],
                      child: Text('${f['name']} (${f['desc']})', style: const TextStyle(fontSize: 11.5), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCourt,
                  isExpanded: true,
                  decoration: _inputDecoration('Court Allocation', '', Icons.stadium_outlined),
                  items: ['Turf A (Football / Cricket)', 'Turf B (Box Cricket)', 'Badminton Court 1', 'Entire Venue']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCourt = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Section 3: Schedule & Deadlines
            _buildWizardCard(
              title: '3. Competition Dates & Deadlines',
              icon: Icons.calendar_month_rounded,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDateCapsuleButton(
                        label: 'Tournament Start',
                        date: _startDate,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _startDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateCapsuleButton(
                        label: 'Tournament End',
                        date: _endDate,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Color(0xFFDC2626), size: 16),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Registration Deadline', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                              Text(_formatDate(_regEndDate), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF991B1B))),
                            ],
                          ),
                        ],
                      ),
                      TextButton(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _regEndDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _regEndDate = picked);
                        },
                        child: const Text('Change Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Section 4: Teams & Financials
            _buildWizardCard(
              title: '4. Entry Fee, Teams & Prize Pool',
              icon: Icons.payments_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _entryFeeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Entry Fee (₹)', '1500', Icons.currency_rupee_rounded),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _maxTeamsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Max Teams', '12', Icons.groups_rounded),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _playersPerTeamCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Players Per Squad', '8 + 2 Substitutes', Icons.person_rounded),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _championPrizeCtrl,
                  decoration: _inputDecoration('Champion Prize 🏆', '₹15,000 Cash + Trophy', Icons.emoji_events_outlined),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _runnerUpPrizeCtrl,
                  decoration: _inputDecoration('Runner-Up Prize 🥈', '₹7,000 Cash', Icons.workspace_premium_outlined),
                ),
                const SizedBox(height: 12),

                // Projected Pool Calculation
                Builder(
                  builder: (context) {
                    final fee = double.tryParse(_entryFeeCtrl.text.trim()) ?? 0;
                    final teams = int.tryParse(_maxTeamsCtrl.text.trim()) ?? 0;
                    final gross = fee * teams;
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: Color(0xFF16A34A), size: 15),
                              SizedBox(width: 6),
                              Text('Projected Gross Pool:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                            ],
                          ),
                          Text('₹${NumberFormat('#,##,###').format(gross.toInt())}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF154D36),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: const Text(
                  'Publish Tournament & Reserve Slots',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: _submitCreateTournament,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF154D36)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 16, color: const Color(0xFF64748B)),
      labelStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
      hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF154D36), width: 1.5)),
    );
  }

  Widget _buildDateCapsuleButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, size: 16, color: Color(0xFF154D36)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                  Text(
                    _formatDate(date),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: LIVE & FIXTURES CONSOLE ---
  Widget _buildLiveAndFixturesTab(AdminTournamentState tournState) {
    if (tournState.tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.live_tv_rounded, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            const Text('No tournaments available to manage fixtures.', style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF154D36), foregroundColor: Colors.white),
              onPressed: () => _tabController.animateTo(1),
              child: const Text('Create Tournament'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Arena Console & Fixtures', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                    Text('Update scores & trigger knockouts in real-time.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sensors_rounded, color: Color(0xFF16A34A), size: 12),
                    SizedBox(width: 4),
                    Text('SYNC ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...tournState.tournaments.map((t) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF154D36).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t.tournamentType.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF154D36))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${t.sportType} • ${t.registeredTeams.length} Registered Teams • ${t.fixtures.length} Fixtures', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),

                  // Engine Selector Chips
                  const Text('⚡ Generate / Switch Fixture Engine:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF154D36))),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.alt_route_rounded, size: 12, color: Color(0xFF154D36)),
                          label: const Text('Seeded Knockout', style: TextStyle(fontSize: 10)),
                          onPressed: () {
                            ref.read(adminTournamentProvider.notifier).generateAdvancedFixtures(t.id, 'Seeded Knockout');
                            ToastUtils.showSuccess(context, "Generated Top Seed Protection Bracket for ${t.title}");
                          },
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          avatar: const Icon(Icons.shield_outlined, size: 12, color: Colors.amber),
                          label: const Text('Double Elimination', style: TextStyle(fontSize: 10)),
                          onPressed: () {
                            ref.read(adminTournamentProvider.notifier).generateAdvancedFixtures(t.id, 'Double Elimination');
                            ToastUtils.showSuccess(context, "Generated Double Elimination Bracket for ${t.title}");
                          },
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          avatar: const Icon(Icons.groups_rounded, size: 12, color: Colors.purple),
                          label: const Text('Group Stage + Knockout', style: TextStyle(fontSize: 10)),
                          onPressed: () {
                            ref.read(adminTournamentProvider.notifier).generateAdvancedFixtures(t.id, 'Group Stage + Knockout');
                            ToastUtils.showSuccess(context, "Generated Hybrid Group + Knockout for ${t.title}");
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (t.fixtures.isEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF154D36),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                        label: const Text('Auto-Generate Fixtures & Brackets', style: TextStyle(fontSize: 11.5)),
                        onPressed: () {
                          ref.read(adminTournamentProvider.notifier).generateFixtures(t.id);
                          ToastUtils.showSuccess(context, "Auto-generated Fixtures for ${t.title}");
                        },
                      ),
                    )
                  else ...[
                    // Interactive Visual Bracket View
                    const Text('🏆 Visual Tournament Bracket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF154D36))),
                    const SizedBox(height: 8),
                    TournamentBracketView(
                      tournament: t,
                      onMatchTap: (fix) => _showUpdateMatchResultDialog(t, fix),
                    ),
                    const SizedBox(height: 14),

                    // Fixture Match Console Cards
                    const Text('📋 Match Operations List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    ...t.fixtures.map((fix) {
                      final isLiveFix = fix.status == 'Live';
                      final hasWinner = fix.winnerTeam.isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isLiveFix ? const Color(0xFFFEF2F2) : (hasWinner ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isLiveFix ? const Color(0xFFFECDD3) : (hasWinner ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${fix.matchNumber} • ${fix.stage}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF154D36))),
                                      Text('${fix.teamA} vs ${fix.teamB}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                                      Text('${fix.timeSlot} • ${fix.courtName}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isLiveFix ? const Color(0xFFDC2626) : (hasWinner ? const Color(0xFF16A34A) : const Color(0xFF154D36)),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${fix.scoreA} - ${fix.scoreB}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () => _showUpdateMatchResultDialog(t, fix),
                                      child: const Text('Edit Score ➔', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF154D36))),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (hasWinner) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'WINNER: ${fix.winnerTeam} ${fix.nextMatchId != null ? "(Advanced ➔)" : "(CHAMPION 🥇)"}',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- TAB 4: ANALYTICS & FINANCIALS ---
  Widget _buildAnalyticsTab(AdminTournamentState tournState) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tournament Financial Performance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),

          // 2x2 Bento Financial Grid
          Row(
            children: [
              Expanded(child: _buildAnalyticsMetricCard('Gross Entry Fees', '₹${NumberFormat('#,##,###').format(tournState.totalRevenue.toInt())}', Icons.payments_rounded, const Color(0xFF154D36))),
              const SizedBox(width: 8),
              Expanded(child: _buildAnalyticsMetricCard('Total Competitions', '${tournState.totalTournaments}', Icons.emoji_events_rounded, const Color(0xFF0284C7))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildAnalyticsMetricCard('Participating Teams', '${tournState.totalParticipants}', Icons.groups_rounded, const Color(0xFFD97706))),
              const SizedBox(width: 8),
              Expanded(child: _buildAnalyticsMetricCard('Matches Concluded', '${tournState.completedCount}', Icons.task_alt_rounded, const Color(0xFF16A34A))),
            ],
          ),
          const SizedBox(height: 16),

          // Payout Breakdown Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Revenue & Settlement Split', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                _buildFinanceRow('Venue Net Share (90%)', '₹${NumberFormat('#,##,###').format((tournState.totalRevenue * 0.90).toInt())}', isBold: true),
                const Divider(height: 16),
                _buildFinanceRow('Platform & Tech Fee (10%)', '₹${NumberFormat('#,##,###').format((tournState.totalRevenue * 0.10).toInt())}'),
                const Divider(height: 16),
                _buildFinanceRow('Settlement Status', 'Settled to Bank (Direct Payout)', isStatus: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 1),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, {bool isBold = false, bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11.5, color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B), fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        if (isStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
            child: Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
          )
        else
          Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: const Color(0xFF0F172A))),
      ],
    );
  }
}
