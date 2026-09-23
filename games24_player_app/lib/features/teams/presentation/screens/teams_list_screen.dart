import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/providers/app_providers.dart';
import '../widgets/team_card.dart';

class TeamsListScreen extends ConsumerWidget {
  const TeamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Madurai Teams & Leaderboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TeamCard(
              team: team,
              onTap: () => context.push('/team-details/${team.id}'),
              onChallengeTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Challenge sent to ${team.name}! Captain ${team.captainName} will be notified.')),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-team'),
        label: const Text('Create Team'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
