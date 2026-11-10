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
      setState(() => _errorMessage = 'Please enter the 4-digit OTP (Mock: 1234).');
      ToastUtils.showError(context, 'Please enter OTP.');
      return;
    }

    if (otp != '1234') {
      setState(() => _errorMessage = 'Invalid OTP! Please enter correct mock OTP: 1234.');
      ToastUtils.showError(context, 'Invalid OTP! Enter 1234.');
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
      backgroundColor: const Color(0xFFF6FAF7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Official Games24 Brand Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 14),

              // Partner Hub Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF166534).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, size: 14, color: Color(0xFF166534)),
                    SizedBox(width: 6),
                    Text(
                      'TURF OWNER & PARTNER HUB',
                      style: TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Header Titles
              const Text(
                'Partner Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your verified mobile number and OTP to manage court slots, revenue & player bookings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Pending Registration status banner if exists
              if (_hasPendingRegistration) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade800, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Verification Notice',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your venue (${_pendingVenueName ?? 'Application'}${_pendingTrackingCode != null ? ' • $_pendingTrackingCode' : ''}) is waiting for Super Admin audit.',
                              style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text('View Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Clean Form Card (matching Player App style)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
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
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                            decoration: const BoxDecoration(
                              border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  '+91',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF6B7280)),
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
                                color: Color(0xFF111827),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter 10-digit number',
                                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
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
                    const Text(
                      'Login OTP',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          color: Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF166534), size: 20),
                          suffixIcon: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF166534).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Mock: 1234',
                              style: TextStyle(
                                color: Color(0xFF166534),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          hintText: 'Enter 4-digit OTP',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5, letterSpacing: 0),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick-Fill Helper Button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _phoneController.text = '7010396732';
                          _otpController.text = '1234';
                          _errorMessage = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF166534)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap to autofill verified partner (7010396732)',
                                style: TextStyle(
                                  color: Color(0xFF166534),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Error Alert Box (if present)
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade900, fontSize: 12),
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
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onAdminLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF166534),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFA7F3D0),
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
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.4,
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
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
                              color: const Color(0xFF166534).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_business_rounded,
                              color: Color(0xFF166534),
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
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '4-step onboarding & instant verification',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF9CA3AF),
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
