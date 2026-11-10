import 'main_layout.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/utils/toast_utils.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _fullName = '';
  String _mobileNumber = '';
  String _preferredSport = 'Football';
  bool _pushNotifications = true;
  bool _matchReminders = true;
  bool _challengeAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fullName = prefs.getString('fullName') ?? 'Player';
        _mobileNumber = prefs.getString('mobileNumber') ?? '';
        _preferredSport = prefs.getString('preferredSport') ?? 'Football';
        _pushNotifications = prefs.getBool('pref_push_notif') ?? true;
        _matchReminders = prefs.getBool('pref_match_remind') ?? true;
        _challengeAlerts = prefs.getBool('pref_challenge_alerts') ?? true;
      });
    }
  }

  Future<void> _updatePref(String key, bool val, Function(bool) updater) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
    setState(() => updater(val));
    if (mounted) {
      ToastUtils.showSuccess(context, 'Preferences updated');
    }
  }

  void _showPolicyDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(body, style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF374151))),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534)),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827), size: 20),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: Color(0xFF166534)),
                    title: const Text('Full Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(_fullName, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: Color(0xFF166534)),
                    title: const Text('Mobile Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(_mobileNumber, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.sports_soccer_outlined, color: Color(0xFF166534)),
                    title: const Text('Preferred Sport', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(_preferredSport, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('NOTIFICATIONS'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeThumbColor: const Color(0xFF166534),
                    secondary: const Icon(Icons.notifications_active_outlined, color: Color(0xFF166534)),
                    title: const Text('Push Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Receive match confirmations & updates', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    value: _pushNotifications,
                    onChanged: (val) => _updatePref('pref_push_notif', val, (v) => _pushNotifications = v),
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    activeThumbColor: const Color(0xFF166534),
                    secondary: const Icon(Icons.alarm_outlined, color: Color(0xFF166534)),
                    title: const Text('Match Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('1 hour before game time', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    value: _matchReminders,
                    onChanged: (val) => _updatePref('pref_match_remind', val, (v) => _matchReminders = v),
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    activeThumbColor: const Color(0xFF166534),
                    secondary: const Icon(Icons.flag_outlined, color: Color(0xFF166534)),
                    title: const Text('Open Challenge Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Nearby open challenge invites', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    value: _challengeAlerts,
                    onChanged: (val) => _updatePref('pref_challenge_alerts', val, (v) => _challengeAlerts = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('LEGAL & ABOUT'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF166534)),
                    title: const Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                    onTap: () => _showPolicyDialog(
                      'Privacy Policy',
                      'Games24 takes your privacy seriously. We securely store your mobile number and bookings to facilitate turf reservations and challenge coordination. We do not sell your personal data to any third parties.',
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: Color(0xFF166534)),
                    title: const Text('Terms of Service', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                    onTap: () => _showPolicyDialog(
                      'Terms of Service',
                      'By booking slots or joining open challenges via Games24, players agree to follow fair play guidelines, arrive promptly at scheduled slots, and respect turf facility equipment and rules.',
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  const ListTile(
                    leading: Icon(Icons.info_outline, color: Color(0xFF166534)),
                    title: Text('App Version', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: Text('v1.0.0 (Production)', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
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
                icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                label: const Text(
                  'Log Out from Games24',
                  style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 14),
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
        color: Color(0xFF9CA3AF),
        letterSpacing: 1.0,
      ),
    );
  }
}
