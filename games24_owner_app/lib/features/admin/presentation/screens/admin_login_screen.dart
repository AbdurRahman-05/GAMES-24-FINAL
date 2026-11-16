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
  final bool showLogo;
  const AdminLoginScreen({super.key, this.showLogo = true});

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
    final phone = _phoneController.text.trim().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final otp = _otpController.text.trim();

    setState(() => _errorMessage = null);

    if (phone.length < 10) {
      setState(
        () => _errorMessage =
            'Please enter a valid 10-digit registered mobile number.',
      );
      ToastUtils.showError(context, 'Enter a valid 10-digit mobile number.');
      return;
    }

    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Please enter the 4-digit OTP.');
      ToastUtils.showError(context, 'Please enter OTP.');
      return;
    }

    if (otp != '1234') {
      setState(
        () =>
            _errorMessage = 'Invalid OTP! Please check your OTP and try again.',
      );
      ToastUtils.showError(context, 'Invalid OTP! Try again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/admin-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': phone, 'otp': otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ref.read(isAdminModeProvider.notifier).setMode(true);
        if (data['admin'] != null && data['admin'] is Map<String, dynamic>) {
          ref
              .read(turfProfileProvider.notifier)
              .setFromVerifiedAdmin(data['admin'] as Map<String, dynamic>);
        }
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('owner_logged_in', true);
          await prefs.setString('owner_phone', phone);
          if (data['admin'] != null) {
            await prefs.setString(
              'verified_admin_data',
              jsonEncode(data['admin']),
            );
            await prefs.setString(
              'owner_venue_name',
              data['admin']?['venueName'] ?? 'Venue',
            );
          }
        } catch (e) {
          debugPrint('Error saving login prefs: $e');
        }
        if (mounted) {
          final venue = data['admin']?['venueName'] ?? 'Venue';
          ToastUtils.showSuccess(context, 'Login Successful! Welcome, $venue.');
          context.go('/admin/dashboard');
        }
      } else {
        final message =
            data['message'] ??
            'Access Denied: This mobile number is not in the Verified Admin table. Waiting registrations cannot log in.';
        if (mounted) {
          setState(() => _errorMessage = message);
          ToastUtils.showError(context, message);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorStr =
            'Cannot connect to server (${ApiConfig.baseUrl}). Please ensure backend is running.';
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
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Official Games24 Brand Logo
              if (widget.showLogo)
                Center(
                  child: Hero(
                    tag: 'gamez24_logo_emblem',
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                const SizedBox(height: 80),
              const SizedBox(height: 16),

              // Header Titles
              const Text(
                'Partner Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your verified mobile number and OTP to manage court slots, revenue & player bookings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFA1A1AA),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Pending Registration status banner if exists
              if (_hasPendingRegistration) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF241A04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF92400E)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.hourglass_top_rounded,
                        color: Color(0xFFFBBF24),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pending Verification Notice',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFFD4FF00),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your venue (${_pendingVenueName ?? 'Application'}${_pendingTrackingCode != null ? ' • $_pendingTrackingCode' : ''}) is waiting for Super Admin audit.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFD4FF00),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text(
                          'View Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFFD4FF00),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Clean Form Card (Dark Premium Pitch Black style)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF262626)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2E2E2E)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 13,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFF2E2E2E)),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  '+91',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 18,
                                  color: Color(0xFFA1A1AA),
                                ),
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
                                color: Colors.white,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter 10-digit number',
                                hintStyle: TextStyle(
                                  color: Color(0xFF71717A),
                                  fontSize: 13.5,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // OTP Input
                    const Text(
                      'Login OTP',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2E2E2E)),
                      ),
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFFD4FF00),
                            size: 20,
                          ),
                          hintText: 'Enter 4-digit OTP',
                          hintStyle: TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 13.5,
                            letterSpacing: 0,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Error Alert Box (if present)
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade700),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade400,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade200,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Primary Login Button (Official Logo Neon Lime #D4FF00)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onAdminLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4FF00),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: const Color(0xFF2A3305),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Login to Dashboard',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Colors.black,
                                  ),
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
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF262626)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/register'),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD4FF00,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_business_rounded,
                              color: Color(0xFFD4FF00),
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '4-step onboarding & instant verification',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFA1A1AA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF71717A),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
