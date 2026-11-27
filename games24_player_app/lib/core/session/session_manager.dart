import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../booking_manager.dart';
import '../../challenge_manager.dart';
import '../../login_screen.dart';
import '../../match_score_manager.dart';
import '../../team_manager.dart';
import '../../tournament_manager.dart';

/// Owns the logged-in user's session.
///
/// Everything in SharedPreferences except a few device-level settings belongs to the current
/// user. It is wiped on logout and whenever a different phone number logs in, so one account
/// never sees another account's bookings, teams, player id or stats.
class SessionManager {
  SessionManager._();

  /// Device preferences that survive logout.
  static const Set<String> _deviceKeys = {
    'has_seen_welcome',
    'user_selected_location',
  };

  static String _last10(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  static Future<String> currentPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('mobileNumber') ?? '').trim();
  }

  static Future<void> _clearUserData(SharedPreferences prefs) async {
    for (final key in prefs.getKeys().toList()) {
      if (!_deviceKeys.contains(key)) {
        await prefs.remove(key);
      }
    }
  }

  /// Called after a successful login or signup.
  static Future<void> startSession({
    required String mobileNumber,
    required String fullName,
    String? preferredSport,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString('mobileNumber');
    if (previous == null || _last10(previous) != _last10(mobileNumber)) {
      await _clearUserData(prefs);
    }
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('mobileNumber', mobileNumber);
    await prefs.setString('fullName', fullName);
    if (preferredSport != null && preferredSport.isNotEmpty) {
      await prefs.setString('preferredSport', preferredSport);
    }
    await _reloadManagers();
  }

  /// Clears the session and all per-user cached data, then returns to the login screen.
  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await _clearUserData(prefs);
    await _reloadManagers();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Drops in-memory state held by the singleton managers and reloads it for the current user.
  static Future<void> _reloadManagers() async {
    await Future.wait([
      BookingManager().reset(),
      TeamManager().reset(),
      ChallengeManager().reset(),
      TournamentManager().reset(),
      MatchScoreManager().reset(),
    ]);
  }
}
