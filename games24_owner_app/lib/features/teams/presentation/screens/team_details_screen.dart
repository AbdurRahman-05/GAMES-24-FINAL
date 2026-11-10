import 'package:flutter/material.dart';
import 'package:games24_owner_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/repositories/mock_teams.dart';

class TeamDetailsScreen extends ConsumerWidget {
  final String teamId;

  const TeamDetailsScreen({
    super.key,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final teams = ref.watch(teamsProvider);

    final team = teams.firstWhere(
      (t) => t.id == teamId,
      orElse: () => MockTeamsRepository.teams.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
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
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      team.logoUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(team.name, style: theme.textTheme.displayMedium),
                  const SizedBox(height: 4),
                  Text('Sport: ${team.sportName} • ${team.homeTurf}', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Team Stats Summary
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    child: Column(
                      children: [
                        Text('${team.winRate}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        const Text('Win Rate', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    child: Column(
                      children: [
                        Text('${team.wins}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.success)),
                        const SizedBox(height: 4),
                        const Text('Wins', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    child: Column(
                      children: [
                        Text('${team.matchesPlayed}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Played', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            Text('Captain & Squad', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(team.captainAvatar),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(team.captainName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const Text('Team Captain', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Achievements', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            ...team.achievements.map((ach) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(ach, style: theme.textTheme.bodyLarge)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 36),

            AppButton(
              text: 'Challenge ${team.name}',
              icon: Icons.flash_on_rounded,
              onPressed: () {
                ToastUtils.showSuccess(context, "Challenge sent to ${team.name}!");
              },
            ),
          ],
        ),
      ),
    );
  }
}
