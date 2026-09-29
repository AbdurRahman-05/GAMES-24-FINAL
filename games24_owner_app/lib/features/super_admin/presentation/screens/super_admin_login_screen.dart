import 'package:flutter/material.dart';
import 'package:games24_owner_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';

class SuperAdminLoginScreen extends ConsumerStatefulWidget {
  const SuperAdminLoginScreen({super.key});

  @override
  ConsumerState<SuperAdminLoginScreen> createState() =>
      _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState
    extends ConsumerState<SuperAdminLoginScreen> {
  final TextEditingController _emailController =
      TextEditingController(text: 'owner@Games24.in');
  final TextEditingController _pinController =
      TextEditingController(text: '9999');

  void _onSuperAdminLogin() {
    ToastUtils.showSuccess(context, "Super Admin Master Login Granted! Welcome App Owner.");
    context.go('/super-admin/dashboard');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Games24 Owner - Platform Control'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Super Admin Portal',
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Platform App Owner Control Center. Oversee all turf venue partners, approve new venue onboarding, and manage user access across Madurai.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  AppTextField(
                    label: 'Super Admin Master Email',
                    hint: 'owner@Games24.in',
                    controller: _emailController,
                    prefixIcon: Icons.email_rounded,
                  ),
                  const SizedBox(height: 20),

                  AppTextField(
                    label: 'Master Security PIN',
                    hint: '9999',
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    prefixIcon: Icons.shield_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Demo Quick Login Helper Card
                  AppCard(
                    onTap: _onSuperAdminLogin,
                    color: AppColors.primary.withValues(alpha: 0.08),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Instant App Owner Quick Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap for 1-tap Super Admin dashboard preview',
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
                  const SizedBox(height: 32),

                  AppButton(
                    text: 'Launch Super Admin Panel',
                    icon: Icons.key_rounded,
                    onPressed: _onSuperAdminLogin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
