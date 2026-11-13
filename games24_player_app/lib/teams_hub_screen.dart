import 'main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:games24_player_app/team_roster_screen.dart';
import 'package:games24_player_app/team_manager.dart';
import 'package:games24_player_app/match_score_manager.dart';
import 'package:games24_player_app/contacts_picker_sheet.dart';

class TeamsHubScreen extends StatefulWidget {
  const TeamsHubScreen({super.key});

  @override
  State<TeamsHubScreen> createState() => _TeamsHubScreenState();
}

class _TeamsHubScreenState extends State<TeamsHubScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _myPlayerId = 'PLY-1001';
  List<TeamInvitation> _incomingInvitations = [];
  bool _loadingInvitations = false;

  @override
  void initState() {
    super.initState();
    _loadPlayerId();
    _loadInvitations();
  }

  Future<void> _loadPlayerId() async {
    final pid = await TeamManager.getCurrentPlayerId();
    if (mounted) {
      setState(() => _myPlayerId = pid);
    }
  }

  Future<void> _loadInvitations() async {
    if (mounted) setState(() => _loadingInvitations = true);
    final list = await TeamManager().fetchMyInvitations();
    if (mounted) {
      setState(() {
        _incomingInvitations = list;
        _loadingInvitations = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showCreateTeamDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedSport = 'Football';
    String selectedFormat = '7v7 Squad';
    final List<PlayerItem> selectedMembers = [
      PlayerItem(
        id: 'me',
        name: 'You',
        phone: '+91 70103 96731',
        role: 'Captain',
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5F5EB),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.group_add_rounded,
                                  color: Color(0xFF154D36),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Create New Squad',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Squad Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Thunder Warriors FC',
                          filled: true,
                          fillColor: const Color(0xFFF3F5F1),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sport',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['Football', 'Cricket', 'Badminton'].map((sport) {
                          final isSel = selectedSport == sport;
                          return ChoiceChip(
                            label: Text(sport),
                            selected: isSel,
                            selectedColor: const Color(0xFFE5F5EB),
                            labelStyle: TextStyle(
                              color: isSel ? const Color(0xFF154D36) : Colors.black87,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  selectedSport = sport;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Format / Squad Size',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          '5v5 Squad',
                          '7v7 Squad',
                          '11v11 Squad',
                          'Box Cricket',
                          'Doubles',
                        ].map((fmt) {
                          final isSel = selectedFormat == fmt;
                          return ChoiceChip(
                            label: Text(fmt),
                            selected: isSel,
                            selectedColor: const Color(0xFFE5F5EB),
                            labelStyle: TextStyle(
                              color: isSel ? const Color(0xFF154D36) : Colors.black87,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  selectedFormat = fmt;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // MOBILE CONTACTS & PLAYERS SECTION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Squad Players',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5F5EB),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${selectedMembers.length} selected',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF154D36),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF154D36),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              ContactsPickerSheet.show(
                                context,
                                alreadySelected: selectedMembers,
                                sport: selectedSport,
                                onImport: (newContacts) {
                                  setModalState(() {
                                    for (final c in newContacts) {
                                      if (!selectedMembers.any((m) => m.phone == c.phone && m.name == c.name)) {
                                        selectedMembers.add(c);
                                      }
                                    }
                                  });
                                },
                              );
                            },
                            icon: const Icon(Icons.contacts_rounded, size: 14),
                            label: const Text(
                              'Import Contacts',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Player list / chips
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: selectedMembers.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No contacts imported. Tap "Import Contacts" to choose players from phone.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selectedMembers.map((member) {
                                  final isCaptain = member.role.toLowerCase().contains('captain');
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isCaptain ? const Color(0xFFE5F5EB) : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isCaptain ? const Color(0xFFBBE5CA) : const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 11,
                                          backgroundColor:
                                              isCaptain ? const Color(0xFF154D36) : const Color(0xFF9CA3AF),
                                          child: Text(
                                            member.avatarInitials,
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          member.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: isCaptain ? const Color(0xFF154D36) : const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            member.role,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isCaptain ? Colors.white : Colors.black54,
                                            ),
                                          ),
                                        ),
                                        if (member.id != 'me') ...[
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () {
                                              setModalState(() {
                                                selectedMembers.removeWhere((m) => m.id == member.id);
                                              });
                                            },
                                            child: const Icon(Icons.close, size: 14, color: Colors.grey),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF154D36),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a team name'),
                                ),
                              );
                              return;
                            }
                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            await TeamManager().createTeam(
                              name: name,
                              sport: selectedSport,
                              squadSize: selectedFormat,
                              members: selectedMembers,
                            );
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Team "$name" created with ${selectedMembers.length} squad players!'),
                                backgroundColor: const Color(0xFF154D36),
                              ),
                            );
                          },
                          child: Text(
                            'Create Squad (${selectedMembers.length} Players)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showInvitePlayerDialog(BuildContext context, {PlayerTeam? preselectedTeam}) {
    final teams = TeamManager().teams;
    if (teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a squad first before inviting players!')),
      );
      return;
    }

    PlayerTeam chosenTeam = preselectedTeam ?? teams.first;
    final idController = TextEditingController();
    String selectedRole = 'Player';
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    Map<String, dynamic>? selectedPlayer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5F5EB),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF154D36), size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Invite Player by ID',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Select Team
                      const Text('Choose Squad to Invite Into', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: chosenTeam.id,
                            isExpanded: true,
                            items: teams.map((t) {
                              return DropdownMenuItem(
                                value: t.id,
                                child: Text('${t.name} (${t.teamCode} • ${t.sport})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() {
                                  chosenTeam = teams.firstWhere((t) => t.id == val);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Enter Player ID / Phone
                      const Text('Target Player ID or Mobile Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: TextField(
                          controller: idController,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (val) async {
                            if (val.trim().length >= 2) {
                              setSheetState(() => isSearching = true);
                              final res = await TeamManager().searchPlayers(val.trim());
                              setSheetState(() {
                                searchResults = res;
                                isSearching = false;
                              });
                            } else {
                              setSheetState(() {
                                searchResults = [];
                                isSearching = false;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'e.g. PLY-0005 or 9876543210',
                            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                            prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF154D36)),
                            suffixIcon: isSearching
                                ? const SizedBox(width: 16, height: 16, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),

                      if (searchResults.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: searchResults.map((p) {
                              final pId = p['playerId']?.toString() ?? '';
                              final name = p['fullName']?.toString() ?? 'Player';
                              final sport = p['preferredSport']?.toString() ?? 'Sports';
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: const Color(0xFF154D36),
                                  child: Text(name.isNotEmpty ? name[0] : 'P', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                ),
                                title: Text('$name ($pId)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                subtitle: Text('Sport: $sport', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF154D36),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    setSheetState(() {
                                      selectedPlayer = p;
                                      idController.text = pId;
                                      searchResults = [];
                                    });
                                  },
                                  child: const Text('Select', style: TextStyle(fontSize: 11)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Player Role
                      const Text('Role in Squad', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: ['Player', 'Vice Captain', 'Striker', 'Bowler', 'Midfielder', 'Goalkeeper'].map((r) {
                          final isSelected = selectedRole == r;
                          return ChoiceChip(
                            label: Text(r),
                            selected: isSelected,
                            selectedColor: const Color(0xFFE5F5EB),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF154D36) : Colors.black87,
                            ),
                            onSelected: (val) {
                              if (val) setSheetState(() => selectedRole = r);
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF154D36),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final targetId = idController.text.trim().toUpperCase();
                            if (targetId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a target Player ID')),
                              );
                              return;
                            }

                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);

                            await TeamManager().sendTeamInvitation(
                              senderTeamId: chosenTeam.id,
                              senderTeamCode: chosenTeam.teamCode,
                              senderTeamName: chosenTeam.name,
                              senderTeamSport: chosenTeam.sport,
                              targetPlayerId: targetId,
                              targetName: selectedPlayer?['fullName']?.toString(),
                              targetPhone: selectedPlayer?['mobileNumber']?.toString(),
                              role: selectedRole,
                            );

                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Squad invitation sent to $targetId for ${chosenTeam.name}! 🚀'),
                                backgroundColor: const Color(0xFF154D36),
                              ),
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Send Squad Invitation 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showChallengeTeamDialog(BuildContext context, PlayerTeam myTeam) {
    final opponentCodeController = TextEditingController();
    final opponentNameController = TextEditingController();
    String selectedSlot = '07:00 PM - 08:00 PM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.sports_kabaddi, color: Color(0xFFB45309), size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Challenge Team to Match',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield, color: Color(0xFF154D36), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Challenger: ${myTeam.name} (${myTeam.teamCode} • ${myTeam.sport})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('Opponent Team ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: opponentCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. TM-1042',
                          prefixIcon: const Icon(Icons.tag, size: 18, color: Color(0xFF154D36)),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text('Opponent Team Name (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: opponentNameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Thunder Strikers',
                          prefixIcon: const Icon(Icons.sports, size: 18, color: Color(0xFF154D36)),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text('Match Time Slot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: ['06:00 PM - 07:00 PM', '07:00 PM - 08:00 PM', '08:00 PM - 09:00 PM', '09:00 PM - 10:00 PM'].map((slot) {
                          final isSelected = selectedSlot == slot;
                          return ChoiceChip(
                            label: Text(slot, style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            selectedColor: const Color(0xFFE5F5EB),
                            onSelected: (val) {
                              if (val) setSheetState(() => selectedSlot = slot);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF154D36),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final oppCode = opponentCodeController.text.trim().toUpperCase();
                            if (oppCode.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter an Opponent Team ID')),
                              );
                              return;
                            }

                            final oppName = opponentNameController.text.trim().isNotEmpty
                                ? opponentNameController.text.trim()
                                : 'Team $oppCode';

                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);

                            await TeamManager().scheduleTeamMatch(
                              challengerTeamId: myTeam.teamCode,
                              challengerTeamName: myTeam.name,
                              opponentTeamId: oppCode,
                              opponentTeamName: oppName,
                              sport: myTeam.sport,
                              timeSlot: selectedSlot,
                            );

                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Challenge sent to $oppName ($oppCode)! Scheduled for $selectedSlot.'),
                                backgroundColor: const Color(0xFF154D36),
                              ),
                            );
                          },
                          icon: const Icon(Icons.sports_kabaddi_rounded, size: 18),
                          label: const Text('Send Match Challenge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleJoinTeam() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a squad passcode or PIN')),
      );
      return;
    }
    final success = await TeamManager().joinTeamWithCode(code);
    if (success && mounted) {
      _codeController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined squad "$code" successfully!'),
          backgroundColor: const Color(0xFF154D36),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildPlayerIdBanner(),
              const SizedBox(height: 14),
              _buildIncomingInvitationsSection(),
              const SizedBox(height: 14),
              _buildCreateTeamCard(),
              const SizedBox(height: 16),
              _buildJoinTeamCard(),
              const SizedBox(height: 24),
              _buildYourTeamsSection(context),
              const SizedBox(height: 24),
              _buildRecruitingSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerIdBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF154D36), Color(0xFF0F3D2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF154D36).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.badge_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Your Official Player ID',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Share to Join Squads & Matches',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _myPlayerId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Player ID $_myPlayerId copied to clipboard'),
                    backgroundColor: const Color(0xFF154D36),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF154D36)),
                    const SizedBox(width: 4),
                    Text(
                      _myPlayerId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF154D36),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingInvitationsSection() {
    if (_incomingInvitations.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Squad Invitations & Requests',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      '${_incomingInvitations.length} Pending',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
              _loadingInvitations
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF154D36)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF154D36)),
                      onPressed: _loadInvitations,
                    ),
            ],
          ),
          const SizedBox(height: 8),
          ..._incomingInvitations.map((inv) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5F5EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.group_add_rounded, color: Color(0xFF154D36), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inv.senderTeamName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${inv.senderTeamSport} • Captain: ${inv.senderName}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F5EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        inv.role,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF154D36)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final ok = await TeamManager().respondToInvitation(inv.id, false);
                          if (ok && mounted) {
                            _loadInvitations();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invitation declined')),
                            );
                          }
                        },
                        icon: const Icon(Icons.close_rounded, size: 14),
                        label: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF154D36),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final ok = await TeamManager().respondToInvitation(inv.id, true, invitation: inv);
                          if (ok && mounted) {
                            _loadInvitations();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Joined ${inv.senderTeamName} successfully!'),
                                backgroundColor: const Color(0xFF154D36),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 14),
                        label: const Text('Accept & Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainLayout()),
                  );
                }
              },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Teams Hub',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage squads & match rosters',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search squads feature active')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(
                    Icons.search,
                    size: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scan squad QR code')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FDF9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5F5EB)),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 18,
                    color: Color(0xFF154D36),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTeamCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7FDF9),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(120),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F5F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.group_add_outlined,
                          color: Color(0xFF154D36),
                          size: 24,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF86EFAC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Fast Setup',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14532D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Create New Team',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Form your squad, pick home turf & lead tournaments',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateTeamDialog(context),
                      icon: const Text(
                        'Create Squad',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      label: const Icon(Icons.arrow_forward, size: 16),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154D36),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinTeamCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.key_outlined,
                    color: Colors.black54,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Join with PIN / Code',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Got a 6-digit squad passcode?',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.key,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        hintText: 'E.G. STRK-24',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _handleJoinTeam,
                    icon: const Text(
                      'Join',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    label: const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF154D36),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourTeamsSection(BuildContext context) {
    return ValueListenableBuilder<List<PlayerTeam>>(
      valueListenable: TeamManager().teamsNotifier,
      builder: (context, teams, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Your Teams',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          teams.length.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (teams.isNotEmpty)
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF154D36),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF154D36),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (teams.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5F5EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.groups_outlined,
                          size: 32,
                          color: Color(0xFF154D36),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No Teams Joined Yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Create your squad or enter a team passcode above to get started with match tracking and rosters.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...teams.map(
                (team) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildTeamCard(
                    context: context,
                    team: team,
                    sportIcon: team.sport == 'Cricket'
                        ? Icons.sports_cricket
                        : (team.sport == 'Badminton'
                            ? Icons.sports_tennis
                            : Icons.sports_soccer),
                    teamName: team.name,
                    roleBadge: team.roleBadge,
                    isCaptain: team.isCaptain,
                    sportDetail: '${team.sport} • ${team.squadSize}',
                    membersCount: team.membersCount.toString(),
                    winsCount: team.winsCount.toString(),
                    rating: team.rating,
                    avatarsCount: '+${team.membersCount > 1 ? (team.membersCount - 1).toString() : '0'}',
                    dateText: team.dateText,
                    nextMatchText: team.nextMatchText,
                    nextMatchTime: team.nextMatchTime,
                    buttonText: 'View Roster & Strategy',
                    onTapDetails: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamRosterScreen(team: team),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTeamCard({
    required BuildContext context,
    required PlayerTeam team,
    required IconData sportIcon,
    required String teamName,
    required String roleBadge,
    required bool isCaptain,
    required String sportDetail,
    required String membersCount,
    required String winsCount,
    required String rating,
    required String avatarsCount,
    required String dateText,
    String? nextMatchText,
    String? nextMatchTime,
    required String buttonText,
    required VoidCallback onTapDetails,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5F5EB),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        teamName.isNotEmpty ? teamName[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF154D36),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF154D36),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(sportIcon, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              teamName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCaptain
                                  ? const Color(0xFFF7FDF9)
                                  : const Color(0xFFF3F4F6),
                              border: Border.all(
                                color: isCaptain
                                    ? const Color(0xFFE5F5EB)
                                    : const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCaptain
                                      ? Icons.military_tech_outlined
                                      : Icons.shield_outlined,
                                  size: 12,
                                  color: isCaptain
                                      ? const Color(0xFF154D36)
                                      : const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  roleBadge,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isCaptain
                                        ? const Color(0xFF154D36)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sportDetail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_outlined, size: 10, color: Color(0xFF154D36)),
                                const SizedBox(width: 3),
                                Text(
                                  team.teamCode,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF154D36),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: team.teamCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Team ID ${team.teamCode} copied!'),
                                        backgroundColor: const Color(0xFF154D36),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.copy_rounded, size: 10, color: Color(0xFF154D36)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(membersCount, 'Members'),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFE5E7EB),
                  ),
                  _buildStatItem(winsCount, 'Wins'),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFE5E7EB),
                  ),
                  _buildStatItem(rating, 'Rating', isRating: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildAvatarStack(),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        avatarsCount,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (nextMatchText != null) ...[
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Color(0xFF154D36),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ] else ...[
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (nextMatchText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: Color(0xFF154D36),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nextMatchText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      nextMatchTime ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF154D36),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onTapDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F5F1),
                  foregroundColor: const Color(0xFF154D36),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF154D36),
                      side: const BorderSide(color: Color(0xFFBBF7D0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _showInvitePlayerDialog(context, preselectedTeam: team),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 14),
                    label: const Text('Invite by ID', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF154D36),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                    ),
                    onPressed: () => _showChallengeTeamDialog(context, team),
                    icon: const Icon(Icons.sports_kabaddi, size: 14),
                    label: const Text('Challenge', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label, {
    Color valueColor = Colors.black87,
    bool isRating = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isRating ? const Color(0xFFD97706) : valueColor,
              ),
            ),
            if (isRating) ...[
              const SizedBox(width: 2),
              const Icon(
                Icons.star_outline,
                size: 14,
                color: Color(0xFFD97706),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildAvatarStack() {
    return SizedBox(
      width: 60,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: _buildAvatarCircle('A', const Color(0xFF10B981)),
          ),
          Positioned(
            left: 18,
            child: _buildAvatarCircle('B', const Color(0xFF3B82F6)),
          ),
          Positioned(
            left: 36,
            child: _buildAvatarCircle('C', const Color(0xFFF59E0B)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle(String label, Color bg) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRecruitingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Recruiting Near You',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Teams looking for players tonight',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              const Text(
                'View All (5)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF154D36),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        size: 24,
                        color: Color(0xFF154D36),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Metro Eagles',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '2 Slots',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Seeking: Striker / Midfielder',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.stadium_outlined,
                        size: 16,
                        color: Color(0xFF154D36),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Grand Arena • Turf A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'Tonight, 21:00',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chat with Metro Eagles captain')),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Request sent to Metro Eagles captain!'),
                                backgroundColor: Color(0xFF154D36),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text(
                            'Request to Join',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF154D36),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
