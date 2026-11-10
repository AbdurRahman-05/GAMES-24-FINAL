import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../shared/repositories/mock_celebrations.dart';

class CelebrationBookingScreen extends StatelessWidget {
  const CelebrationBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packages = MockCelebrationsRepository.packages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Celebration & Events'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/dashboard');
            }
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final pkg = packages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      pkg.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(pkg.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              'From ₹${pkg.basePrice.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(pkg.subtitle, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.people_rounded, size: 16, color: AppColors.secondary),
                            const SizedBox(width: 6),
                            Text('Capacity: Up to ${pkg.capacity} guests', style: theme.textTheme.bodySmall),
                          ],
                        ),
                        const Divider(height: 24),
                        const Text('Package Highlights:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        ...pkg.highlights.map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text(h, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )),
                        const SizedBox(height: 16),
                        AppButton(
                          text: 'Enquire / Book Package',
                          icon: Icons.cake_rounded,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(pkg.title),
                                content: const Text('Our Madurai event coordinator will call you back within 15 minutes to customize your celebration!'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Got it'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
