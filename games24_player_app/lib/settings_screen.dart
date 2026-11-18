import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:games24_player_app/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _matchReminders = true;
  bool _challengeAlerts = true;

  String _fullName = 'Loading...';
  String _mobileNumber = 'Loading...';
  String _preferredSport = 'Football';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName =
          prefs.getString('fullName') ??
          prefs.getString('userName') ??
          'Games24 Player';
      _mobileNumber = prefs.getString('mobileNumber') ?? 'Not Available';
      _preferredSport = prefs.getString('preferredSport') ?? 'Football';

      _pushNotifications = prefs.getBool('pref_push_notif') ?? true;
      _matchReminders = prefs.getBool('pref_match_remind') ?? true;
      _challengeAlerts = prefs.getBool('pref_challenge_alerts') ?? true;
    });
  }

  Future<void> _updatePref(
    String key,
    bool val,
    void Function(bool) updater,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
    setState(() => updater(val));
  }

  void _showPolicyDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181818),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF262626)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFFA1A1AA),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4FF00),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('ACCOUNT PROFILE'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                      color: Color(0xFFD4FF00),
                    ),
                    title: const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      _fullName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFF262626)),
                  ListTile(
                    leading: const Icon(
                      Icons.phone_outlined,
                      color: Color(0xFFD4FF00),
                    ),
                    title: const Text(
                      'Mobile Number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      _mobileNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFF262626)),
                  ListTile(
                    leading: const Icon(
                      Icons.sports_soccer_outlined,
                      color: Color(0xFFD4FF00),
                    ),
                    title: const Text(
                      'Preferred Sport',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      _preferredSport,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('NOTIFICATIONS'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeThumbColor: const Color(0xFFD4FF00),
                    activeTrackColor: const Color(0xFF1F2916),
                    secondary: const Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFFD4FF00),
                    ),
                    title: const Text(
                      'Push Notifications',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: const Text(
                      'Receive match confirmations & updates',
                      style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                    ),
                    value: _pushNotifications,
                    onChanged: (val) => _updatePref(
                      'pref_push_notif',
                      val,
                      (v) => _pushNotifications = v,
                    ),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFF262626)),
                  SwitchListTile(
                    activeThumbColor: const Color(0xFFD4FF00),
                    activeTrackColor: const Color(0xFF1F2916),
                    secondary: const Icon(
                      Icons.alarm_outlined,
                      color: Color(0xFFD4FF00),
                    ),
                    title: const Text(
                      'Match Reminders',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: const Text(
                      '1 hour before game time',
                      style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                    ),
                    value: _matchReminders,
                    onChanged: (val) => _updatePref(
                      'pref_match_remind',
                      val,
                      (v) => _matchReminders = v,
                    ),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFF262626)),
                  SwitchListTile(
                    activeThumbColor: const Color(0xFFD4FF00),
                    activeTrackColor: const Color(0xFF1F2916),
                    secondary: const Icon(
                      Icons.flag_outlined,
                      color: Color(0xFFD4FF00),
                    ),
                    title: const Text(
                      'Open Challenge Alerts',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: const Text(
                      'Nearby open challenge invites',
                      style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                    ),
                    value: _challengeAlerts,
                    onChanged: (val) => _updatePref(
                      'pref_challenge_alerts',
                      val,
                      (v) => _challengeAlerts = v,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('LEGAL & ABOUT'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.privacy_tip_outlined,
                      color: Color(0xFFD4FF00),
                    ),
                    title: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFA1A1AA),
                    ),
                    onTap: () => _showPolicyDialog(
                      'Privacy Policy',
                      'Games24 takes your privacy seriously. We securely store your mobile number and bookings to facilitate turf reservations and challenge coordination. We do not sell your personal data to any third parties.',
                    ),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFF262626)),
                  ListTile(
                    leading: const Icon(
                      Icons.description_outlined,
                      color: Color(0xFFD4FF00),
                    ),
                    title: const Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFA1A1AA),
                    ),
                    onTap: () => _showPolicyDialog(
                      'Terms of Service',
                      'By booking slots or joining open challenges via Games24, players agree to follow fair play guidelines, arrive promptly at scheduled slots, and respect turf facility equipment and rules.',
                    ),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFF262626)),
                  const ListTile(
                    leading: Icon(Icons.info_outline, color: Color(0xFFD4FF00)),
                    title: Text(
                      'App Version',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    trailing: Text(
                      'v1.0.0 (Production)',
                      style: TextStyle(fontSize: 13, color: Color(0xFFA1A1AA)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                label: const Text(
                  'Log Out from Games24',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFFA1A1AA),
        letterSpacing: 1.0,
      ),
    );
  }
}
