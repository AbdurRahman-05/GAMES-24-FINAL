import 'dart:math';
import 'package:flutter/material.dart';
import 'match_score_manager.dart';
import 'booking_manager.dart';
import 'challenge_manager.dart';
import 'contacts_picker_sheet.dart';

class MatchScorecardScreen extends StatefulWidget {
  final String bookingId;
  final String turfName;
  final String sport;
  final String date;
  final String timeSlot;
  final int initialTab;

  const MatchScorecardScreen({
    super.key,
    required this.bookingId,
    required this.turfName,
    required this.sport,
    required this.date,
    required this.timeSlot,
    this.initialTab = 0,
  });

  @override
  State<MatchScorecardScreen> createState() => _MatchScorecardScreenState();
}

class _MatchScorecardScreenState extends State<MatchScorecardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sport & Format Configuration
  late String _currentSport;
  final List<String> _venueSports = [
    'Cricket',
    'Football',
    'Badminton',
    'Pickleball',
    'Tennis',
  ];

  // Match & Timing Configuration
  bool _forceEarlyStart = false;
  String _selectedTeamSize = '7v7';
  int _selectedOvers = 10;
  int _footballDurationMinutes = 60;
  String _racketFormat = 'Best of 3 Sets';

  // Open Challenge Link
  bool _isOpenChallenge = false;
  Challenge? _linkedChallenge;

  // Teams & Rosters
  String _teamAName = 'Blazing Strikers (My Team)';
  String _teamBName = 'Thunder Smashers';
  final List<PlayerItem> _teamAPlayers = [];
  final List<PlayerItem> _teamBPlayers = [];

  // Coin Toss State
  bool _isTossing = false;
  double _tossCoinAngle = 0;
  String? _tossCaller;
  String? _tossCall = 'Heads';
  String? _tossResult;
  String? _tossWinner;
  String? _tossDecision; // 'Bat First 🏏', 'Bowl First ⚾', etc.
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

  int _currentCricketInning = 1; // 1 = 1st batting team, 2 = 2nd batting team
  int? _cricketTarget;

  // Active Player Tracking per Inning (Cricket)
  PlayerItem? _striker1;
  PlayerItem? _nonStriker1;
  PlayerItem? _currentBowler1;

  PlayerItem? _striker2;
  PlayerItem? _nonStriker2;
  PlayerItem? _currentBowler2;

  PlayerItem? get _striker =>
      _currentCricketInning == 1 ? _striker1 : _striker2;
  set _striker(PlayerItem? p) {
    if (_currentCricketInning == 1) {
      _striker1 = p;
    } else {
      _striker2 = p;
    }
  }

  PlayerItem? get _nonStriker =>
      _currentCricketInning == 1 ? _nonStriker1 : _nonStriker2;
  set _nonStriker(PlayerItem? p) {
    if (_currentCricketInning == 1) {
      _nonStriker1 = p;
    } else {
      _nonStriker2 = p;
    }
  }

  PlayerItem? get _currentBowler =>
      _currentCricketInning == 1 ? _currentBowler1 : _currentBowler2;
  set _currentBowler(PlayerItem? p) {
    if (_currentCricketInning == 1) {
      _currentBowler1 = p;
    } else {
      _currentBowler2 = p;
    }
  }

  final Map<String, PlayerMatchStat> _playerStats = {};

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

  // Match History & Multi-match in Slot
  List<MatchResultItem> _slotMatches = [];
  int _selectedMatchHistoryIndex = 0;
  int _matchIndex = 1;
  bool _isMatchCompleted = false;
  String? _finalWinner;
  String? _finalMargin;
  MatchResultItem? _loadedResult;

  @override
  void initState() {
    super.initState();
    _currentSport = widget.sport.isNotEmpty ? widget.sport : 'Cricket';
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    _initializeDefaultTeams();
    _loadHistoricalMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadHistoricalMatches() {
    _slotMatches = MatchScoreManager().getAllResultsForBooking(widget.bookingId);
    if (_slotMatches.isNotEmpty) {
      _selectedMatchHistoryIndex = _slotMatches.length - 1;
      final latest = _slotMatches.last;
      _loadedResult = latest;
      _matchIndex = _slotMatches.length;

      // If user came specifically to see results or the match is completed
      if (widget.initialTab == 3) {
        _isMatchCompleted = true;
        _finalWinner = latest.winner;
        _finalMargin = latest.winningMargin;
      }
    }
  }

  void _initializeDefaultTeams() {
    _tossCaller = _teamAName;

    // Detect if this match is linked to an Open Challenge
    final challenges = ChallengeManager().challengesNotifier.value;
    for (final c in challenges) {
      final turfMatch =
          c.turfName.trim().toLowerCase() == widget.turfName.trim().toLowerCase();
      final timeMatch =
          c.time.contains(widget.timeSlot) || widget.timeSlot.contains(c.time);
      if (turfMatch && (timeMatch || c.date == widget.date)) {
        _linkedChallenge = c;
        _isOpenChallenge = true;
        _selectedTeamSize = c.teamSize.isNotEmpty ? c.teamSize : '7v7';
        if (c.challengerName.isNotEmpty) {
          _teamAName = c.challengerName;
        }
        if (c.opponentName != null && c.opponentName!.isNotEmpty) {
          _teamBName = c.opponentName!;
        } else {
          _teamBName = 'Opponent Team (Waiting)';
        }
        _tossCaller = _teamAName;
        break;
      }
    }

    final contacts = MatchScoreManager().getDeviceContacts();
    _teamAPlayers.addAll(contacts.take(3));
    if (!_isOpenChallenge ||
        (_linkedChallenge?.opponentName != null &&
            _linkedChallenge!.opponentName!.isNotEmpty)) {
      _teamBPlayers.addAll(contacts.skip(3).take(3));
    }
  }

  bool get _isMatchStarted =>
      BookingManager.isMatchStarted(dateStr: widget.date, timeSlot: widget.timeSlot);

  bool get _canPlayMatch => _isMatchStarted || _forceEarlyStart || _isMatchCompleted;

  int get _playersPerSide {
    final reg = RegExp(r'(\d+)');
    final match = reg.firstMatch(_selectedTeamSize);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 7;
    }
    return 7;
  }

  bool get _isCricket => _currentSport.toLowerCase().contains('cricket');
  bool get _isFootball =>
      _currentSport.toLowerCase().contains('football') ||
      _currentSport.toLowerCase().contains('soccer');

  // Innings resolution based on Coin Toss
  String get _firstBattingTeam {
    if (_tossCompleted && _tossWinner != null && _tossDecision != null) {
      if (_tossDecision!.contains('Bat')) {
        return _tossWinner!;
      } else {
        return _tossWinner == _teamAName ? _teamBName : _teamAName;
      }
    }
    return _teamAName;
  }

  String get _firstBowlingTeam =>
      _firstBattingTeam == _teamAName ? _teamBName : _teamAName;

  String get _secondBattingTeam => _firstBowlingTeam;
  String get _secondBowlingTeam => _firstBattingTeam;

  String get _currentBattingTeam =>
      _currentCricketInning == 1 ? _firstBattingTeam : _secondBattingTeam;

  String get _currentBowlingTeam =>
      _currentCricketInning == 1 ? _firstBowlingTeam : _secondBowlingTeam;

  List<PlayerItem> get _currentBattingSquad =>
      _currentBattingTeam == _teamAName ? _teamAPlayers : _teamBPlayers;

  List<PlayerItem> get _currentBowlingSquad =>
      _currentBowlingTeam == _teamAName ? _teamAPlayers : _teamBPlayers;

  PlayerMatchStat _getStat(PlayerItem p) {
    return _playerStats.putIfAbsent(
      p.id.isNotEmpty ? p.id : p.name,
      () => PlayerMatchStat(name: p.name, role: p.role),
    );
  }

  void _ensureActivePlayers() {
    final battingSquad = _currentBattingSquad;
    final bowlingSquad = _currentBowlingSquad;

    if (battingSquad.isNotEmpty) {
      if (_striker == null || !battingSquad.contains(_striker)) {
        final available =
            battingSquad.where((p) => !_getStat(p).isOut).toList();
        _striker = available.isNotEmpty ? available.first : battingSquad.first;
      }
      if (_nonStriker == null ||
          !battingSquad.contains(_nonStriker) ||
          _nonStriker == _striker) {
        final available = battingSquad
            .where((p) => p != _striker && !_getStat(p).isOut)
            .toList();
        if (available.isNotEmpty) {
          _nonStriker = available.first;
        } else if (battingSquad.length > 1) {
          _nonStriker = battingSquad.firstWhere(
            (p) => p != _striker,
            orElse: () => battingSquad.first,
          );
        }
      }
    }

    if (bowlingSquad.isNotEmpty) {
      if (_currentBowler == null || !bowlingSquad.contains(_currentBowler)) {
        _currentBowler = bowlingSquad.first;
      }
    }
  }

  void _swapStrike() {
    final temp = _striker;
    _striker = _nonStriker;
    _nonStriker = temp;
  }

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

    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => _tossCoinAngle += 1440.0 + (landsOnHeads ? 0 : 180.0));
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final callerIsA = _tossCaller == _teamAName;
      final winner = (_tossCall == outcome)
          ? (callerIsA ? _teamAName : _teamBName)
          : (callerIsA ? _teamBName : _teamAName);

      setState(() {
        _isTossing = false;
        _tossResult = outcome;
        _tossWinner = winner;
        _tossCompleted = true;
        _tossDecision = _isCricket
            ? 'Bat First 🏏'
            : (_isFootball ? 'Kick-Off ⚽' : 'Serve First 🏸');
      });
      _ensureActivePlayers();
    });
  }

  // ---------------------------------------------------------------------------
  // CRICKET ACTIONS & INNINGS TRANSITIONS
  // ---------------------------------------------------------------------------
  void _addCricketRuns(int runs, {bool isBoundary = false, bool isSix = false}) {
    if (_isMatchCompleted) return;
    _ensureActivePlayers();

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

      if (_striker != null) {
        final st = _getStat(_striker!);
        st.runs += runs;
        st.balls += 1;
        if (isBoundary) st.fours += 1;
        if (isSix) st.sixes += 1;
      }

      if (_currentBowler != null) {
        final bw = _getStat(_currentBowler!);
        bw.ballsBowled += 1;
        bw.runsConceded += runs;
      }

      if (runs == 1 || runs == 3) {
        _swapStrike();
      }

      final activeBalls =
          _currentCricketInning == 1 ? _cricketBallsA : _cricketBallsB;
      if (activeBalls % 6 == 0) {
        _swapStrike();
        _promptNewBowler();
      }
    });

    _checkCricketInningsProgress();
  }

  void _addCricketWicket() {
    if (_isMatchCompleted) return;
    _ensureActivePlayers();

    final dismissed = _striker;
    final bowlerRef = _currentBowler;

    setState(() {
      if (_currentCricketInning == 1) {
        _cricketWicketsA += 1;
        _cricketBallsA += 1;
        _cricketTimelineA.add('W');
      } else {
        _cricketWicketsB += 1;
        _cricketBallsB += 1;
        _cricketTimelineB.add('W');
      }

      if (dismissed != null) {
        final st = _getStat(dismissed);
        st.balls += 1;
        st.isOut = true;
      }

      if (bowlerRef != null) {
        final bw = _getStat(bowlerRef);
        bw.ballsBowled += 1;
        bw.wickets += 1;
      }

      final activeBalls =
          _currentCricketInning == 1 ? _cricketBallsA : _cricketBallsB;
      if (activeBalls % 6 == 0) {
        _swapStrike();
        _promptNewBowler();
      }
    });

    _promptFielderAndNextBatter(dismissed);
    _checkCricketInningsProgress();
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
      if (_currentBowler != null) {
        _getStat(_currentBowler!).runsConceded += 1;
      }
    });
    _checkCricketInningsProgress();
  }

  void _promptNewBowler() {
    final squad = _currentBowlingSquad;
    if (squad.length <= 1) return;

    final candidates = squad.where((p) => p != _currentBowler).toList();
    if (candidates.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Over completed! Next bowler: ${candidates.first.name} ($_currentBowlingTeam)'),
        backgroundColor: const Color(0xFF166534),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Change',
          textColor: Colors.amberAccent,
          onPressed: () {
            _showSelectBowlerDialog(squad);
          },
        ),
      ),
    );
    setState(() {
      _currentBowler = candidates.first;
    });
  }

  void _showSelectBowlerDialog(List<PlayerItem> squad, {bool isOpeningBowler = false}) {
    if (squad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No players in $_currentBowlingTeam squad. Add players in Teams tab.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.sports_cricket, color: Color(0xFF166534), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isOpeningBowler
                    ? 'Select Opening Bowler (Inning $_currentCricketInning)'
                    : 'Select Bowler (Inning $_currentCricketInning)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bowling Team: $_currentBowlingTeam',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: squad.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final p = squad[idx];
                    final st = _getStat(p);
                    final isCurrent = p == _currentBowler;

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isCurrent ? const Color(0xFF166534) : const Color(0xFFEFF6FF),
                        child: Text(
                          p.avatarInitials,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5F5EB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        st.ballsBowled > 0
                            ? '${st.wickets}/${st.runsConceded} (${st.oversBowled} ov) • Econ: ${st.economy}'
                            : '${p.role} • Yet to bowl',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      onTap: () {
                        setState(() => _currentBowler = p);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Now Bowling: ${p.name} for $_currentBowlingTeam (Inning $_currentCricketInning)! 🎯'),
                            backgroundColor: const Color(0xFF166534),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _promptFielderAndNextBatter(PlayerItem? dismissed) {
    final fielders = _currentBowlingSquad;
    final remainingBatters =
        _currentBattingSquad.where((p) => p != dismissed && !_getStat(p).isOut).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_cricket, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  '🔴 Wicket! ${dismissed?.name ?? "Batter"} is Out',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (fielders.isNotEmpty) ...[
              const Text('Fielding credit (Catch / Run-Out):', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: fielders.map((f) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ActionChip(
                        avatar: const Icon(Icons.back_hand, size: 14),
                        label: Text(f.name),
                        onPressed: () {
                          _getStat(f).catches += 1;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Catch / fielding credited to ${f.name} (+10 pts)!'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text('Next Batter to Crease:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (remainingBatters.isNotEmpty)
              Wrap(
                spacing: 8,
                children: remainingBatters.map((b) {
                  return ChoiceChip(
                    label: Text(b.name),
                    selected: _striker == b,
                    selectedColor: const Color(0xFF166534),
                    labelStyle: TextStyle(color: _striker == b ? Colors.white : Colors.black87),
                    onSelected: (_) {
                      setState(() => _striker = b);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('All available batters have batted.', style: TextStyle(color: Colors.grey)),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkCricketInningsProgress() {
    final maxBalls = _selectedOvers * 6;
    final maxWickets = _playersPerSide > 1 ? _playersPerSide - 1 : 10;

    if (_currentCricketInning == 1) {
      if (_cricketBallsA >= maxBalls || _cricketWicketsA >= maxWickets) {
        _cricketTarget = _cricketRunsA + 1;
        _showInningsBreakDialog();
      }
    } else {
      final target = _cricketTarget ?? (_cricketRunsA + 1);
      if (_cricketRunsB >= target) {
        _finalizeMatch();
      } else if (_cricketBallsB >= maxBalls || _cricketWicketsB >= maxWickets) {
        _finalizeMatch();
      }
    }
  }

  void _showInningsBreakDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.flag_rounded, color: Color(0xFF166534)),
            SizedBox(width: 8),
            Text('1st Innings Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_firstBattingTeam scored $_cricketRunsA/$_cricketWicketsA in ${_formatOvers(_cricketBallsA)} overs.',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F5EB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.track_changes, color: Color(0xFF166534)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Target for $_secondBattingTeam: $_cricketTarget runs in $_selectedOvers overs.',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Switching to 2nd Innings. $_secondBattingTeam will now bat to chase the target.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _currentCricketInning = 2;
                _ensureActivePlayers();
              });
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _showSelectBowlerDialog(_currentBowlingSquad, isOpeningBowler: true);
                }
              });
            },
            child: const Text('Start 2nd Innings Batting 🏏'),
          ),
        ],
      ),
    );
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

      final target = _currentSport.toLowerCase().contains('pickle') ? 11 : 21;
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
      scoreA = '$_cricketRunsA/$_cricketWicketsA (${_formatOvers(_cricketBallsA)} ov)';
      scoreB = '$_cricketRunsB/$_cricketWicketsB (${_formatOvers(_cricketBallsB)} ov)';

      final maxWickets = _playersPerSide > 1 ? _playersPerSide - 1 : 10;
      final target = _cricketTarget ?? (_cricketRunsA + 1);

      if (_cricketRunsB >= target) {
        winner = _secondBattingTeam;
        margin = 'by ${maxWickets - _cricketWicketsB} wickets';
      } else if (_cricketRunsB == target - 1) {
        winner = 'Match Tied';
        margin = 'Scores Level!';
      } else {
        winner = _firstBattingTeam;
        final runDiff = _cricketRunsA - _cricketRunsB;
        margin = 'by $runDiff runs';
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

    // Calculate Match Awards
    PlayerMatchStat? motm;
    PlayerMatchStat? topScorer;
    PlayerMatchStat? bestBowler;
    PlayerMatchStat? bestFielder;

    int maxPts = -1;
    int maxRuns = -1;
    int maxWickets = -1;
    int maxCatches = -1;

    for (final s in _playerStats.values) {
      if (s.fantasyPoints > maxPts) {
        maxPts = s.fantasyPoints;
        motm = s;
      }
      if (s.runs > maxRuns && s.runs > 0) {
        maxRuns = s.runs;
        topScorer = s;
      }
      if (s.wickets > maxWickets && s.wickets > 0) {
        maxWickets = s.wickets;
        bestBowler = s;
      } else if (s.wickets == maxWickets && s.wickets > 0 && bestBowler != null) {
        if (s.runsConceded < bestBowler.runsConceded) {
          bestBowler = s;
        }
      }
      if ((s.catches + s.runOuts) > maxCatches && (s.catches + s.runOuts) > 0) {
        maxCatches = s.catches + s.runOuts;
        bestFielder = s;
      }
    }

    final motmStr = motm != null ? '${motm.name} (${motm.fantasyPoints} pts)' : null;
    final topScorerStr = topScorer != null
        ? '${topScorer.name} (${topScorer.runs} runs off ${topScorer.balls}b)'
        : null;
    final bestBowlerStr = bestBowler != null
        ? '${bestBowler.name} (${bestBowler.wickets}/${bestBowler.runsConceded} in ${bestBowler.oversBowled} ov)'
        : null;
    final bestFielderStr =
        bestFielder != null ? '${bestFielder.name} (${bestFielder.catches} catches)' : null;

    final statsA = _teamAPlayers.map((p) => _getStat(p)).toList();
    final statsB = _teamBPlayers.map((p) => _getStat(p)).toList();

    final matchResult = MatchResultItem(
      id: 'MAT-${DateTime.now().millisecondsSinceEpoch}',
      bookingId: widget.bookingId,
      turfName: widget.turfName,
      sport: _currentSport,
      date: widget.date,
      timeSlot: widget.timeSlot,
      teamAName: _teamAName,
      teamBName: _teamBName,
      teamAPlayers: _teamAPlayers,
      teamBPlayers: _teamBPlayers,
      tossWinner: _tossWinner ?? _teamAName,
      tossDecision: _tossDecision ?? 'Bat First 🏏',
      teamAScore: scoreA,
      teamBScore: scoreB,
      winner: winner,
      winningMargin: margin,
      userWon: userWon,
      manOfTheMatch: motmStr,
      highestScorer: topScorerStr,
      bestBowler: bestBowlerStr,
      bestFielder: bestFielderStr,
      overs: _selectedOvers,
      teamSize: _selectedTeamSize,
      matchIndex: _matchIndex,
      playerStatsA: statsA,
      playerStatsB: statsB,
    );

    MatchScoreManager().recordMatchResult(matchResult);

    setState(() {
      _isMatchCompleted = true;
      _finalWinner = winner;
      _finalMargin = margin;
      _loadedResult = matchResult;
      _slotMatches = MatchScoreManager().getAllResultsForBooking(widget.bookingId);
      _selectedMatchHistoryIndex = _slotMatches.length - 1;
    });

    _tabController.animateTo(3);

    // Fixed Celebration Dialog (No Overflow)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF166534),
              ),
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
                      const Expanded(
                        child: Text(
                          'Total Matches:',
                          style: TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${MatchScoreManager().getTotalMatches(1)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Profile Wins Updated:',
                          style: TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
            child: const Text('View Match Details & Result 📋'),
          ),
        ],
      ),
    );
  }

  void _startRematch() {
    setState(() {
      _isMatchCompleted = false;
      _cricketRunsA = 0;
      _cricketWicketsA = 0;
      _cricketBallsA = 0;
      _cricketTimelineA.clear();
      _cricketRunsB = 0;
      _cricketWicketsB = 0;
      _cricketBallsB = 0;
      _cricketTimelineB.clear();
      _currentCricketInning = 1;
      _cricketTarget = null;
      _footballGoalsA = 0;
      _footballGoalsB = 0;
      _footballEvents.clear();
      _pointsA = 0;
      _pointsB = 0;
      _setsWonA = 0;
      _setsWonB = 0;
      _currentSet = 1;
      _setHistory.clear();
      _tossCompleted = false;
      _tossResult = null;
      _tossWinner = null;
      _tossDecision = null;
      _playerStats.clear();
      _striker1 = null;
      _nonStriker1 = null;
      _currentBowler1 = null;
      _striker2 = null;
      _nonStriker2 = null;
      _currentBowler2 = null;
      _matchIndex = _slotMatches.length + 1;
    });
    _tabController.animateTo(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting Match #$_matchIndex in this slot! Flip coin for toss.'),
        backgroundColor: const Color(0xFF166534),
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
              '$_currentSport Match Center',
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
            Tab(icon: Icon(Icons.emoji_events_rounded, size: 18), text: '4. Result & Awards'),
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
  // PRE-MATCH LOCK SCREEN HELPER
  // ===========================================================================
  Widget _buildPreMatchLockedCard({
    required String featureName,
    required IconData featureIcon,
  }) {
    final startSlot =
        BookingManager.getFormattedSlotStart(timeSlot: widget.timeSlot);
    final minsUntil = BookingManager.getMinutesUntilMatchStart(
      dateStr: widget.date,
      timeSlot: widget.timeSlot,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  size: 40,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$featureName Locked',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  'Match starts at $startSlot ${minsUntil > 0 ? "(in $minsUntil mins)" : ""}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Matches start in time only at $startSlot. Before the match begins, assemble squads, pick team size & overs, and add players from contacts. The coin toss and scoring unlock once match time arrives.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF166534),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.group_rounded, size: 18),
                  label: const Text('Go to Squad Setup', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _tabController.animateTo(0),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD97706),
                    side: const BorderSide(color: Color(0xFFD97706)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text('Start Match Early (Both Teams Ready)', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() => _forceEarlyStart = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Match unlocked! Coin toss and live scoring active.'),
                        backgroundColor: Color(0xFF166534),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CONTACT IMPORT & AUTO-SPLIT HELPERS
  // ===========================================================================
  void _openContactsPicker(bool forTeamA) {
    final currentList = forTeamA ? _teamAPlayers : _teamBPlayers;
    final otherList = forTeamA ? _teamBPlayers : _teamAPlayers;

    ContactsPickerSheet.show(
      context,
      alreadySelected: currentList,
      sport: _currentSport,
      onImport: (selected) {
        setState(() {
          for (final p in selected) {
            if (!currentList.any((item) => item.name == p.name && item.phone == p.phone)) {
              otherList.removeWhere((item) => item.name == p.name && item.phone == p.phone);
              currentList.add(p);
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${selected.length} player(s) to ${forTeamA ? _teamAName : _teamBName}!'),
            backgroundColor: const Color(0xFF166534),
          ),
        );
      },
    );
  }

  void _autoSplitContacts() {
    final contacts = MatchScoreManager().getDeviceContacts();
    final half = (contacts.length / 2).ceil();
    setState(() {
      _teamAPlayers.clear();
      _teamBPlayers.clear();
      _teamAPlayers.addAll(contacts.take(half));
      _teamBPlayers.addAll(contacts.skip(half));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Auto-balanced squads: ${_teamAPlayers.length} in $_teamAName, ${_teamBPlayers.length} in $_teamBName!'),
        backgroundColor: const Color(0xFF166534),
      ),
    );
  }

  void _showCustomSquadSizeDialog() {
    final ctrl = TextEditingController(text: '$_playersPerSide');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Custom Squad Size'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Players per side (e.g. 4, 9, 10)',
            hintText: '4',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534), foregroundColor: Colors.white),
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val >= 1 && val <= 25) {
                setState(() => _selectedTeamSize = '${val}v$val');
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set Size'),
          ),
        ],
      ),
    );
  }

  void _showCustomOversDialog() {
    final ctrl = TextEditingController(text: '$_selectedOvers');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Custom Match Overs'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of Overs (e.g. 4, 5, 7, 14, 25)',
            hintText: '6',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534), foregroundColor: Colors.white),
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val >= 1 && val <= 100) {
                setState(() => _selectedOvers = val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set Overs'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: TEAMS & CONTACTS ROSTER
  // ===========================================================================
  Widget _buildTeamsTab() {
    final startSlot = BookingManager.getFormattedSlotStart(timeSlot: widget.timeSlot);
    final minsUntil = BookingManager.getMinutesUntilMatchStart(dateStr: widget.date, timeSlot: widget.timeSlot);
    final isOpponentJoined = _linkedChallenge?.isJoined == true ||
        (_linkedChallenge?.opponentName != null && _linkedChallenge!.opponentName!.isNotEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pre-Match Alert Banner
          if (!_canPlayMatch) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pre-Match Phase: Starts at $startSlot ${minsUntil > 0 ? "(in $minsUntil mins)" : ""}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Prepare your squads, overs & format below. Coin Toss and Live Scorecard will unlock when match starts!',
                          style: TextStyle(fontSize: 11, color: Color(0xFFB45309), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Open Challenge Status Card
          if (_isOpenChallenge) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOpponentJoined ? const Color(0xFFE5F5EB) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isOpponentJoined ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isOpponentJoined ? const Color(0xFF166534) : const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOpponentJoined ? Icons.handshake_rounded : Icons.public,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOpponentJoined ? '⚔️ Open Challenge: Opponent Joined!' : '⚔️ Open Challenge Match',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isOpponentJoined ? const Color(0xFF166534) : const Color(0xFF1E40AF),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOpponentJoined ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOpponentJoined ? 'Opponent Ready' : '⏳ Waiting for Team',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOpponentJoined ? const Color(0xFF166534) : const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOpponentJoined
                        ? 'Opponent squad "$_teamBName" is confirmed for this clash ($_selectedTeamSize).'
                        : 'This game is posted as an Open Challenge ($_selectedTeamSize). Waiting for another squad to accept.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOpponentJoined ? const Color(0xFF14532D) : const Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Match Configuration (Sport Switcher, Team Size & Overs)
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Match Format & Rules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      '$_playersPerSide players / side',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Venue Supported Sports Switcher
                const Text('Select Sport (Venue Supported):', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _venueSports.map((sp) {
                      final isSel = _currentSport.toLowerCase() == sp.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: Icon(
                            sp == 'Cricket'
                                ? Icons.sports_cricket
                                : (sp == 'Football'
                                    ? Icons.sports_soccer
                                    : Icons.sports_tennis),
                            size: 16,
                            color: isSel ? Colors.white : const Color(0xFF166534),
                          ),
                          label: Text(sp),
                          selected: isSel,
                          selectedColor: const Color(0xFF166534),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : Colors.black87,
                          ),
                          onSelected: (_) {
                            setState(() => _currentSport = sp);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Team Size Selector
                const Text('Squad Size:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ...['5v5', '6v6', '7v7', '8v8', '11v11'].map((size) {
                      final isSel = _selectedTeamSize == size;
                      return ChoiceChip(
                        label: Text(size),
                        selected: isSel,
                        selectedColor: const Color(0xFF166534),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : Colors.black87,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedTeamSize = size);
                        },
                      );
                    }),
                    ActionChip(
                      avatar: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF166534)),
                      label: Text(
                        !['5v5', '6v6', '7v7', '8v8', '11v11'].contains(_selectedTeamSize)
                            ? '$_selectedTeamSize (Custom)'
                            : '+ Custom',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                      onPressed: _showCustomSquadSizeDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Overs or Duration Selector
                if (_isCricket) ...[
                  const Text('Match Overs:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ...[4, 6, 8, 10, 12, 15, 20].map((ov) {
                        final isSel = _selectedOvers == ov;
                        return ChoiceChip(
                          label: Text('$ov Overs'),
                          selected: isSel,
                          selectedColor: const Color(0xFF166534),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : Colors.black87,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedOvers = ov);
                          },
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF166534)),
                        label: Text(
                          ![4, 6, 8, 10, 12, 15, 20].contains(_selectedOvers)
                              ? '$_selectedOvers Overs (Custom)'
                              : '+ Custom',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                        ),
                        onPressed: _showCustomOversDialog,
                      ),
                    ],
                  ),
                ] else if (_isFootball) ...[
                  const Text('Match Duration:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [30, 45, 60, 90].map((mins) {
                      final isSel = _footballDurationMinutes == mins;
                      return ChoiceChip(
                        label: Text('$mins Mins'),
                        selected: isSel,
                        selectedColor: const Color(0xFF166534),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : Colors.black87,
                        ),
                        onSelected: (_) {
                          setState(() => _footballDurationMinutes = mins);
                        },
                      );
                    }).toList(),
                  ),
                ] else ...[
                  const Text('Match Format:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['Best of 3 Sets', '1 Set (21 Pts)', '11 Pts Rapid'].map((fmt) {
                      final isSel = _racketFormat == fmt;
                      return ChoiceChip(
                        label: Text(fmt),
                        selected: isSel,
                        selectedColor: const Color(0xFF166534),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : Colors.black87,
                        ),
                        onSelected: (_) {
                          setState(() => _racketFormat = fmt);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Squads & Contacts Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Team Squads & Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                icon: const Icon(Icons.shuffle, size: 16, color: Color(0xFF166534)),
                label: const Text('Auto Split Contacts', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _autoSplitContacts,
              ),
            ],
          ),
          const SizedBox(height: 8),

          _buildTeamCard(
            teamName: _teamAName,
            players: _teamAPlayers,
            isTeamA: true,
            onNameChange: (val) => setState(() => _teamAName = val),
            onAddPlayer: () => _openContactsPicker(true),
          ),
          const SizedBox(height: 16),

          _buildTeamCard(
            teamName: _teamBName,
            players: _teamBPlayers,
            isTeamA: false,
            onNameChange: (val) => setState(() => _teamBName = val),
            onAddPlayer: () => _openContactsPicker(false),
          ),
          const SizedBox(height: 24),

          // Proceed to Toss Button
          if (!_canPlayMatch) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F6D38),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.timer_outlined),
                label: Text(
                  'Squad Ready • Match Starts at $startSlot',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lineup is set! Coin toss and live scoring will unlock at $startSlot.'),
                      backgroundColor: const Color(0xFF166534),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFD97706)),
                label: const Text(
                  'Both Teams at Turf? Start Toss Early',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                ),
                onPressed: () {
                  setState(() => _forceEarlyStart = true);
                  _tabController.animateTo(1);
                },
              ),
            ),
          ] else ...[
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
                label: const Text('Proceed to Coin Toss 🪙', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () => _tabController.animateTo(1),
              ),
            ),
          ],
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
              Text(
                '${players.length}/$_playersPerSide Players Added',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: players.length >= _playersPerSide ? const Color(0xFF166534) : Colors.grey,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.contacts, size: 16, color: Color(0xFF166534)),
                label: const Text(
                  '+ Add from Contacts',
                  style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: onAddPlayer,
              ),
            ],
          ),
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Text('No players added yet. Tap "+ Add from Contacts".', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
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
                    child: Text(
                      p.avatarInitials,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isTeamA ? const Color(0xFF166534) : const Color(0xFF2563EB),
                      ),
                    ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rename Team'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Team Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534), foregroundColor: Colors.white),
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
  Widget _buildCallingTeamSelector() {
    final callerOptions = <String>{_teamAName, _teamBName}.toList();
    if (!callerOptions.contains(_tossCaller)) {
      _tossCaller = callerOptions.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Calling Team:', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(_tossCaller ?? _teamAName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: callerOptions.map((team) {
            final isSel = _tossCaller == team;
            final isA = team == _teamAName;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  avatar: Icon(
                    isA ? Icons.shield : Icons.shield_outlined,
                    size: 16,
                    color: isSel ? (isA ? const Color(0xFF166534) : const Color(0xFF2563EB)) : Colors.grey,
                  ),
                  label: Text(
                    team,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? (isA ? const Color(0xFF166534) : const Color(0xFF2563EB)) : Colors.black87,
                    ),
                  ),
                  selected: isSel,
                  selectedColor: isA ? const Color(0xFFE5F5EB) : const Color(0xFFDBEAFE),
                  side: BorderSide(
                    color: isSel ? (isA ? const Color(0xFF166534) : const Color(0xFF2563EB)) : const Color(0xFFE5E7EB),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _tossCaller = team);
                    }
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCoinTossTab() {
    if (!_canPlayMatch) {
      return _buildPreMatchLockedCard(featureName: 'Coin Toss', featureIcon: Icons.toll_rounded);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Official Match Toss', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('$_currentSport • Flip the coin to decide who plays first', style: const TextStyle(fontSize: 13, color: Colors.grey)),
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
                  _isTossing ? 'FLIPPING...' : (_tossResult ?? 'FLIP\nCOIN'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
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
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  _buildCallingTeamSelector(),
                  const Divider(height: 24),
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
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _tossDecision = opt;
                            _ensureActivePlayers();
                          });
                        },
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
                    onPressed: _tossDecision == null ? null : () => _tabController.animateTo(2),
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
    if (!_canPlayMatch) {
      return _buildPreMatchLockedCard(featureName: 'Live Scorecard', featureIcon: Icons.scoreboard_rounded);
    }

    if (_isCricket) {
      return _buildCricketScorecard();
    } else if (_isFootball) {
      return _buildFootballScorecard();
    } else {
      return _buildRacketScorecard();
    }
  }

  Widget _buildCricketScorecard() {
    _ensureActivePlayers();

    final activeRuns = _currentCricketInning == 1 ? _cricketRunsA : _cricketRunsB;
    final activeWickets = _currentCricketInning == 1 ? _cricketWicketsA : _cricketWicketsB;
    final activeBalls = _currentCricketInning == 1 ? _cricketBallsA : _cricketBallsB;
    final activeTimeline = _currentCricketInning == 1 ? _cricketTimelineA : _cricketTimelineB;
    final battingTeam = _currentBattingTeam;
    final bowlingTeam = _currentBowlingTeam;

    final target = _cricketTarget ?? (_cricketRunsA + 1);
    final ballsRemaining = (_selectedOvers * 6) - _cricketBallsB;
    final runsNeeded = target - _cricketRunsB;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Inning Tab Switcher
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text('Inning 1: $_firstBattingTeam'),
                  selected: _currentCricketInning == 1,
                  selectedColor: const Color(0xFF166534),
                  labelStyle: TextStyle(color: _currentCricketInning == 1 ? Colors.white : Colors.black87),
                  onSelected: (_) {
                    setState(() {
                      _currentCricketInning = 1;
                      _ensureActivePlayers();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Text('Inning 2: $_secondBattingTeam'),
                  selected: _currentCricketInning == 2,
                  selectedColor: const Color(0xFF166534),
                  labelStyle: TextStyle(color: _currentCricketInning == 2 ? Colors.white : Colors.black87),
                  onSelected: (_) {
                    setState(() {
                      _currentCricketInning = 2;
                      _ensureActivePlayers();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Inning 2 Target Chasing Bar
          if (_currentCricketInning == 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.track_changes, color: Color(0xFFB45309), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'TARGET: $target',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                  Text(
                    runsNeeded > 0
                        ? 'Need $runsNeeded runs in ${ballsRemaining.clamp(0, 999)}b'
                        : '🎉 Target Achieved!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: runsNeeded > 0 ? const Color(0xFFB45309) : const Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),

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
                  'Overs: ${_formatOvers(activeBalls)} / $_selectedOvers  •  Bowling: $bowlingTeam',
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
          const SizedBox(height: 14),

          // Active Batters & Bowler Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('On Crease & Bowling:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Row(
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            minimumSize: const Size(40, 24),
                          ),
                          onPressed: () {
                            setState(() => _swapStrike());
                          },
                          child: const Text('🔄 Swap', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF6FF),
                            foregroundColor: const Color(0xFF1D4ED8),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(40, 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                            ),
                          ),
                          icon: const Icon(Icons.sports_cricket, size: 12, color: Color(0xFF1D4ED8)),
                          label: const Text('Change Bowler 🔄', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            _showSelectBowlerDialog(_currentBowlingSquad);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Striker
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F5EB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.star, size: 12, color: Color(0xFF166534)),
                                SizedBox(width: 4),
                                Text('Striker *', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _striker?.name ?? 'Batter 1',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _striker != null ? '${_getStat(_striker!).runs} (${_getStat(_striker!).balls}b)' : '0 (0b)',
                              style: const TextStyle(fontSize: 11, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Non-Striker
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Non-Striker', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              _nonStriker?.name ?? 'Batter 2',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _nonStriker != null ? '${_getStat(_nonStriker!).runs} (${_getStat(_nonStriker!).balls}b)' : '0 (0b)',
                              style: const TextStyle(fontSize: 11, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bowler (Clickable to change bowler in both innings)
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _showSelectBowlerDialog(_currentBowlingSquad),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Row(
                                    children: [
                                      Icon(Icons.sports_cricket, size: 12, color: Color(0xFF1D4ED8)),
                                      SizedBox(width: 4),
                                      Text('Bowler', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                                    ],
                                  ),
                                  Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFF1D4ED8)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentBowler?.name ?? 'Select Bowler',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _currentBowler != null
                                    ? '${_getStat(_currentBowler!).wickets}/${_getStat(_currentBowler!).runsConceded} (${_getStat(_currentBowler!).oversBowled} ov)'
                                    : 'Tap to pick 🎯',
                                style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 14),

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
          const SizedBox(height: 16),

          // Quick Scoring Keypad
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Tap to Add Runs / Events:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 20),

          // End Match / Innings Switch
          if (_currentCricketInning == 1) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F6D38),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Declare / Switch to 2nd Innings', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  _cricketTarget = _cricketRunsA + 1;
                  _showInningsBreakDialog();
                },
              ),
            ),
          ] else ...[
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
  // TAB 4: RESULT & MATCH SUMMARY & DETAILED AWARDS
  // ===========================================================================
  Widget _buildResultTab() {
    // If we have saved matches in this booking slot, pick the selected one
    final activeResult = _slotMatches.isNotEmpty && _selectedMatchHistoryIndex < _slotMatches.length
        ? _slotMatches[_selectedMatchHistoryIndex]
        : _loadedResult;

    if (!_isMatchCompleted && activeResult == null) {
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
              const Text(
                'Go to Tab 3 (Scorecard) to record runs/goals and complete the match.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF166534),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _tabController.animateTo(2),
                child: const Text('Go to Scorecard'),
              ),
            ],
          ),
        ),
      );
    }

    final result = activeResult;
    final winnerName = result?.winner ?? _finalWinner ?? 'Match Completed';
    final marginText = result?.winningMargin ?? _finalMargin ?? '';
    final userWon = winnerName == _teamAName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot Matches Switcher (if multiple matches played in this booked slot)
          if (_slotMatches.length > 1) ...[
            const Text('Matches in this Booked Slot:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_slotMatches.length, (idx) {
                  final isSel = idx == _selectedMatchHistoryIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('Match #${idx + 1} 🏆'),
                      selected: isSel,
                      selectedColor: const Color(0xFF166534),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : Colors.black87,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedMatchHistoryIndex = idx);
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Winner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events, size: 64, color: Color(0xFFD97706)),
                const SizedBox(height: 10),
                Text(
                  winnerName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Won $marginText',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                ),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(result?.teamAName ?? _teamAName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            result?.teamAScore ?? (_isCricket ? '$_cricketRunsA/$_cricketWicketsA' : '$_footballGoalsA'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Text('VS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Column(
                        children: [
                          Text(result?.teamBName ?? _teamBName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            result?.teamBScore ?? (_isCricket ? '$_cricketRunsB/$_cricketWicketsB' : '$_footballGoalsB'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
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
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Match Awards Grid (Player of Match, Top Scorer, Best Bowler, Best Fielder)
          const Text('Match Awards & Top Performers 🌟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildAwardTile(
                  title: 'Player of Match',
                  value: result?.manOfTheMatch ?? 'Match Performer',
                  icon: Icons.star_rounded,
                  color: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAwardTile(
                  title: 'Top Run Scorer',
                  value: result?.highestScorer ?? 'Top Batsman',
                  icon: Icons.sports_cricket,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildAwardTile(
                  title: 'Best Bowler',
                  value: result?.bestBowler ?? 'Top Bowler',
                  icon: Icons.track_changes,
                  color: const Color(0xFF166534),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAwardTile(
                  title: 'Best Fielder',
                  value: result?.bestFielder ?? 'Top Fielder',
                  icon: Icons.back_hand,
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Detailed Batting & Bowling Scorecards
          if (_isCricket) ...[
            _buildDetailedScorecardTable(
              teamName: result?.teamAName ?? _teamAName,
              stats: (result?.playerStatsA.isNotEmpty == true) ? result!.playerStatsA : _teamAPlayers.map((p) => _getStat(p)).toList(),
            ),
            const SizedBox(height: 14),
            _buildDetailedScorecardTable(
              teamName: result?.teamBName ?? _teamBName,
              stats: (result?.playerStatsB.isNotEmpty == true) ? result!.playerStatsB : _teamBPlayers.map((p) => _getStat(p)).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Rematch in Slot Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.replay_rounded),
              label: Text(
                'Start Rematch (Match #${_slotMatches.length + 1} in Slot) 🔄',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: _startRematch,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to My Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAwardTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedScorecardTable({
    required String teamName,
    required List<PlayerMatchStat> stats,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scorecard: $teamName',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF166534)),
          ),
          const Divider(height: 16),
          if (stats.isEmpty)
            const Text('No individual stats recorded.', style: TextStyle(fontSize: 12, color: Colors.grey))
          else ...[
            const Row(
              children: [
                Expanded(flex: 3, child: Text('Batter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(child: Text('4s', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(child: Text('6s', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 6),
            ...stats.map((s) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${s.name}${s.isOut ? "" : " *"}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: s.isOut ? FontWeight.normal : FontWeight.bold,
                          color: s.isOut ? Colors.black87 : const Color(0xFF166534),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(child: Text('${s.runs}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('${s.balls}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                    Expanded(child: Text('${s.fours}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                    Expanded(child: Text('${s.sixes}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                    Expanded(flex: 2, child: Text(s.strikeRate, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: Colors.black87))),
                  ],
                ),
              );
            }),
            const Divider(height: 16),
            const Row(
              children: [
                Expanded(flex: 3, child: Text('Bowler', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(child: Text('O', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(child: Text('M', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(child: Text('W', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 2, child: Text('Econ', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 6),
            ...stats.where((s) => s.ballsBowled > 0).map((s) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(s.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    Expanded(child: Text(s.oversBowled, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                    Expanded(child: Text('${s.maidens}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                    Expanded(child: Text('${s.runsConceded}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                    Expanded(child: Text('${s.wickets}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)))),
                    Expanded(flex: 2, child: Text(s.economy, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: Colors.black87))),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
