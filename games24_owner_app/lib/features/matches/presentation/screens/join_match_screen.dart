import 'package:flutter/material.dart';
import 'package:games24_owner_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/repositories/mock_matches.dart';

class JoinMatchScreen extends ConsumerWidget {
  final String matchId;

  const JoinMatchScreen({
    super.key,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final matches = ref.watch(hostedMatchesProvider);

    final match = matches.firstWhere(
      (m) => m.id == matchId,
      orElse: () => MockMatchesRepository.matches.first,
    );

    final spotsLeft = match.totalPlayersNeeded - match.joinedPlayersCount;

    return Scaffold(
      appBar: AppBar(
        title: Text('${match.sportName} Match'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Host info card
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(match.hostAvatar),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(match.hostName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Host • Contact: ${match.hostPhone}', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                    onPressed: () => context.push('/chat'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Venue info card
            Text('Match Details', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(match.venueName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: Colors.grey),
                      const SizedBox(width: 10),
                      Text('${match.date} (${match.time})', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.fitness_center_rounded, color: AppColors.secondary),
                      const SizedBox(width: 10),
                      Text('Skill: ${match.skillLevel}', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Joined players section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Joined Players (${match.joinedPlayersCount}/${match.totalPlayersNeeded})', style: theme.textTheme.titleMedium),
                Text('$spotsLeft spots open', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: match.playerAvatars.map((avatar) {
                return CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(avatar),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            Text('Host Note', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(match.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 36),

            AppButton(
              text: match.isFull ? 'Match Full' : 'Join the Match (Pay ₹${match.pricePerPlayer.toInt()})',
              icon: Icons.check_circle_rounded,
              onPressed: match.isFull
                  ? null
                  : () {
                      ref.read(hostedMatchesProvider.notifier).joinMatch(match.id);
                      ToastUtils.showSuccess(context, "You joined the match! Chat with players now.");
                      context.push('/chat');
                    },
            ),
          ],
        ),
      ),
    );
  }
}
