import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:games24_player_app/api_config.dart';
import 'package:games24_player_app/main_layout.dart';
import 'package:games24_player_app/teams_hub_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // Scopes: Friends, City, State, Global
  String _selectedScope = 'Global (Universal)';
  String _currentCity = 'Chennai';
  String _currentState = 'Tamil Nadu';

  // Sport Filter: All Sports, Cricket, Football, Badminton
  String _selectedSport = 'All Sports';

  // Role Filter: dependent on sport
  String _selectedRole = 'All Roles';

  // Current User Identification
  String _myPlayerId = 'PLY-0001';
  String _myPhone = '+919087786231';
  String _myName = 'Active Player';

  // Search & Filter
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // State Data
  bool _isLoading = true;
  List<Map<String, dynamic>> _leaderboard = [];
  Map<String, dynamic> _currentUserRank = {
    'rank': 1,
    'points': '3,580',
    'pointsNumeric': 3580,
    'role': 'All-Rounder',
    'pointsToNext': 0,
    'targetPlayerName': '',
    'totalContenders': 0,
  };
  List<Map<String, dynamic>> _incomingRequests = [];
  Map<String, dynamic> _season = {
    'name': 'Season 4 Final Lap',
    'daysLeft': 12,
    'reward': 'Top 3 earn ₹25,000 Vouchers + Golden Jersey',
  };

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final rawPhone = prefs.getString('mobileNumber') ?? '';
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final fallbackId = 'PLY-${digits.length >= 4 ? digits.substring(digits.length - 4) : '0001'}';

    setState(() {
      _myPhone = rawPhone.isNotEmpty ? rawPhone : '+919087786231';
      _myPlayerId = prefs.getString('playerId') ?? fallbackId;
      _myName = prefs.getString('fullName') ?? 'Active Player';
      _currentCity = prefs.getString('userCity') ?? 'Chennai';
      _currentState = prefs.getString('userState') ?? 'Tamil Nadu';
    });

    await Future.wait([
      _fetchLeaderboard(),
      _fetchFriendsAndRequests(),
    ]);
  }

  String _getScopeParam() {
    if (_selectedScope.startsWith('Friends')) return 'friends';
    if (_selectedScope.contains('City') || _selectedScope == _currentCity) return 'city';
    if (_selectedScope.contains('State') || _selectedScope == _currentState) return 'state';
    return 'global';
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    final scopeParam = _getScopeParam();
    final sportParam = _selectedSport == 'All Sports' ? 'All' : _selectedSport;
    final roleParam = _selectedRole == 'All Roles' ? 'All' : _selectedRole;

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/auth/leaderboard'
      '?scope=$scopeParam'
      '&sport=$sportParam'
      '&role=$roleParam'
      '&city=${Uri.encodeComponent(_currentCity)}'
      '&state=${Uri.encodeComponent(_currentState)}'
      '&phone=${Uri.encodeComponent(_myPhone)}'
      '&playerId=${Uri.encodeComponent(_myPlayerId)}',
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _leaderboard = List<Map<String, dynamic>>.from(data['leaderboard'] ?? []);
            if (data['currentUserRank'] != null) {
              _currentUserRank = Map<String, dynamic>.from(data['currentUserRank']);
            }
            if (data['season'] != null) {
              _season = Map<String, dynamic>.from(data['season']);
            }
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Leaderboard fetch error: $e");
    }

    // Fallback seed calculation if network offline
    if (mounted) {
      _loadFallbackLeaderboard();
    }
  }

  void _loadFallbackLeaderboard() {
    final seedPlayers = [
      {
        'rank': 1,
        'change': '-',
        'isChangeNegative': false,
        'playerId': _myPlayerId,
        'name': _myName,
        'phone': _myPhone,
        'city': _currentCity,
        'state': _currentState,
        'location': '$_currentCity, $_currentState',
        'sport': 'Cricket',
        'role': 'All-Rounder',
        'points': '3,580',
        'pointsNumeric': 3580,
        'wins': '15 Wins',
        'matchesPlayed': 18,
        'winRate': '83% W',
        'imageUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        'badge': 'Universal Elite',
        'isVerified': true,
        'isYou': true,
        'friendshipStatus': 'none',
        'statsSummary': '460 Runs • 18 Wkts',
      },
      {
        'rank': 2,
        'change': '+ 2',
        'isChangeNegative': false,
        'playerId': 'PLY-1045',
        'name': 'Rohan Sharma',
        'phone': '+919876543204',
        'city': 'Bangalore',
        'state': 'Karnataka',
        'location': 'Bangalore, Karnataka',
        'sport': 'Cricket',
        'role': 'Batter',
        'points': '3,450',
        'pointsNumeric': 3450,
        'wins': '14 Wins',
        'matchesPlayed': 17,
        'winRate': '82% W',
        'imageUrl': 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
        'badge': 'Century King',
        'isVerified': true,
        'isYou': false,
        'friendshipStatus': 'none',
        'statsSummary': '560 Runs • 1 Wkts',
      },
      {
        'rank': 3,
        'change': '+ 1',
        'isChangeNegative': false,
        'playerId': 'PLY-1078',
        'name': 'Vikram Sethi',
        'phone': '+919876543207',
        'city': 'Delhi NCR',
        'state': 'Delhi',
        'location': 'Delhi NCR, Delhi',
        'sport': 'Football',
        'role': 'Forward / Striker',
        'points': '3,420',
        'pointsNumeric': 3420,
        'wins': '15 Wins',
        'matchesPlayed': 18,
        'winRate': '83% W',
        'imageUrl': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        'badge': 'Golden Boot',
        'isVerified': true,
        'isYou': false,
        'friendshipStatus': 'none',
        'statsSummary': '24 Goals • 8 Ast',
      },
      {
        'rank': 4,
        'change': '-',
        'isChangeNegative': false,
        'playerId': 'PLY-0002',
        'name': 'mafaz',
        'phone': '+918124817806',
        'city': 'Chennai',
        'state': 'Tamil Nadu',
        'location': 'Chennai, Tamil Nadu',
        'sport': 'Cricket',
        'role': 'Batter',
        'points': '3,240',
        'pointsNumeric': 3240,
        'wins': '11 Wins',
        'matchesPlayed': 15,
        'winRate': '73% W',
        'imageUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'badge': 'Turf Master',
        'isVerified': true,
        'isYou': false,
        'friendshipStatus': 'accepted',
        'statsSummary': '490 Runs • 2 Wkts',
      },
      {
        'rank': 5,
        'change': '+ 1',
        'isChangeNegative': false,
        'playerId': 'PLY-0003',
        'name': 'Vignesh',
        'phone': '+917010396731',
        'city': 'Chennai',
        'state': 'Tamil Nadu',
        'location': 'Chennai, Tamil Nadu',
        'sport': 'Cricket',
        'role': 'Bowler',
        'points': '3,110',
        'pointsNumeric': 3110,
        'wins': '10 Wins',
        'matchesPlayed': 14,
        'winRate': '71% W',
        'imageUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        'badge': 'Wicket Machine',
        'isVerified': true,
        'isYou': false,
        'friendshipStatus': 'pending_received',
        'statsSummary': '95 Runs • 26 Wkts',
      },
      {
        'rank': 6,
        'change': '- 1',
        'isChangeNegative': true,
        'playerId': 'PLY-1014',
        'name': 'Karthik Raman',
        'phone': '+919876543201',
        'city': 'Chennai',
        'state': 'Tamil Nadu',
        'location': 'Chennai, Tamil Nadu',
        'sport': 'Cricket',
        'role': 'Bowler',
        'points': '3,150',
        'pointsNumeric': 3150,
        'wins': '12 Wins',
        'matchesPlayed': 16,
        'winRate': '75% W',
        'imageUrl': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
        'badge': 'Death Overs Ace',
        'isVerified': true,
        'isYou': false,
        'friendshipStatus': 'none',
        'statsSummary': '80 Runs • 28 Wkts',
      },
    ];

    // Filter fallback by scope
    List<Map<String, dynamic>> filtered = List.from(seedPlayers);
    final scopeParam = _getScopeParam();
    if (scopeParam == 'friends') {
      filtered = filtered.where((p) => p['isYou'] == true || p['friendshipStatus'] == 'accepted').toList();
    } else if (scopeParam == 'city') {
      filtered = filtered.where((p) => (p['city'] as String).toLowerCase() == _currentCity.toLowerCase()).toList();
    } else if (scopeParam == 'state') {
      filtered = filtered.where((p) => (p['state'] as String).toLowerCase() == _currentState.toLowerCase()).toList();
    }

    if (_selectedSport != 'All Sports') {
      filtered = filtered.where((p) => (p['sport'] as String).toLowerCase() == _selectedSport.toLowerCase()).toList();
    }

    if (_selectedRole != 'All Roles') {
      filtered = filtered.where((p) => (p['role'] as String).toLowerCase() == _selectedRole.toLowerCase()).toList();
    }

    filtered.sort((a, b) => (b['pointsNumeric'] as int).compareTo(a['pointsNumeric'] as int));

    for (int i = 0; i < filtered.length; i++) {
      filtered[i]['rank'] = i + 1;
    }

    setState(() {
      _leaderboard = filtered;
      _isLoading = false;
    });
  }

  Future<void> _fetchFriendsAndRequests() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/auth/friends?identifier=$_myPhone')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _incomingRequests = List<Map<String, dynamic>>.from(data['incomingRequests'] ?? []);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _sendFriendRequest(Map<String, dynamic> target) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/friends/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fromPhone': _myPhone,
          'fromPlayerId': _myPlayerId,
          'fromName': _myName,
          'toPlayerId': target['playerId'],
          'toPhone': target['phone'] ?? '',
          'toName': target['name'],
        }),
      );

      final body = jsonDecode(res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.person_add_alt_1, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(body['message'] ?? 'Friend request sent!')),
              ],
            ),
            backgroundColor: const Color(0xFF154D36),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchLeaderboard();
        _fetchFriendsAndRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    }
  }

  Future<void> _respondFriendRequest(String requestId, String action) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/friends/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestId': requestId,
          'action': action,
          'responderPhone': _myPhone,
          'responderPlayerId': _myPlayerId,
        }),
      );

      final body = jsonDecode(res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? 'Request updated'),
            backgroundColor: action == 'accept' ? const Color(0xFF154D36) : Colors.grey[800],
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchLeaderboard();
        _fetchFriendsAndRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating friend request: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    }
  }

  List<String> _getRolesForCurrentSport() {
    if (_selectedSport == 'Cricket') {
      return ['All Roles', 'All-Rounder', 'Batter', 'Bowler', 'Wicket-Keeper'];
    } else if (_selectedSport == 'Football') {
      return ['All Roles', 'Forward / Striker', 'Midfielder', 'Defender', 'Goalkeeper'];
    } else if (_selectedSport == 'Badminton') {
      return ['All Roles', 'Singles Specialist', 'Doubles Specialist'];
    }
    return ['All Roles'];
  }

  @override
  Widget build(BuildContext context) {
    // Filter by search query if active
    final query = _searchController.text.trim().toLowerCase();
    final displayedList = query.isEmpty
        ? _leaderboard
        : _leaderboard.where((p) {
            final name = (p['name'] ?? '').toString().toLowerCase();
            final id = (p['playerId'] ?? '').toString().toLowerCase();
            final role = (p['role'] ?? '').toString().toLowerCase();
            return name.contains(query) || id.contains(query) || role.contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchLeaderboard();
          await _fetchFriendsAndRequests();
        },
        color: const Color(0xFF154D36),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSearching) _buildSearchBar(),
              _buildSeasonBanner(),
              _buildScopeTabs(),
              _buildSportFilterChips(),
              if (_selectedSport != 'All Sports') _buildRoleFilterChips(),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF154D36)),
                  ),
                )
              else ...[
                if (displayedList.length >= 3) _buildPodium(displayedList.take(3).toList()),
                _buildCurrentUserCard(),
                _buildRankingsList(displayedList),
                _buildHowPointsWorkCard(),
                const SizedBox(height: 36),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
        children: [
          Row(
            children: [
              const Text(
                'Leaderboard',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF154D36),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Season 4',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.location_on, size: 10, color: Colors.green[700]),
              const SizedBox(width: 3),
              Text(
                '$_currentCity • $_currentState',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: Colors.black87,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchController.clear();
            });
          },
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.person_add_outlined, color: Colors.black87),
              tooltip: 'Friend Requests',
              onPressed: _showFriendRequestsModal,
            ),
            if (_incomingRequests.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${_incomingRequests.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.tune_outlined, color: Colors.black87),
          tooltip: 'Change City / State',
          onPressed: _showLocationPickerModal,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by Player Name or ID (e.g. PLY-0002)...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF154D36)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          filled: true,
          fillColor: const Color(0xFFF3F5F1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F3D2A), Color(0xFF154D36)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF154D36).withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.amberAccent,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _season['name'] ?? 'Season 4 Final Lap',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_season['daysLeft'] ?? 12}d left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _season['reward'] ?? 'Top 3 earn ₹25,000 Vouchers + Golden Jersey',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
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

  Widget _buildScopeTabs() {
    final scopes = [
      {'title': 'Friends', 'key': 'Friends'},
      {'title': _currentCity, 'key': _currentCity},
      {'title': _currentState, 'key': _currentState},
      {'title': 'Global', 'key': 'Global (Universal)'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: scopes.map((tab) {
            final isSelected = _selectedScope == tab['key'] ||
                (_selectedScope.startsWith('Friends') && tab['key'] == 'Friends') ||
                (_selectedScope.startsWith('City') && tab['key'] == _currentCity) ||
                (_selectedScope.startsWith('State') && tab['key'] == _currentState);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedScope = tab['key']!;
                  });
                  _fetchLeaderboard();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      tab['title']!,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF154D36) : Colors.grey[700],
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSportFilterChips() {
    final sports = [
      {'label': 'All Sports', 'icon': Icons.all_inclusive_rounded},
      {'label': 'Cricket', 'icon': Icons.sports_cricket_rounded},
      {'label': 'Football', 'icon': Icons.sports_soccer_rounded},
      {'label': 'Badminton', 'icon': Icons.sports_tennis_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: sports.map((s) {
          final isSelected = _selectedSport == s['label'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              avatar: Icon(
                s['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF154D36),
              ),
              label: Text(
                s['label'] as String,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF154D36),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF154D36) : Colors.grey[300]!,
                ),
              ),
              onSelected: (val) {
                setState(() {
                  _selectedSport = s['label'] as String;
                  _selectedRole = 'All Roles';
                });
                _fetchLeaderboard();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoleFilterChips() {
    final roles = _getRolesForCurrentSport();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: roles.map((r) {
          final isSelected = _selectedRole == r;
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ChoiceChip(
              label: Text(
                r,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[800],
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF154D36),
              backgroundColor: const Color(0xFFE5F5EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF154D36) : Colors.transparent,
                ),
              ),
              onSelected: (val) {
                setState(() {
                  _selectedRole = r;
                });
                _fetchLeaderboard();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    if (top3.length < 3) return const SizedBox.shrink();
    final first = top3[0];
    final second = top3[1];
    final third = top3[2];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPodiumColumn(player: second, rank: 2, height: 110, medalColor: Colors.grey[400]!),
          const SizedBox(width: 14),
          _buildPodiumColumn(player: first, rank: 1, height: 135, medalColor: Colors.amber[700]!, isCenter: true),
          const SizedBox(width: 14),
          _buildPodiumColumn(player: third, rank: 3, height: 95, medalColor: Colors.brown[400]!),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required Map<String, dynamic> player,
    required int rank,
    required double height,
    required Color medalColor,
    bool isCenter = false,
  }) {
    final avatarSize = isCenter ? 72.0 : 58.0;
    final isYou = player['isYou'] == true;

    return GestureDetector(
      onTap: () => _showPlayerProfileModal(player),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isCenter
                        ? [Colors.amber, Colors.orangeAccent]
                        : [Colors.grey[300]!, Colors.grey[100]!],
                  ),
                ),
                child: CircleAvatar(
                  radius: avatarSize / 2,
                  backgroundColor: const Color(0xFF154D36),
                  backgroundImage: player['imageUrl'] != null ? NetworkImage(player['imageUrl']) : null,
                  child: player['imageUrl'] == null
                      ? Text(
                          (player['name'] ?? 'P').substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
              if (isCenter)
                const Positioned(
                  top: -16,
                  child: Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
                )
              else
                Positioned(
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: medalColor,
                      ),
                    ),
                  ),
                ),
              if (isYou)
                Positioned(
                  bottom: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF154D36),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            player['name'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isCenter ? 13 : 11,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F5EB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              player['role'] ?? player['sport'] ?? '',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF154D36),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${player['points']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isCenter ? 14 : 12,
                    color: isCenter ? Colors.amber[900] : const Color(0xFF154D36),
                  ),
                ),
                Text(
                  'PTS • ${player['winRate']}',
                  style: TextStyle(fontSize: 8.5, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserCard() {
    final rank = _currentUserRank['rank'] ?? 1;
    final points = _currentUserRank['points'] ?? '3,580';
    final role = _currentUserRank['role'] ?? 'All-Rounder';
    final pointsToNext = _currentUserRank['pointsToNext'] ?? 0;
    final targetName = _currentUserRank['targetPlayerName'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBBE5CA)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF154D36).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF154D36),
                      child: Text(
                        _myName.isNotEmpty ? _myName.substring(0, 1).toUpperCase() : 'P',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF154D36),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '#$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                        children: [
                          Text(
                            _myName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5F5EB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              role,
                              style: const TextStyle(
                                color: Color(0xFF154D36),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: $_myPlayerId • $_currentCity, $_currentState',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$points',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF154D36),
                      ),
                    ),
                    const Text(
                      'Universal PTS',
                      style: TextStyle(color: Colors.grey, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
            if (pointsToNext > 0 && targetName.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Color(0xFF154D36), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$pointsToNext pts to overtake $targetName',
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                  const Spacer(),
                  const Text(
                    '88%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF154D36),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: 0.88,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF154D36)),
                minHeight: 5,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRankingsList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.military_tech_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                _selectedScope.startsWith('Friends')
                    ? 'No friends ranked in this filter yet.'
                    : 'No contenders found for the selected criteria.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              if (_selectedScope.startsWith('Friends')) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _selectedScope = 'Global (Universal)');
                    _fetchLeaderboard();
                  },
                  icon: const Icon(Icons.person_add_alt, size: 16),
                  label: const Text('Add Friends from Global Rankings'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF154D36)),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedScope.replaceAll(RegExp(r'[^a-zA-Z\s]'), '')} Rankings',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Showing ${list.length} active contender${list.length > 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
              InkWell(
                onTap: _showLocationPickerModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tune, size: 13, color: Colors.black87),
                      const SizedBox(width: 4),
                      Text(
                        _currentCity,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFF0F2F5)),
          itemBuilder: (context, index) {
            final player = list[index];
            return _buildRankRow(player);
          },
        ),
      ],
    );
  }

  Widget _buildRankRow(Map<String, dynamic> player) {
    final rank = player['rank'] ?? 0;
    final name = player['name'] ?? 'Player';
    final playerId = player['playerId'] ?? '';
    final role = player['role'] ?? player['sport'] ?? 'All-Rounder';
    final location = player['location'] ?? 'Chennai';
    final points = player['points'] ?? '0';
    final statsSummary = player['statsSummary'] ?? '${player['wins']}';
    final change = player['change'] ?? '-';
    final isNegative = player['isChangeNegative'] == true;
    final isVerified = player['isVerified'] == true;
    final isYou = player['isYou'] == true;

    Color changeColor = change == '-'
        ? Colors.grey
        : (isNegative ? Colors.red : const Color(0xFF154D36));

    return InkWell(
      onTap: () => _showPlayerProfileModal(player),
      child: Container(
        color: isYou ? const Color(0xFFF3F9F5) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                  color: rank <= 3 ? const Color(0xFF154D36) : Colors.black87,
                ),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF154D36),
                  backgroundImage: player['imageUrl'] != null ? NetworkImage(player['imageUrl']) : null,
                  child: player['imageUrl'] == null
                      ? Text(
                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                if (isVerified)
                  const Positioned(
                    bottom: -2,
                    right: -2,
                    child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isYou) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF154D36),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      if (change == '-')
                        const Text('—', style: TextStyle(color: Colors.grey, fontSize: 10))
                      else
                        Row(
                          children: [
                            Icon(
                              isNegative ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                              color: changeColor,
                              size: 16,
                            ),
                            Text(
                              change.replaceAll(RegExp(r'[+-]\s'), ''),
                              style: TextStyle(
                                color: changeColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (playerId.isNotEmpty) ...[
                        Text(
                          '$playerId • ',
                          style: const TextStyle(color: Color(0xFF154D36), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ],
                      Text(
                        location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Text('•', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F5EB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(
                            color: Color(0xFF154D36),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$points',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF154D36),
                  ),
                ),
                Text(
                  statsSummary,
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 8),
            _buildFriendshipActionIcon(player),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendshipActionIcon(Map<String, dynamic> player) {
    if (player['isYou'] == true) {
      return const SizedBox(width: 24);
    }

    final status = player['friendshipStatus'] ?? 'none';
    if (status == 'accepted') {
      return const Tooltip(
        message: 'Friends',
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.people_alt_rounded, color: Color(0xFF154D36), size: 18),
        ),
      );
    } else if (status == 'pending_sent') {
      return const Tooltip(
        message: 'Request Pending',
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 18),
        ),
      );
    } else if (status == 'pending_received') {
      return IconButton(
        icon: const Icon(Icons.check_circle_outline, color: Color(0xFF154D36), size: 20),
        tooltip: 'Accept Friend Request',
        onPressed: () {
          final reqId = player['friendRequestId'];
          if (reqId != null) _respondFriendRequest(reqId, 'accept');
        },
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.person_add_alt, color: Colors.grey, size: 20),
        tooltip: 'Send Friend Request',
        onPressed: () => _sendFriendRequest(player),
      );
    }
  }

  // ==========================================
  // INTERACTIVE PLAYER PROFILE MODAL
  // ==========================================
  void _showPlayerProfileModal(Map<String, dynamic> player) {
    final isYou = player['isYou'] == true;
    final status = player['friendshipStatus'] ?? 'none';
    final name = player['name'] ?? 'Player';
    final playerId = player['playerId'] ?? '';
    final role = player['role'] ?? player['sport'] ?? 'All-Rounder';
    final sport = player['sport'] ?? 'Cricket';
    final location = player['location'] ?? '$_currentCity, $_currentState';
    final points = player['points'] ?? '0';
    final matches = player['matchesPlayed'] ?? 10;
    final wins = player['wins'] ?? '0';
    final winRate = player['winRate'] ?? '80%';
    final statsSummary = player['statsSummary'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF154D36),
                          backgroundImage: player['imageUrl'] != null ? NetworkImage(player['imageUrl']) : null,
                          child: player['imageUrl'] == null
                              ? Text(
                                  name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (player['isVerified'] == true) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified, color: Color(0xFF10B981), size: 18),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5F5EB),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'ID: $playerId',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF154D36),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: playerId));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Copied $playerId'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    child: const Icon(Icons.copy, size: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$location • $sport $role',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Friendship / Action Status Banner
                    if (!isYou) ...[
                      if (status == 'accepted')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F5EB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBE5CA)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.handshake_rounded, color: Color(0xFF154D36), size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'You are friends! Ranked together on Friends Leaderboard.',
                                  style: TextStyle(
                                    color: Color(0xFF154D36),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (status == 'pending_sent')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Friend request sent. Waiting for player to accept.',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (status == 'pending_received')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  final reqId = player['friendRequestId'];
                                  if (reqId != null) _respondFriendRequest(reqId, 'accept');
                                },
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Accept Friend'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF154D36),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  final reqId = player['friendRequestId'];
                                  if (reqId != null) _respondFriendRequest(reqId, 'decline');
                                },
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Decline'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _sendFriendRequest(player);
                            },
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: const Text('Send Friend Request 👋'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF154D36),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],

                    // Performance & Stats Grid
                    const Text(
                      'CAREER PERFORMANCE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatBox('Universal PTS', '$points', Icons.stars, Colors.amber[700]!),
                        const SizedBox(width: 10),
                        _buildStatBox('Wins ($matches M)', '$wins', Icons.emoji_events, const Color(0xFF154D36)),
                        const SizedBox(width: 10),
                        _buildStatBox('Win Rate', '$winRate', Icons.trending_up, Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$sport Metrics',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                statsSummary.isNotEmpty ? statsSummary : '150+ Runs • 12 Wickets',
                                style: TextStyle(color: Colors.grey[700], fontSize: 11),
                              ),
                            ],
                          ),
                          Row(
                            children: const [
                              Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                              SizedBox(width: 2),
                              Text(
                                'Form 92%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Color(0xFF154D36),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Head to Head & Team Invite Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showHeadToHeadModal(player);
                            },
                            icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                            label: const Text('Head-to-Head'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF154D36),
                              side: const BorderSide(color: Color(0xFF154D36)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TeamsHubScreen()),
                              );
                            },
                            icon: const Icon(Icons.groups_outlined, size: 18),
                            label: const Text('Invite to Squad'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HEAD-TO-HEAD COMPARISON MODAL
  // ==========================================
  void _showHeadToHeadModal(Map<String, dynamic> target) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'HEAD-TO-HEAD COMPARISON',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF154D36),
                        child: Text(
                          _myName.isNotEmpty ? _myName.substring(0, 1).toUpperCase() : 'Y',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('You ($_myName)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(_currentUserRank['role'] ?? 'All-Rounder', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.blueGrey,
                        backgroundImage: target['imageUrl'] != null ? NetworkImage(target['imageUrl']) : null,
                        child: target['imageUrl'] == null
                            ? Text(
                                (target['name'] ?? 'P').substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(target['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(target['role'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildCompareRow('Points', '${_currentUserRank['points']}', '${target['points']}'),
              _buildCompareRow('Wins', '${_currentUserRank['wins'] ?? '15 Wins'}', '${target['wins']}'),
              _buildCompareRow('Matches', '18', '${target['matchesPlayed'] ?? 15}'),
              _buildCompareRow('Win Rate', '83%', '${target['winRate'] ?? '75%'}'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF154D36),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close Comparison'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompareRow(String metric, String val1, String val2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              val1,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF154D36)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              metric,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              val2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INCOMING FRIEND REQUESTS MODAL
  // ==========================================
  void _showFriendRequestsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Incoming Friend Requests',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F5EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_incomingRequests.length} Pending',
                          style: const TextStyle(
                            color: Color(0xFF154D36),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_incomingRequests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            const Text(
                              'No pending friend requests.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _incomingRequests.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final req = _incomingRequests[idx];
                        final senderName = req['fromName'] ?? 'Player';
                        final senderId = req['fromPlayerId'] ?? '';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF154D36),
                            child: Text(
                              senderName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('ID: $senderId', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Color(0xFF154D36), size: 24),
                                onPressed: () async {
                                  await _respondFriendRequest(req['id'], 'accept');
                                  setSheetState(() {
                                    _incomingRequests.removeAt(idx);
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.cancel, color: Colors.red[400], size: 24),
                                onPressed: () async {
                                  await _respondFriendRequest(req['id'], 'decline');
                                  setSheetState(() {
                                    _incomingRequests.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // LOCATION PICKER MODAL (CITY / STATE)
  // ==========================================
  void _showLocationPickerModal() {
    final locations = [
      {'city': 'Chennai', 'state': 'Tamil Nadu'},
      {'city': 'Coimbatore', 'state': 'Tamil Nadu'},
      {'city': 'Madurai', 'state': 'Tamil Nadu'},
      {'city': 'Bangalore', 'state': 'Karnataka'},
      {'city': 'Mumbai', 'state': 'Maharashtra'},
      {'city': 'Delhi NCR', 'state': 'Delhi'},
      {'city': 'Hyderabad', 'state': 'Telangana'},
      {'city': 'Pune', 'state': 'Maharashtra'},
      {'city': 'Kochi', 'state': 'Kerala'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Your Home Region',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Filter leaderboard standings by your metropolitan turf zone.',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: locations.length,
                  itemBuilder: (context, idx) {
                    final loc = locations[idx];
                    final isCurrent = loc['city'] == _currentCity && loc['state'] == _currentState;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.location_city,
                        color: isCurrent ? const Color(0xFF154D36) : Colors.grey,
                      ),
                      title: Text(
                        loc['city']!,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent ? const Color(0xFF154D36) : Colors.black87,
                        ),
                      ),
                      subtitle: Text(loc['state']!, style: const TextStyle(fontSize: 11)),
                      trailing: isCurrent
                          ? const Icon(Icons.check_circle, color: Color(0xFF154D36), size: 20)
                          : null,
                      onTap: () async {
                        final nav = Navigator.of(context);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('userCity', loc['city']!);
                        await prefs.setString('userState', loc['state']!);
                        if (mounted) {
                          setState(() {
                            _currentCity = loc['city']!;
                            _currentState = loc['state']!;
                          });
                          nav.pop();
                          _fetchLeaderboard();
                        }
                      },
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

  Widget _buildHowPointsWorkCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.stars, color: Color(0xFF154D36), size: 18),
                SizedBox(width: 8),
                Text(
                  'Authentic Universal Points Calculation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Rankings are dynamically calculated from verified turf bookings: +60 pts per Match Win, +95 pts per MVP award, +1.5 pts per Cricket Run, +25 pts per Wicket, and +35 pts per Football Goal.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoBadge(const Color(0xFF154D36), 'Match Wins (+60)'),
                const SizedBox(width: 10),
                _buildInfoBadge(Colors.amber[800]!, 'MVP (+95)'),
                const SizedBox(width: 10),
                _buildInfoBadge(Colors.blue[700]!, 'Runs & Wickets'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(Color color, String label) {
    return Row(
      children: [
        Icon(Icons.circle, size: 6, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 10)),
      ],
    );
  }
}
