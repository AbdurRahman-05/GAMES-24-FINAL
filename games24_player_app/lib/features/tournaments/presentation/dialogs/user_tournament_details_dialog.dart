import 'package:flutter/material.dart';
import 'package:games24_player_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/tournament_model.dart';
import '../../providers/tournament_provider.dart';
import '../widgets/tournament_bracket_view.dart';

class UserTournamentDetailsDialog extends ConsumerStatefulWidget {
  final TournamentModel tournament;

  const UserTournamentDetailsDialog({
    super.key,
    required this.tournament,
  });

  @override
  ConsumerState<UserTournamentDetailsDialog> createState() =>
      _UserTournamentDetailsDialogState();
}

class _UserTournamentDetailsDialogState
    extends ConsumerState<UserTournamentDetailsDialog> {
  final _teamNameCtrl = TextEditingController();
  final _captainNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _paymentMethod = 'UPI (GPay / PhonePe)';

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    _captainNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _showRegisterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                    const Text('Register Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _teamNameCtrl, decoration: const InputDecoration(labelText: 'Team Name *', prefixIcon: Icon(Icons.shield_outlined), border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextFormField(controller: _captainNameCtrl, decoration: const InputDecoration(labelText: 'Captain Name *', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
                const SizedBox(height: 14),

                const Text('Payment Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: ['UPI (GPay / PhonePe)', 'Credit / Debit Card', 'Pay at Venue']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => _paymentMethod = val);
                  },
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Entry Fee:'),
                      Text('₹${widget.tournament.teamEntryFee.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: AppButton(
                    text: 'Confirm Team Registration',
                    icon: Icons.check_circle_rounded,
                    onPressed: () {
                      if (_teamNameCtrl.text.trim().isEmpty || _captainNameCtrl.text.trim().isEmpty) {
                        ToastUtils.showError(context, "Please fill Team & Captain Name.");
                        return;
                      }

                      final newReg = TeamRegistrationModel(
                        id: 'reg_${DateTime.now().millisecondsSinceEpoch}',
                        teamName: _teamNameCtrl.text.trim(),
                        captainName: _captainNameCtrl.text.trim(),
                        captainPhone: _phoneCtrl.text.trim(),
                        captainEmail: _emailCtrl.text.trim(),
                        playerCount: widget.tournament.playersPerTeam,
                        paymentStatus: _paymentMethod == 'Pay at Venue' ? 'Pending' : 'Paid',
                        registrationDate: 'Today',
                      );

                      ref.read(adminTournamentProvider.notifier).registerTeam(widget.tournament.id, newReg);

                      Navigator.pop(ctx);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Team "${newReg.teamName}" registered successfully for ${widget.tournament.title}!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Image Banner
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      t.bannerUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.status == 'Live' ? Colors.red : AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        t.status == 'Live' ? '🔴 LIVE NOW' : 'STATUS: ${t.status.toUpperCase()}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(t.subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 14),

                    // Quick Stats Pill
                    Row(
                      children: [
                        _buildBadge(Icons.sports, t.sportType),
                        const SizedBox(width: 8),
                        _buildBadge(Icons.account_tree_outlined, t.tournamentType),
                        const SizedBox(width: 8),
                        _buildBadge(Icons.stadium_outlined, t.courtAllocation),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Entry Fee & Prize Pool Card
                    AppCard(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Team Entry Fee:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('₹${t.teamEntryFee.toInt()} / team', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Champion Prize:'),
                              Text(t.championPrize, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Runner-up Prize:'),
                              Text(t.runnerUpPrize, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            child: Text(
                              'Registration Deadline: Last Date to Register is ${t.regEndDate}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Live Score Box if active
                    if (t.liveScore.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🔴 REAL-TIME MATCH TICKER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                            const SizedBox(height: 4),
                            Text(t.liveScore, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                            if (t.liveCommentary.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('🎙️ "${t.liveCommentary}"', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Fixtures & UEFA Bracket Tree Section
                    if (t.fixtures.isNotEmpty) ...[
                      const Text('🏆 Live Tournament Bracket Tree', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                      const SizedBox(height: 8),
                      TournamentBracketView(tournament: t),
                      const SizedBox(height: 14),
                      const Text('📋 Match Schedule & Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Column(
                        children: t.fixtures.map((fix) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: fix.status == 'Live'
                                  ? Colors.red.shade50
                                  : (fix.winnerTeam.isNotEmpty ? Colors.green.shade50 : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(10),
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
                                          Text('${fix.teamA} vs ${fix.teamB}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                          Text('Time: ${fix.timeSlot} • ${fix.courtName}', style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: fix.status == 'Live' ? Colors.red : (fix.winnerTeam.isNotEmpty ? Colors.green : AppColors.primary),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(fix.getFormattedScore(t.sportType), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                if (fix.winnerTeam.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.emoji_events_rounded, color: Colors.green, size: 12),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'WINNER: ${fix.winnerTeam} ${fix.nextMatchId != null ? "(Advanced ➔)" : "(CHAMPION 🥇)"}',
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
                      const SizedBox(height: 14),
                    ],

                    // Points Table Standings if League format
                    if (t.standings.isNotEmpty) ...[
                      const Text('📊 Live Points Table Standings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 14,
                          headingRowHeight: 34,
                          dataRowMinHeight: 34,
                          dataRowMaxHeight: 38,
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
                      const SizedBox(height: 14),
                    ],

                    // Description & Rules
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(t.description, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    const SizedBox(height: 12),
                    const Text('Rules & Regulations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(t.rules, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),

                    // Sponsors Grid
                    if (t.sponsors.isNotEmpty) ...[
                      const Text('Official Sponsors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: t.sponsors.map((sp) {
                          return Chip(
                            avatar: CircleAvatar(backgroundImage: NetworkImage(sp.logoUrl)),
                            label: Text('${sp.name} (${sp.category})', style: const TextStyle(fontSize: 10)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: AppButton(
                        text: 'Register Team Now (₹${t.teamEntryFee.toInt()})',
                        icon: Icons.app_registration_rounded,
                        onPressed: () => _showRegisterSheet(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
