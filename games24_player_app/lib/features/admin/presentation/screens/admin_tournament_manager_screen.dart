import 'package:flutter/material.dart';
import 'package:games24_player_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../tournaments/data/models/tournament_model.dart';
import '../../../tournaments/providers/tournament_provider.dart';
import '../../../tournaments/presentation/widgets/tournament_bracket_view.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  void _submitCreateTournament() {
    if (_titleCtrl.text.trim().isEmpty) {
      ToastUtils.showError(context, "Please enter Tournament Name");
      return;
    }

    final todayStr = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    final newTournament = TournamentModel(
      id: 'tourn_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      subtitle: _subtitleCtrl.text.trim().isEmpty ? 'Open Championship' : _subtitleCtrl.text.trim(),
      bannerUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=800&q=80',
      logoUrl: 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?auto=format&fit=crop&w=150&q=80',
      description: _descCtrl.text.trim().isEmpty ? 'Official PlayHub Tournament' : _descCtrl.text.trim(),
      rules: _rulesCtrl.text.trim().isEmpty ? '1. Standard tournament rules apply.' : _rulesCtrl.text.trim(),
      organizerName: _organizerCtrl.text.trim(),
      contactPerson: 'Venue Manager',
      phone: _phoneCtrl.text.trim(),
      whatsapp: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
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
      championPrize: _championPrizeCtrl.text.trim(),
      runnerUpPrize: _runnerUpPrizeCtrl.text.trim(),
      status: 'Upcoming',
    );

    ref.read(adminTournamentProvider.notifier).addTournament(newTournament);

    // Auto Lock Court Slots in Admin Slot Provider
    ref.read(adminSlotProvider.notifier).reserveTournamentSlots(
      todayStr,
      ['08:00 AM - 09:00 AM', '09:00 AM - 10:00 AM', '10:00 AM - 11:00 AM', '05:00 PM - 06:00 PM'],
      newTournament.title,
    );

    _titleCtrl.clear();
    _subtitleCtrl.clear();
    _descCtrl.clear();
    _rulesCtrl.clear();

    _tabController.animateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tournament "${newTournament.title}" created & synced with user app!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showLiveScoreDialog(TournamentModel t) {
    _liveScoreCtrl.text = t.liveScore;
    _liveCommentaryCtrl.text = t.liveCommentary;

    showModalBottomSheet(
      context: context,
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
                    'Live Control - ${t.title}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _liveScoreCtrl,
              decoration: const InputDecoration(
                labelText: 'Live Score / Status',
                prefixIcon: Icon(Icons.sports_score_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _liveCommentaryCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Live Match Commentary Update',
                prefixIcon: Icon(Icons.record_voice_over_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Publish Live Update (Real-time Sync)',
                icon: Icons.cell_tower_rounded,
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

    final TextEditingController scoreACtrl = TextEditingController(text: '${fix.scoreA}');
    final TextEditingController scoreBCtrl = TextEditingController(text: '${fix.scoreB}');
    final TextEditingController wicketsACtrl = TextEditingController(text: '${fix.wicketsA}');
    final TextEditingController wicketsBCtrl = TextEditingController(text: '${fix.wicketsB}');
    final TextEditingController oversACtrl = TextEditingController(text: fix.oversA.isEmpty ? '0.0' : fix.oversA);
    final TextEditingController oversBCtrl = TextEditingController(text: fix.oversB.isEmpty ? '0.0' : fix.oversB);

    final TextEditingController playerCtrl = TextEditingController();
    final TextEditingController minuteCtrl = TextEditingController(text: isCricket ? '14.2 ov' : '14\'');

    List<String> eventOptions = isCricket
        ? ['Wicket', 'Six', 'Four', 'Fifty', 'Century', 'Wide', 'No Ball']
        : (isBadminton
            ? ['Ace', 'Smash Winner', 'Unforced Error', 'Set Point']
            : ['Goal', 'Yellow Card', 'Red Card', 'Penalty']);

    String selectedEventType = eventOptions.first;
    String selectedEventTeam = fix.teamA;
    String selectedWinner = fix.winnerTeam.isNotEmpty ? fix.winnerTeam : fix.teamA;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('${t.sportType} Match Console - ${fix.matchNumber}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: Icon(fix.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: AppColors.primary),
                    onPressed: () {
                      ref.read(adminTournamentProvider.notifier).togglePauseMatch(t.id, fix.id);
                      setDialogState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(fix.isPaused ? 'Match Resumed!' : 'Match Paused!')),
                      );
                    },
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stage: ${fix.stage} • ${fix.timeSlot} • Ref: ${fix.referee}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 12),

                    // Quick Score Controller with Sport-Specific Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(fix.teamA, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              TextField(
                                controller: scoreACtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(labelText: isCricket ? 'Runs A' : (isBadminton ? 'Sets A' : 'Goals A'), border: const OutlineInputBorder()),
                              ),
                              if (isCricket) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(child: TextField(controller: wicketsACtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wkts', border: OutlineInputBorder()))),
                                    const SizedBox(width: 4),
                                    Expanded(child: TextField(controller: oversACtrl, decoration: const InputDecoration(labelText: 'Overs', border: OutlineInputBorder()))),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                children: isCricket
                                    ? [
                                        OutlinedButton(onPressed: () { scoreACtrl.text = '${(int.tryParse(scoreACtrl.text) ?? 0) + 1}'; setDialogState(() {}); }, child: const Text('+1', style: TextStyle(fontSize: 9))),
                                        OutlinedButton(onPressed: () { scoreACtrl.text = '${(int.tryParse(scoreACtrl.text) ?? 0) + 4}'; setDialogState(() {}); }, child: const Text('+4', style: TextStyle(fontSize: 9))),
                                        OutlinedButton(onPressed: () { scoreACtrl.text = '${(int.tryParse(scoreACtrl.text) ?? 0) + 6}'; setDialogState(() {}); }, child: const Text('+6', style: TextStyle(fontSize: 9))),
                                        OutlinedButton(onPressed: () { wicketsACtrl.text = '${(int.tryParse(wicketsACtrl.text) ?? 0) + 1}'; setDialogState(() {}); }, child: const Text('+Wkt', style: TextStyle(fontSize: 9))),
                                      ]
                                    : [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.add, size: 12),
                                          label: Text(isBadminton ? '+1 Set' : '+1 Goal', style: const TextStyle(fontSize: 10)),
                                          onPressed: () {
                                            final val = (int.tryParse(scoreACtrl.text) ?? 0) + 1;
                                            scoreACtrl.text = '$val';
                                            setDialogState(() {});
                                          },
                                        ),
                                      ],
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.0),
                          child: Text('VS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(fix.teamB, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              TextField(
                                controller: scoreBCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(labelText: isCricket ? 'Runs B' : (isBadminton ? 'Sets B' : 'Goals B'), border: const OutlineInputBorder()),
                              ),
                              if (isCricket) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(child: TextField(controller: wicketsBCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wkts', border: OutlineInputBorder()))),
                                    const SizedBox(width: 4),
                                    Expanded(child: TextField(controller: oversBCtrl, decoration: const InputDecoration(labelText: 'Overs', border: OutlineInputBorder()))),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                children: isCricket
                                    ? [
                                        OutlinedButton(onPressed: () { scoreBCtrl.text = '${(int.tryParse(scoreBCtrl.text) ?? 0) + 1}'; setDialogState(() {}); }, child: const Text('+1', style: TextStyle(fontSize: 9))),
                                        OutlinedButton(onPressed: () { scoreBCtrl.text = '${(int.tryParse(scoreBCtrl.text) ?? 0) + 4}'; setDialogState(() {}); }, child: const Text('+4', style: TextStyle(fontSize: 9))),
                                        OutlinedButton(onPressed: () { scoreBCtrl.text = '${(int.tryParse(scoreBCtrl.text) ?? 0) + 6}'; setDialogState(() {}); }, child: const Text('+6', style: TextStyle(fontSize: 9))),
                                        OutlinedButton(onPressed: () { wicketsBCtrl.text = '${(int.tryParse(wicketsBCtrl.text) ?? 0) + 1}'; setDialogState(() {}); }, child: const Text('+Wkt', style: TextStyle(fontSize: 9))),
                                      ]
                                    : [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.add, size: 12),
                                          label: Text(isBadminton ? '+1 Set' : '+1 Goal', style: const TextStyle(fontSize: 10)),
                                          onPressed: () {
                                            final val = (int.tryParse(scoreBCtrl.text) ?? 0) + 1;
                                            scoreBCtrl.text = '$val';
                                            setDialogState(() {});
                                          },
                                        ),
                                      ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(),

                    // Match Event Logger Section
                    Text('⚡ Log ${t.sportType} Match Event', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedEventTeam,
                            decoration: const InputDecoration(labelText: 'Team', border: OutlineInputBorder()),
                            items: [fix.teamA, fix.teamB]
                                .map((team) => DropdownMenuItem(value: team, child: Text(team, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedEventTeam = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedEventType,
                            decoration: const InputDecoration(labelText: 'Event', border: OutlineInputBorder()),
                            items: eventOptions
                                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedEventType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: playerCtrl,
                            decoration: const InputDecoration(labelText: 'Player Name', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: minuteCtrl,
                            decoration: InputDecoration(labelText: isCricket ? 'Over' : 'Min (\')', border: const OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.flash_on_rounded, size: 16),
                      label: const Text('Add Live Event', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (playerCtrl.text.trim().isEmpty) return;
                        final event = MatchEvent(
                          id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
                          type: selectedEventType,
                          teamName: selectedEventTeam,
                          playerName: playerCtrl.text.trim(),
                          minute: minuteCtrl.text.trim().isEmpty ? (isCricket ? '14.2 ov' : '14\'') : minuteCtrl.text.trim(),
                          timestamp: DateTime.now().toString(),
                        );
                        ref.read(adminTournamentProvider.notifier).addMatchEvent(t.id, fix.id, event);
                        playerCtrl.clear();
                        setDialogState(() {});
                        ToastUtils.showSuccess(context, "Logged ${event.type} for ${event.playerName}!");
                      },
                    ),

                    if (fix.events.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text('Live Match Timeline:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Column(
                        children: fix.events.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Text('${e.minute} ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                                Text('• ${e.teamName}: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                Text('${e.type} by ${e.playerName}', style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 14),
                    const Divider(),

                    // Winner Selection & Auto Progression
                    const Text('Declare Final Match Winner:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedWinner,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: [fix.teamA, fix.teamB, 'Draw']
                          .map((team) => DropdownMenuItem(value: team, child: Text(team)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedWinner = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    if (fix.nextMatchId != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_fix_high_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Finishing match will automatically advance winner to the next round!',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final scA = int.tryParse(scoreACtrl.text.trim()) ?? 0;
                    final scB = int.tryParse(scoreBCtrl.text.trim()) ?? 0;
                    final wA = int.tryParse(wicketsACtrl.text.trim()) ?? 0;
                    final wB = int.tryParse(wicketsBCtrl.text.trim()) ?? 0;
                    final oA = oversACtrl.text.trim();
                    final oB = oversBCtrl.text.trim();
                    final winner = selectedWinner == 'Draw' ? '' : selectedWinner;

                    ref.read(adminTournamentProvider.notifier).finishMatchAndAdvanceWinner(
                          t.id,
                          fix.id,
                          scA,
                          scB,
                          winner,
                          wicketsA: wA,
                          wicketsB: wB,
                          oversA: oA,
                          oversB: oB,
                        );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Finished Match ${fix.matchNumber}! ${winner.isNotEmpty ? "$winner advanced to Next Round 🏆" : ""}')),
                    );
                  },
                  child: const Text('Finish Match & Advance Winner'),
                ),
              ],
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
      appBar: AppBar(
        title: const Text('Tournament Management Hub'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/admin/dashboard');
            }
          },
          tooltip: 'Back to Dashboard',
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events_rounded), text: 'Tournaments'),
            Tab(icon: Icon(Icons.add_circle_outline_rounded), text: 'Create Tournament'),
            Tab(icon: Icon(Icons.live_tv_rounded), text: 'Live & Fixtures'),
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Tournament Dashboard & List
          _buildTournamentDashboardTab(tournState),

          // Tab 2: Create Tournament Wizard Form
          _buildCreateTournamentTab(),

          // Tab 3: Live Score Controller & Fixture Brackets
          _buildLiveAndFixturesTab(tournState),

          // Tab 4: Analytics & Revenue Summary
          _buildAnalyticsTab(tournState),
        ],
      ),
    );
  }

  Widget _buildTournamentDashboardTab(AdminTournamentState tournState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Summary Grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildKpiCard('Total Tournaments', '${tournState.totalTournaments}', Icons.emoji_events_rounded, Colors.purple),
              _buildKpiCard('Live Tournaments', '${tournState.liveCount}', Icons.sensors_rounded, Colors.red),
              _buildKpiCard('Upcoming', '${tournState.upcomingCount}', Icons.upcoming_rounded, Colors.blue),
              _buildKpiCard('Completed', '${tournState.completedCount}', Icons.task_alt_rounded, Colors.green),
              _buildKpiCard('Total Participants', '${tournState.totalParticipants}', Icons.groups_rounded, Colors.orange),
              _buildKpiCard('Total Revenue', '₹${tournState.totalRevenue.toInt()}', Icons.payments_rounded, Colors.teal),
              _buildKpiCard('Pending Approvals', '${tournState.pendingApprovals}', Icons.pending_actions_rounded, Colors.amber.shade800),
              _buildKpiCard('Available Slots', '${tournState.availableSlots}', Icons.event_seat_rounded, Colors.indigo),
            ],
          ),
          const SizedBox(height: 20),

          // Status Filter Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Active Tournaments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Tournament', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _tabController.animateTo(1),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tournament List Cards
          if (tournState.tournaments.isEmpty)
            const Center(child: Text('No tournaments created yet.'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tournState.tournaments.length,
              itemBuilder: (ctx, idx) {
                final t = tournState.tournaments[idx];
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(t.bannerUrl, width: 70, height: 70, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        t.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: t.status == 'Live'
                                            ? Colors.red.withValues(alpha: 0.15)
                                            : AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        t.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: t.status == 'Live' ? Colors.red : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('${t.sportType} • ${t.tournamentType} • ${t.courtAllocation}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text('Teams: ${t.registeredTeamsCount}/${t.maxTeams} • Fee: ₹${t.teamEntryFee.toInt()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (t.liveScore.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text('🔴 LIVE SCORE: ${t.liveScore}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.cell_tower, size: 14),
                            label: const Text('Live Score', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _showLiveScoreDialog(t),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.account_tree_rounded, size: 14),
                            label: const Text('Fixtures', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              ref.read(adminTournamentProvider.notifier).generateFixtures(t.id);
                              ToastUtils.showSuccess(context, "Generated Knockout Fixtures for ${t.title}");
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                            onPressed: () {
                              ref.read(adminTournamentProvider.notifier).deleteTournament(t.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTournamentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Basic Information
            _buildFormSectionHeader('1. Basic Tournament Information', Icons.info_outline),
            const SizedBox(height: 8),
            TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Tournament Name *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextFormField(controller: _subtitleCtrl, decoration: const InputDecoration(labelText: 'Subtitle / Tagline', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextFormField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextFormField(controller: _rulesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Rules & Guidelines', border: OutlineInputBorder())),
            const SizedBox(height: 16),

            // Section 2: Sport & Format
            _buildFormSectionHeader('2. Sport & Tournament Format', Icons.sports),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSport,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Sport Type', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                    items: ['Cricket', 'Football', 'Futsal', 'Volleyball', 'Basketball', 'Badminton', 'Tennis']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedSport = val!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Tournament Format', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                    items: ['Knockout', 'Seeded Knockout', 'Double Elimination', 'Group Stage + Knockout', 'Round Robin']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedCourt,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Court Allocation', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
              items: ['Turf A (Football / Cricket)', 'Turf B (Box Cricket)', 'Badminton Court 1', 'Entire Venue']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCourt = val!),
            ),
            const SizedBox(height: 16),

            // Section 3: Tournament Dates & Registration Deadline
            _buildFormSectionHeader('3. Tournament Dates & Registration Deadline', Icons.calendar_month_rounded),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Start Date', style: TextStyle(fontSize: 8.5, color: Colors.grey)),
                              Text(_formatDate(_startDate), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_available_rounded, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('End Date', style: TextStyle(fontSize: 8.5, color: Colors.grey)),
                              Text(_formatDate(_endDate), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.red, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Last Date for Registration', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.red)),
                        Text(_formatDate(_regEndDate), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                      ],
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 30)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _regEndDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _regEndDate = picked);
                    },
                    child: const Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 4: Pricing & Team Settings
            _buildFormSectionHeader('4. Entry Fee & Team Settings', Icons.payments_outlined),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _entryFeeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fee (₹)', hintText: '1500', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)))),
                const SizedBox(width: 6),
                Expanded(child: TextFormField(controller: _maxTeamsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Teams', hintText: '12', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)))),
                const SizedBox(width: 6),
                Expanded(child: TextFormField(controller: _playersPerTeamCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Players', hintText: '8', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)))),
              ],
            ),
            const SizedBox(height: 16),

            // Section 5: Prizes
            _buildFormSectionHeader('5. Prize Pool & Awards', Icons.workspace_premium_outlined),
            const SizedBox(height: 8),
            TextFormField(controller: _championPrizeCtrl, decoration: const InputDecoration(labelText: 'Champion Prize 🏆', hintText: 'e.g. ₹15,000 Cash + Trophy', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextFormField(controller: _runnerUpPrizeCtrl, decoration: const InputDecoration(labelText: 'Runner-up Prize 🥈', hintText: 'e.g. ₹7,000 Cash', border: OutlineInputBorder())),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: AppButton(
                text: 'Publish Tournament & Lock Slots',
                icon: Icons.rocket_launch_rounded,
                onPressed: _submitCreateTournament,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveAndFixturesTab(AdminTournamentState tournState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
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
                    Text('📺 Live Match Controller & Bracket Fixtures', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('Update match scores & view generated fixtures in real time.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sensors_rounded, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Text('REAL-TIME SYNC', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...tournState.tournaments.map((t) {
            return AppCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t.tournamentType.toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Sport: ${t.sportType} • Registered Teams: ${t.registeredTeams.length} • Fixtures: ${t.fixtures.length} matches generated', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),

                  // Format Selector Action Chips
                  const Text('⚡ Switch / Re-generate Advanced Fixture Engine:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.alt_route_rounded, size: 14, color: AppColors.primary),
                        label: const Text('Seeded Knockout', style: TextStyle(fontSize: 10)),
                        onPressed: () {
                          ref.read(adminTournamentProvider.notifier).generateAdvancedFixtures(t.id, 'Seeded Knockout');
                          ToastUtils.showSuccess(context, "Generated Top Seed Protection Bracket for ${t.title}");
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.shield_outlined, size: 14, color: Colors.amber),
                        label: const Text('Double Elimination', style: TextStyle(fontSize: 10)),
                        onPressed: () {
                          ref.read(adminTournamentProvider.notifier).generateAdvancedFixtures(t.id, 'Double Elimination');
                          ToastUtils.showSuccess(context, "Generated Double Elimination (Winners & Losers Brackets) for ${t.title}");
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.groups_rounded, size: 14, color: Colors.purple),
                        label: const Text('Group Stage + Knockout', style: TextStyle(fontSize: 10)),
                        onPressed: () {
                          ref.read(adminTournamentProvider.notifier).generateAdvancedFixtures(t.id, 'Group Stage + Knockout');
                          ToastUtils.showSuccess(context, "Generated Group Stage + Knockout Hybrid Fixtures for ${t.title}");
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (t.fixtures.isEmpty)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Auto-Generate Fixtures & Brackets'),
                      onPressed: () {
                        ref.read(adminTournamentProvider.notifier).generateFixtures(t.id);
                        ToastUtils.showSuccess(context, "Auto-generated Brackets & Bye rounds for ${t.title}");
                      },
                    )
                  else ...[
                    // FIFA/UEFA Interactive Visual Bracket Tree
                    const Text('🏆 Visual Tournament Bracket Tree', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    TournamentBracketView(
                      tournament: t,
                      onMatchTap: (fix) => _showUpdateMatchResultDialog(t, fix),
                    ),
                    const SizedBox(height: 16),
                    const Text('📋 Match Console List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Column(
                      children: t.fixtures.map((fix) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: fix.status == 'Live'
                                ? Colors.red.shade50
                                : (fix.winnerTeam.isNotEmpty ? Colors.green.shade50 : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: fix.status == 'Live'
                                  ? Colors.red
                                  : (fix.winnerTeam.isNotEmpty ? Colors.green : Colors.grey.shade300),
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
                                        Text('${fix.matchNumber} (${fix.stage})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        const SizedBox(height: 2),
                                        Text('${fix.teamA} vs ${fix.teamB}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                                        Text('Time: ${fix.timeSlot} • Court: ${fix.courtName}', style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: fix.status == 'Live' ? Colors.red : (fix.winnerTeam.isNotEmpty ? Colors.green : AppColors.primary),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('${fix.scoreA} - ${fix.scoreB}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () => _showUpdateMatchResultDialog(t, fix),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('Edit Score & Winner ➔', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (fix.winnerTeam.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.emoji_events_rounded, color: Colors.green, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'WINNER: ${fix.winnerTeam} ${fix.nextMatchId != null ? "(Advanced to Next Round ➔)" : "(TOURNAMENT CHAMPION 🥇)"}',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    if (t.standings.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('📊 Live Points Table Standings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 16,
                          headingRowHeight: 36,
                          dataRowMinHeight: 36,
                          dataRowMaxHeight: 40,
                          columns: const [
                            DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            DataColumn(label: Text('Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            DataColumn(label: Text('P', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            DataColumn(label: Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            DataColumn(label: Text('L', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            DataColumn(label: Text('D', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            DataColumn(label: Text('GD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            DataColumn(label: Text('PTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          ],
                          rows: t.standings.asMap().entries.map((entry) {
                            final idx = entry.key + 1;
                            final row = entry.value;
                            return DataRow(
                              cells: [
                                DataCell(Text('$idx', style: const TextStyle(fontSize: 11))),
                                DataCell(Text(row.teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                DataCell(Text('${row.played}', style: const TextStyle(fontSize: 11))),
                                DataCell(Text('${row.won}', style: const TextStyle(fontSize: 11, color: Colors.green))),
                                DataCell(Text('${row.lost}', style: const TextStyle(fontSize: 11, color: Colors.red))),
                                DataCell(Text('${row.drawn}', style: const TextStyle(fontSize: 11))),
                                DataCell(Text('${row.goalDifference}', style: const TextStyle(fontSize: 11))),
                                DataCell(Text('${row.points}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(AdminTournamentState tournState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📈 Tournament Analytics & Financials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Revenue Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Gross Registrations:'),
                    Text('₹${tournState.totalRevenue.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Platform & GST Deduction:'),
                    Text('₹${(tournState.totalRevenue * 0.18).toInt()}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Net Venue Profit:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹${(tournState.totalRevenue * 0.82).toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Participation Conversion Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: tournState.totalTournaments == 0 ? 0 : (tournState.totalParticipants / 200).clamp(0.0, 1.0),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                  backgroundColor: Colors.grey.shade200,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                Text('${tournState.totalParticipants} Players Registered across ${tournState.totalTournaments} tournaments', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
