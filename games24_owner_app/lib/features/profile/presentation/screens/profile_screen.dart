import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../admin/providers/admin_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
          child: Column(
            children: [
              // User header
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.person_rounded, size: 48, color: AppColors.primary),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Abdur Rahman', style: theme.textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text('+91 98765 43210 • Madurai, TN', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Partner / Admin Portal Launcher Card
              AppCard(
                onTap: () {
                  ref.read(isAdminModeProvider.notifier).setMode(true);
                  context.push('/admin/dashboard');
                },
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Turf Partner / Admin Portal 🏟️', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          const Text('Manage slots, block courts, scan QR entry', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Player Stats Row
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        children: [
                          Text('12', style: theme.textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          const Text('Bookings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        children: [
                          Text('5', style: theme.textTheme.titleLarge?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          const Text('Hosted', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        children: [
                          Text('4.9 ★', style: theme.textTheme.titleLarge?.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          const Text('Karma', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Options Menu
              _ProfileTile(
                icon: Icons.confirmation_number_outlined,
                title: 'My Bookings',
                onTap: () => context.push('/my-bookings'),
              ),
              _ProfileTile(
                icon: Icons.sports_kabaddi_rounded,
                title: 'My Hosted Matches',
                onTap: () => context.push('/my-hosted-games'),
              ),
              _ProfileTile(
                icon: Icons.shield_outlined,
                title: 'Madurai Teams Leaderboard',
                onTap: () => context.push('/teams'),
              ),
              _ProfileTile(
                icon: Icons.favorite_outline_rounded,
                title: 'Favorites',
                onTap: () => context.push('/favorites'),
              ),
              _ProfileTile(
                icon: Icons.cake_outlined,
                title: 'Party & Celebration Packages',
                onTap: () => context.push('/celebrations'),
              ),
              _ProfileTile(
                icon: Icons.settings_outlined,
                title: 'Settings & Theme',
                onTap: () => context.push('/settings'),
              ),
              const SizedBox(height: 20),
              AppCard(
                onTap: () => context.go('/login'),
                color: AppColors.error.withValues(alpha: 0.08),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
