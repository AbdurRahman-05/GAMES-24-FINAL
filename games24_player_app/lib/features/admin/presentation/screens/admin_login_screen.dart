import 'package:flutter/material.dart';
import 'package:games24_player_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../providers/admin_providers.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  void _onAdminLogin() {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();
    if (phone.isEmpty) {
      ToastUtils.showError(context, "Please enter partner registered phone.");
      return;
    }
    if (pin.isEmpty) {
      ToastUtils.showError(context, "Please enter security PIN.");
      return;
    }
    ref.read(isAdminModeProvider.notifier).setMode(true);
    ToastUtils.showSuccess(context, "Venue Partner Login Successful! Welcome Madurai Turf Arena.");
    context.go('/admin/dashboard');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
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
              const SizedBox(height: 20),
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
                'Log in to manage your Madurai sports turf, block slots, track daily revenue, and scan player entry QR codes.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

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

              AppTextField(
                label: 'Partner Registered Phone',
                hint: 'Enter 10-digit mobile number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_rounded,
              ),
              const SizedBox(height: 20),

              AppTextField(
                label: 'Admin Security PIN',
                hint: 'Enter PIN',
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 16),

              // Demo Auto-fill Helper Card
              AppCard(
                onTap: _onAdminLogin,
                color: AppColors.primary.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Demo Partner Quick Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap here for instant Turf Partner Dashboard preview (Madurai Turf Arena)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              AppButton(
                text: 'Login to Turf Partner Dashboard',
                icon: Icons.login_rounded,
                onPressed: _onAdminLogin,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
