import '../../../../api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:games24_owner_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/admin_providers.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasPendingRegistration = false;
  String? _pendingTrackingCode;
  String? _pendingVenueName;

  @override
  void initState() {
    super.initState();
    _checkPendingRegistration();
  }

  Future<void> _checkPendingRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPending = prefs.getBool('owner_is_pending_verification') ?? false;
      if (isPending && mounted) {
        setState(() {
          _hasPendingRegistration = true;
          _pendingTrackingCode = prefs.getString('owner_tracking_code');
          _pendingVenueName = prefs.getString('owner_venue_name');
          final phone = prefs.getString('owner_phone');
          if (phone != null && phone.isNotEmpty) {
            _phoneController.text = phone;
          }
        });
      }
    } catch (e) {
      debugPrint("Error reading pending registration: $e");
    }
  }

  Future<void> _onAdminLogin() async {
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final otp = _otpController.text.trim();

    setState(() => _errorMessage = null);

    if (phone.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit registered mobile number.');
      ToastUtils.showError(context, 'Enter a valid 10-digit mobile number.');
      return;
    }

    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Please enter the 4-digit OTP.');
      ToastUtils.showError(context, 'Please enter OTP.');
      return;
    }

    if (otp != '1234') {
      setState(() => _errorMessage = 'Invalid OTP! Please check your OTP and try again.');
      ToastUtils.showError(context, 'Invalid OTP! Try again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/admin-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': phone,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ref.read(isAdminModeProvider.notifier).setMode(true);
        if (data['admin'] != null && data['admin'] is Map<String, dynamic>) {
          ref.read(turfProfileProvider.notifier).setFromVerifiedAdmin(data['admin'] as Map<String, dynamic>);
        }
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('owner_logged_in', true);
          await prefs.setString('owner_phone', phone);
          if (data['admin'] != null) {
            await prefs.setString('verified_admin_data', jsonEncode(data['admin']));
            await prefs.setString('owner_venue_name', data['admin']?['venueName'] ?? 'Venue');
          }
        } catch (e) {
          debugPrint('Error saving login prefs: $e');
        }
        if (mounted) {
          final venue = data['admin']?['venueName'] ?? 'Venue';
          ToastUtils.showSuccess(
            context,
            'Login Successful! Welcome, $venue.',
          );
          context.go('/admin/dashboard');
        }
      } else {
        final message = data['message'] ??
            'Access Denied: This mobile number is not in the Verified Admin table. Waiting registrations cannot log in.';
        if (mounted) {
          setState(() => _errorMessage = message);
          ToastUtils.showError(context, message);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorStr = 'Cannot connect to server (${ApiConfig.baseUrl}). Please ensure backend is running.';
        setState(() => _errorMessage = errorStr);
        ToastUtils.showError(context, errorStr);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Curved Stadium Header with wm_full.png
            ClipPath(
              clipper: _HeaderCurveClipper(),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 34,
                  left: 24,
                  right: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF071C13), // Deep Stadium Midnight Pitch
                      Color(0xFF0E3825), // Stadium Turf Dark Green
                    ],
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'gamez24_logo_emblem',
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260, maxHeight: 36),
                      child: Image.asset(
                        'assets/images/wm_full.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Main Content Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header Titles
                  const Text(
                    'Partner Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Enter your registered mobile number and OTP to manage court slots, tariffs & matchday bookings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

              // Pending Registration status banner if exists
              if (_hasPendingRegistration) ...[
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
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFB45309), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pending Verification Notice',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF92400E)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your venue (${_pendingVenueName ?? 'Application'}${_pendingTrackingCode != null ? ' • $_pendingTrackingCode' : ''}) is waiting for Super Admin audit.',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF78350F)),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('View Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFFB45309))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Clean Form Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phone Number Label & Input
                    const Text(
                      'Registered Mobile Number',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                            decoration: const BoxDecoration(
                              border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  '+91',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter 10-digit number',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // OTP Input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Login OTP',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        Text(
                          'Test OTP: 1234',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: Color(0xFF154D36), size: 20),
                          hintText: 'Enter 4-digit OTP',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5, letterSpacing: 0),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Error Alert Box (if present)
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Primary Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onAdminLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF154D36),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFA7F3D0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Login to Dashboard',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Register New Turf Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/register'),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF154D36).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_business_rounded,
                              color: Color(0xFF154D36),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Turf Owner? Register Venue',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '4-step onboarding & instant verification',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Security & Trust Footnote
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shield_outlined, size: 14, color: Color(0xFF94A3B8)),
                  SizedBox(width: 6),
                  Text(
                    'Encrypted Operator Access • Gamez24 Partner OS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    ),
  ),
);
  }
}

/// Custom Clipper to render the curved stadium banner header
class _HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);
    // Smooth quadratic curve dipping down in the center
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 28,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
