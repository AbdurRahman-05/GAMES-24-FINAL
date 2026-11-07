import 'dart:math';
import 'package:flutter/material.dart';
import 'match_score_manager.dart';

class MatchScorecardScreen extends StatefulWidget {
  final String bookingId;
  final String turfName;
  final String sport;
  final String date;
  final String timeSlot;

  const MatchScorecardScreen({
    super.key,
    required this.bookingId,
    required this.turfName,
    required this.sport,
    required this.date,
    required this.timeSlot,
  });

  @override
  State<MatchScorecardScreen> createState() => _MatchScorecardScreenState();
}

class _MatchScorecardScreenState extends State<MatchScorecardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Teams & Rosters
  String _teamAName = 'Blazing Strikers (My Team)';
  String _teamBName = 'Thunder Smashers';
  final List<PlayerItem> _teamAPlayers = [];
  final List<PlayerItem> _teamBPlayers = [];

  // Coin Toss State
  bool _isTossing = false;
  double _tossCoinAngle = 0;
  String? _tossCaller = 'Team A';
  String? _tossCall = 'Heads';
  String? _tossResult;
  String? _tossWinner;
  String? _tossDecision; // 'Bat', 'Bowl', 'Kick-Off', 'Serve', etc.
  bool _tossCompleted = false;

  // Cricket Scorecard State
  int _cricketRunsA = 0;
  int _cricketWicketsA = 0;
  int _cricketBallsA = 0;
  final List<String> _cricketTimelineA = [];

  int _cricketRunsB = 0;
  int _cricketWicketsB = 0;
  int _cricketBallsB = 0;
  final List<String> _cricketTimelineB = [];

  int _currentCricketInning = 1; // 1 = Team A batting, 2 = Team B batting

  // Football Scorecard State
  int _footballGoalsA = 0;
  int _footballGoalsB = 0;
  final List<String> _footballEvents = [];

  // Badminton / Pickleball / Tennis Scorecard State
  int _pointsA = 0;
  int _pointsB = 0;
  int _setsWonA = 0;
  int _setsWonB = 0;
  int _currentSet = 1;
  final List<String> _setHistory = [];

  // Match Status
  bool _isMatchCompleted = false;
  String? _finalWinner;
  String? _finalMargin;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeDefaultTeams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeDefaultTeams() {
    final contacts = MatchScoreManager().getDeviceContacts();
    _teamAPlayers.addAll(contacts.take(3));
    _teamBPlayers.addAll(contacts.skip(3).take(3));
  }

  bool get _isCricket =>
      widget.sport.toLowerCase().contains('cricket');
  bool get _isFootball =>
      widget.sport.toLowerCase().contains('football') ||
      widget.sport.toLowerCase().contains('soccer');

  // ---------------------------------------------------------------------------
  // TOSS ANIMATION & LOGIC
  // ---------------------------------------------------------------------------
  void _executeCoinToss() {
    if (_isTossing) return;
    setState(() {
      _isTossing = true;
      _tossResult = null;
      _tossWinner = null;
      _tossDecision = null;
    });

    final random = Random();
    final landsOnHeads = random.nextBool();
    final outcome = landsOnHeads ? 'Heads' : 'Tails';

    // Multi-turn flip animation
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => _tossCoinAngle += 1440.0 + (landsOnHeads ? 0 : 180.0));
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final winner = (_tossCall == outcome)
          ? (_tossCaller == 'Team A' ? _teamAName : _teamBName)
          : (_tossCaller == 'Team A' ? _teamBName : _teamAName);

      setState(() {
        _isTossing = false;
        _tossResult = outcome;
        _tossWinner = winner;
        _tossCompleted = true;
      });
    });
  }

  // ---------------------------------------------------------------------------
  // CRICKET ACTIONS
  // ---------------------------------------------------------------------------
  void _addCricketRuns(int runs, {bool isBoundary = false, bool isSix = false}) {
    if (_isMatchCompleted) return;
    setState(() {
      if (_currentCricketInning == 1) {
        _cricketRunsA += runs;
        _cricketBallsA += 1;
        _cricketTimelineA.add(isSix ? '6' : (isBoundary ? '4' : '$runs'));
      } else {
        _cricketRunsB += runs;
        _cricketBallsB += 1;
        _cricketTimelineB.add(isSix ? '6' : (isBoundary ? '4' : '$runs'));
      }
    });
  }

  void _addCricketWicket() {
    if (_isMatchCompleted) return;
    setState(() {
      if (_currentCricketInning == 1) {
        if (_cricketWicketsA < 10) _cricketWicketsA += 1;
        _cricketBallsA += 1;
        _cricketTimelineA.add('W');
      } else {
        if (_cricketWicketsB < 10) _cricketWicketsB += 1;
        _cricketBallsB += 1;
        _cricketTimelineB.add('W');
      }
    });
  }

  void _addCricketExtra(String type) {
    if (_isMatchCompleted) return;
    setState(() {
      if (_currentCricketInning == 1) {
        _cricketRunsA += 1;
        _cricketTimelineA.add(type);
      } else {
        _cricketRunsB += 1;
        _cricketTimelineB.add(type);
      }
    });
  }

  String _formatOvers(int balls) {
    final overs = balls ~/ 6;
    final rem = balls % 6;
    return '$overs.$rem';
  }

  // ---------------------------------------------------------------------------
  // FOOTBALL ACTIONS
  // ---------------------------------------------------------------------------
  void _addFootballGoal(bool teamA) {
    if (_isMatchCompleted) return;
    setState(() {
      if (teamA) {
        _footballGoalsA += 1;
        _footballEvents.add('⚽ Goal for $_teamAName! ($_footballGoalsA-$_footballGoalsB)');
      } else {
        _footballGoalsB += 1;
        _footballEvents.add('⚽ Goal for $_teamBName! ($_footballGoalsA-$_footballGoalsB)');
      }
    });
  }

  // ---------------------------------------------------------------------------
  // RACKET SPORT ACTIONS (Badminton / Pickleball / Tennis)
  // ---------------------------------------------------------------------------
  void _addPoint(bool teamA) {
    if (_isMatchCompleted) return;
    setState(() {
      if (teamA) {
        _pointsA += 1;
      } else {
        _pointsB += 1;
      }

      // Standard win condition (21 points or 11 points for pickleball)
      final target = widget.sport.toLowerCase().contains('pickle') ? 11 : 21;
      if (_pointsA >= target && (_pointsA - _pointsB) >= 2) {
        _setsWonA += 1;
        _setHistory.add('Set $_currentSet: $_teamAName ($_pointsA - $_pointsB)');
        _currentSet += 1;
        _pointsA = 0;
        _pointsB = 0;
      } else if (_pointsB >= target && (_pointsB - _pointsA) >= 2) {
        _setsWonB += 1;
        _setHistory.add('Set $_currentSet: $_teamBName ($_pointsB - $_pointsA)');
        _currentSet += 1;
        _pointsA = 0;
        _pointsB = 0;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // FINALIZE MATCH & AWARD WIN
  // ---------------------------------------------------------------------------
  void _finalizeMatch() {
    String winner;
    String margin;
    String scoreA;
    String scoreB;

    if (_isCricket) {
      scoreA = '$_cricketRunsA/$_cricketWicketsA (${_formatOvers(_cricketBallsA)})';
      scoreB = '$_cricketRunsB/$_cricketWicketsB (${_formatOvers(_cricketBallsB)})';
      if (_cricketRunsA > _cricketRunsB) {
        winner = _teamAName;
        margin = 'by ${_cricketRunsA - _cricketRunsB} runs';
      } else if (_cricketRunsB > _cricketRunsA) {
        winner = _teamBName;
        margin = 'by ${10 - _cricketWicketsB} wickets';
      } else {
        winner = 'Match Tied';
        margin = 'Scores Level!';
      }
    } else if (_isFootball) {
      scoreA = '$_footballGoalsA Goals';
      scoreB = '$_footballGoalsB Goals';
      if (_footballGoalsA > _footballGoalsB) {
        winner = _teamAName;
        margin = '$_footballGoalsA - $_footballGoalsB';
      } else if (_footballGoalsB > _footballGoalsA) {
        winner = _teamBName;
        margin = '$_footballGoalsB - $_footballGoalsA';
      } else {
        winner = 'Draw';
        margin = '$_footballGoalsA - $_footballGoalsB';
      }
    } else {
      scoreA = '$_setsWonA Sets ($_pointsA pts)';
      scoreB = '$_setsWonB Sets ($_pointsB pts)';
      if (_setsWonA > _setsWonB) {
        winner = _teamAName;
        margin = '$_setsWonA - $_setsWonB sets';
      } else if (_setsWonB > _setsWonA) {
        winner = _teamBName;
        margin = '$_setsWonB - $_setsWonA sets';
      } else {
        winner = _teamAName;
        margin = '$_setsWonA - $_setsWonB sets';
      }
    }

    final userWon = winner == _teamAName;

    final matchResult = MatchResultItem(
      id: 'MAT-${DateTime.now().millisecondsSinceEpoch}',
      bookingId: widget.bookingId,
      turfName: widget.turfName,
      sport: widget.sport,
      date: widget.date,
      timeSlot: widget.timeSlot,
      teamAName: _teamAName,
      teamBName: _teamBName,
      teamAPlayers: _teamAPlayers,
      teamBPlayers: _teamBPlayers,
      tossWinner: _tossWinner ?? _teamAName,
      tossDecision: _tossDecision ?? 'Bat First',
      teamAScore: scoreA,
      teamBScore: scoreB,
      winner: winner,
      winningMargin: margin,
      userWon: userWon,
    );

    MatchScoreManager().recordMatchResult(matchResult);

    setState(() {
      _isMatchCompleted = true;
      _finalWinner = winner;
      _finalMargin = margin;
    });

    _tabController.animateTo(3);

    // Show celebration dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Color(0xFFD97706)),
            const SizedBox(height: 12),
            Text(
              userWon ? '🎉 VICTORY! 🎉' : 'Match Completed',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$winner Won $margin!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Matches:', style: TextStyle(color: Colors.grey)),
                      Text('${MatchScoreManager().getTotalMatches(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Profile Wins Updated:', style: TextStyle(color: Colors.grey)),
                      Text(
                        '+1 Win Added! 🏆',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: userWon ? const Color(0xFF166534) : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF166534),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('View Final Scorecard'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONTACT PICKER DIALOG
  // ---------------------------------------------------------------------------
  void _showContactPicker(bool forTeamA) {
    final contacts = MatchScoreManager().getDeviceContacts();
    final customNameCtrl = TextEditingController();
    final customPhoneCtrl = TextEditingController();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = contacts.where((c) {
            return c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                c.phone.contains(searchQuery);
          }).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Players to ${forTeamA ? _teamAName : _teamBName}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: 'Search contacts by name or phone...',
                      filled: true,
                      fillColor: const Color(0xFFF3F5F1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) => setModalState(() => searchQuery = val),
                  ),
                  const SizedBox(height: 14),
                  // Manual Add Expandable Tile
                  ExpansionTile(
                    title: const Text('Add Custom Player by Phone', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    leading: const Icon(Icons.person_add_alt_1, color: Color(0xFF166534)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: customNameCtrl,
                              decoration: const InputDecoration(labelText: 'Player Name', isDense: true),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: customPhoneCtrl,
                              decoration: const InputDecoration(labelText: 'Mobile Number', isDense: true),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534), foregroundColor: Colors.white),
                                onPressed: () {
                                  if (customNameCtrl.text.trim().isNotEmpty) {
                                    final newP = PlayerItem(
                                      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                                      name: customNameCtrl.text.trim(),
                                      phone: customPhoneCtrl.text.trim().isEmpty ? '+91 90000 00000' : customPhoneCtrl.text.trim(),
                                      role: 'Player',
                                    );
                                    setState(() {
                                      if (forTeamA) {
                                        _teamAPlayers.add(newP);
                                      } else {
                                        _teamBPlayers.add(newP);
                                      }
                                    });
                                    Navigator.pop(ctx);
                                  }
                                },
                                child: const Text('Add Player to Team'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text('Device & Recent Contacts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final contact = filtered[idx];
                        final isAlreadyInTeam = forTeamA
                            ? _teamAPlayers.any((p) => p.name == contact.name)
                            : _teamBPlayers.any((p) => p.name == contact.name);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE5F5EB),
                            child: Text(contact.avatarInitials, style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('${contact.phone} • ${contact.role}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          trailing: isAlreadyInTeam
                              ? const Icon(Icons.check_circle, color: Color(0xFF166534))
                              : IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF166534)),
                                  onPressed: () {
                                    setState(() {
                                      if (forTeamA) {
                                        _teamAPlayers.add(contact);
                                      } else {
                                        _teamBPlayers.add(contact);
                                      }
                                    });
                                    Navigator.pop(ctx);
                                  },
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.sport} Match Center',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Text(
              '${widget.turfName} • ${widget.timeSlot}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF166534),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF166534),
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.group_rounded, size: 18), text: '1. Teams'),
            Tab(icon: Icon(Icons.toll_rounded, size: 18), text: '2. Coin Toss'),
            Tab(icon: Icon(Icons.scoreboard_rounded, size: 18), text: '3. Scorecard'),
            Tab(icon: Icon(Icons.emoji_events_rounded, size: 18), text: '4. Result'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamsTab(),
          _buildCoinTossTab(),
          _buildScorecardTab(),
          _buildResultTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: TEAMS & CONTACTS ROSTER
  // ===========================================================================
  Widget _buildTeamsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F5EB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC6E7D2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.contact_phone_rounded, color: Color(0xFF166534)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Separate both teams, pick contacts from phonebook, and assemble your match squad!',
                    style: TextStyle(fontSize: 13, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Team A
          _buildTeamCard(
            teamName: _teamAName,
            players: _teamAPlayers,
            isTeamA: true,
            onNameChange: (val) => setState(() => _teamAName = val),
            onAddPlayer: () => _showContactPicker(true),
          ),
          const SizedBox(height: 16),
          // Team B
          _buildTeamCard(
            teamName: _teamBName,
            players: _teamBPlayers,
            isTeamA: false,
            onNameChange: (val) => setState(() => _teamBName = val),
            onAddPlayer: () => _showContactPicker(false),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.toll_rounded),
              label: const Text('Proceed to Coin Toss', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: () => _tabController.animateTo(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard({
    required String teamName,
    required List<PlayerItem> players,
    required bool isTeamA,
    required Function(String) onNameChange,
    required VoidCallback onAddPlayer,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTeamA ? const Color(0xFF166534) : const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  teamName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _showEditTeamNameDialog(teamName, onNameChange),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${players.length} Players Selected', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              TextButton.icon(
                icon: const Icon(Icons.contacts, size: 16, color: Color(0xFF166534)),
                label: const Text('Add from Contacts', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: onAddPlayer,
              ),
            ],
          ),
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Text('No players added yet. Tap "Add from Contacts".', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: players.map((p) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: isTeamA ? const Color(0xFFE5F5EB) : const Color(0xFFDBEAFE),
                    child: Text(p.avatarInitials, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isTeamA ? const Color(0xFF166534) : const Color(0xFF2563EB))),
                  ),
                  label: Text('${p.name} (${p.role.split(' ').first})', style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => players.remove(p));
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showEditTeamNameDialog(String current, Function(String) onSave) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Team'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Team Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                onSave(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: COIN TOSS (Head / Tail + Sport Specific Decision)
  // ===========================================================================
  Widget _buildCoinTossTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Official Match Toss', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            '${widget.sport} • Flip the coin to decide',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          // Interactive Coin
          GestureDetector(
            onTap: _executeCoinToss,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutBack,
              transform: Matrix4.rotationY(_tossCoinAngle * pi / 180),
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFDE68A), Color(0xFFD97706), Color(0xFF92400E)],
                  center: Alignment(-0.2, -0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFFFEF3C7), width: 4),
              ),
              child: Center(
                child: Text(
                  _isTossing
                      ? 'FLIPPING...'
                      : (_tossResult ?? 'FLIP\nCOIN'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Caller & Call Selector
          if (!_tossCompleted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Calling Team:', style: TextStyle(fontWeight: FontWeight.w600)),
                      DropdownButton<String>(
                        value: _tossCaller,
                        underline: const SizedBox.shrink(),
                        items: [_teamAName, _teamBName].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setState(() => _tossCaller = val),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Call:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Row(
                        children: ['Heads', 'Tails'].map((call) {
                          final isSel = _tossCall == call;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ChoiceChip(
                              label: Text(call),
                              selected: isSel,
                              selectedColor: const Color(0xFF166534),
                              labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                              onSelected: (_) => setState(() => _tossCall = call),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.touch_app),
                label: const Text('Flip Coin Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: _executeCoinToss,
              ),
            ),
          ] else ...[
            // Toss Result Banner & Decision Options
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F5EB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFC6E7D2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Color(0xFF166534), size: 36),
                  const SizedBox(height: 8),
                  Text(
                    '🎉 Toss Winner: $_tossWinner!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                  ),
                  Text(
                    'Coin landed on $_tossResult (Called $_tossCall by $_tossCaller)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Decision:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: _getDecisionOptions().map((opt) {
                      final isSel = _tossDecision == opt;
                      return ChoiceChip(
                        label: Text(opt),
                        selected: isSel,
                        selectedColor: const Color(0xFF166534),
                        labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                        onSelected: (_) => setState(() => _tossDecision = opt),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _tossCompleted = false),
                    child: const Text('Re-toss'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF166534),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _tossDecision == null
                        ? null
                        : () => _tabController.animateTo(2),
                    child: const Text('Start Scoring'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getDecisionOptions() {
    if (_isCricket) {
      return ['Bat First 🏏', 'Bowl First ⚾'];
    } else if (_isFootball) {
      return ['Kick-Off ⚽', 'Defend Side 🥅'];
    } else {
      return ['Serve First 🏸', 'Pick Court Side 🔄'];
    }
  }

  // ===========================================================================
  // TAB 3: LIVE SCORECARD
  // ===========================================================================
  Widget _buildScorecardTab() {
    if (_isCricket) {
      return _buildCricketScorecard();
    } else if (_isFootball) {
      return _buildFootballScorecard();
    } else {
      return _buildRacketScorecard();
    }
  }

  Widget _buildCricketScorecard() {
    final activeRuns = _currentCricketInning == 1 ? _cricketRunsA : _cricketRunsB;
    final activeWickets = _currentCricketInning == 1 ? _cricketWicketsA : _cricketWicketsB;
    final activeBalls = _currentCricketInning == 1 ? _cricketBallsA : _cricketBallsB;
    final activeTimeline = _currentCricketInning == 1 ? _cricketTimelineA : _cricketTimelineB;
    final battingTeam = _currentCricketInning == 1 ? _teamAName : _teamBName;
    final bowlingTeam = _currentCricketInning == 1 ? _teamBName : _teamAName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Inning Tab Switcher
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text('Inning 1: $_teamAName'),
                  selected: _currentCricketInning == 1,
                  selectedColor: const Color(0xFF166534),
                  labelStyle: TextStyle(color: _currentCricketInning == 1 ? Colors.white : Colors.black87),
                  onSelected: (_) => setState(() => _currentCricketInning = 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Text('Inning 2: $_teamBName'),
                  selected: _currentCricketInning == 2,
                  selectedColor: const Color(0xFF166534),
                  labelStyle: TextStyle(color: _currentCricketInning == 2 ? Colors.white : Colors.black87),
                  onSelected: (_) => setState(() => _currentCricketInning = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Big Score Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F6D38), Color(0xFF166534)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF166534).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'BATTING: $battingTeam',
                  style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$activeRuns',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    Text(
                      ' / $activeWickets',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                  ],
                ),
                Text(
                  'Overs: ${_formatOvers(activeBalls)}  •  Bowling: $bowlingTeam',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                if (_tossDecision != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Toss: $_tossWinner elected to $_tossDecision',
                    style: const TextStyle(color: Color(0xFFFEF3C7), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Ball-by-ball timeline
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('Recent Balls:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: activeTimeline.reversed.take(12).toList().reversed.map((b) {
                        Color col = const Color(0xFFF3F5F1);
                        Color textCol = Colors.black87;
                        if (b == '4') {
                          col = const Color(0xFFDBEAFE);
                          textCol = const Color(0xFF1E40AF);
                        } else if (b == '6') {
                          col = const Color(0xFFFEE2E2);
                          textCol = const Color(0xFF991B1B);
                        } else if (b == 'W') {
                          col = Colors.red;
                          textCol = Colors.white;
                        }
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                          child: Center(
                            child: Text(b, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCol)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Quick Scoring Keypad
          const Text('Tap to Add Runs / Events:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildCricketKey('0 (Dot)', () => _addCricketRuns(0)),
              const SizedBox(width: 8),
              _buildCricketKey('+1', () => _addCricketRuns(1)),
              const SizedBox(width: 8),
              _buildCricketKey('+2', () => _addCricketRuns(2)),
              const SizedBox(width: 8),
              _buildCricketKey('+3', () => _addCricketRuns(3)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCricketKey('FOUR 💥', () => _addCricketRuns(4, isBoundary: true), color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              _buildCricketKey('SIX 🚀', () => _addCricketRuns(6, isSix: true), color: const Color(0xFFDC2626)),
              const SizedBox(width: 8),
              _buildCricketKey('OUT 🔴', _addCricketWicket, color: Colors.black87),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCricketKey('Wide (+1)', () => _addCricketExtra('Wd')),
              const SizedBox(width: 8),
              _buildCricketKey('No Ball (+1)', () => _addCricketExtra('Nb')),
            ],
          ),
          const SizedBox(height: 24),
          // End Match
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Complete Match & Save Result', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: _finalizeMatch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCricketKey(String label, VoidCallback onTap, {Color? color}) {
    return Expanded(
      child: SizedBox(
        height: 46,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? const Color(0xFFF3F5F1),
            foregroundColor: color != null ? Colors.white : Colors.black87,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildFootballScorecard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F6D38), Color(0xFF166534)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(_teamAName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('$_footballGoalsA', style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
                const Text('VS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70)),
                Expanded(
                  child: Column(
                    children: [
                      Text(_teamBName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('$_footballGoalsB', style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534), foregroundColor: Colors.white),
                  icon: const Icon(Icons.sports_soccer),
                  label: const Text('Goal Team A (+1)'),
                  onPressed: () => _addFootballGoal(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                  icon: const Icon(Icons.sports_soccer),
                  label: const Text('Goal Team B (+1)'),
                  onPressed: () => _addFootballGoal(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Match Events Log:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_footballEvents.isEmpty)
                  const Text('No goals scored yet.', style: TextStyle(color: Colors.grey, fontSize: 13))
                else
                  ..._footballEvents.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(e))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Complete Football Match', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: _finalizeMatch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRacketScorecard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F6D38), Color(0xFF166534)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text('SET $_currentSet IN PROGRESS', style: const TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(_teamAName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('$_pointsA', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('Sets Won: $_setsWonA', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const Text('VS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70)),
                    Column(
                      children: [
                        Text(_teamBName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('$_pointsB', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('Sets Won: $_setsWonB', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534), foregroundColor: Colors.white),
                  icon: const Icon(Icons.add),
                  label: const Text('Point Team A (+1)'),
                  onPressed: () => _addPoint(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                  icon: const Icon(Icons.add),
                  label: const Text('Point Team B (+1)'),
                  onPressed: () => _addPoint(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_setHistory.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Set History:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._setHistory.map((s) => Text(s, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('End Match & Record Win', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: _finalizeMatch,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: RESULT & MATCH SUMMARY
  // ===========================================================================
  Widget _buildResultTab() {
    if (!_isMatchCompleted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.scoreboard_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Match in Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Go to Tab 3 (Scorecard) to record runs/goals and complete the match.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534), foregroundColor: Colors.white),
                onPressed: () => _tabController.animateTo(2),
                child: const Text('Go to Scorecard'),
              ),
            ],
          ),
        ),
      );
    }

    final userWon = _finalWinner == _teamAName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events, size: 72, color: Color(0xFFD97706)),
                const SizedBox(height: 12),
                Text(
                  '$_finalWinner',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Won $_finalMargin',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(_teamAName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          _isCricket ? '$_cricketRunsA/$_cricketWicketsA' : (_isFootball ? '$_footballGoalsA' : '$_setsWonA sets'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Text('VS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    Column(
                      children: [
                        Text(_teamBName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          _isCricket ? '$_cricketRunsB/$_cricketWicketsB' : (_isFootball ? '$_footballGoalsB' : '$_setsWonB sets'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F5EB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF166534)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userWon
                              ? '🏆 Win recorded! +1 Win and Form Index updated on Player Profile.'
                              : 'Match recorded to player match history.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to My Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
