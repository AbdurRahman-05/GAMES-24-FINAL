import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:games24_owner_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/admin_providers.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final TextEditingController _phoneController =
      TextEditingController(text: '7010396732');
  final TextEditingController _otpController =
      TextEditingController(text: '1234');

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
        Uri.parse('http://localhost:3000/auth/admin-login'),
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
        final errorStr = 'Cannot connect to server (http://localhost:3000). Please ensure backend is running.';
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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.stadium_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Turf Owner Partner Hub',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Log in with your verified mobile number and OTP to manage slots, revenue, and player bookings.',
                style: theme.textTheme.bodyMedium,
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

              // Register New Turf Callout Banner
              AppCard(
                onTap: () => context.push('/register'),
                color: AppColors.secondary.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_business_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New Turf Owner? Register Here 🏟️',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Complete 4-step onboarding & GST KYC document submission',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.secondary),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Phone Number Input
              AppTextField(
                label: 'Partner Registered Phone',
                hint: 'Enter 10-digit registered number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_rounded,
              ),
              const SizedBox(height: 20),

              // OTP Input (Mock: 1234)
              AppTextField(
                label: 'Partner Login OTP (Mock: 1234)',
                hint: '1234',
                controller: _otpController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.password_rounded,
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  'Mock OTP: Use 1234 to verify and log in',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Quick Fill Helper for Verified Admin
              AppCard(
                onTap: () {
                  setState(() {
                    _phoneController.text = '7010396732';
                    _otpController.text = '1234';
                    _errorMessage = null;
                  });
                },
                color: AppColors.primary.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick-Fill Verified Partner (7010396732)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to autofill verified owner number (Inno - KK Nagar)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.touch_app_rounded,
                        color: AppColors.primary, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Error / Warning Alert Box
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Login Denied / Not Verified',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Login Button
              AppButton(
                text: _isLoading ? 'Verifying with Database...' : 'Login to Turf Partner Dashboard',
                icon: Icons.login_rounded,
                onPressed: _isLoading ? null : _onAdminLogin,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
