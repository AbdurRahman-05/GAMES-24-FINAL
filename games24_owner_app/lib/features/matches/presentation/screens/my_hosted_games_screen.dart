import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../shared/providers/app_providers.dart';
import '../widgets/match_card.dart';

class MyHostedGamesScreen extends ConsumerWidget {
  const MyHostedGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(hostedMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Hosted Games'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: matches.isEmpty
          ? EmptyState(
              icon: Icons.groups_outlined,
              title: 'No Hosted Games Yet',
              description: 'Host a game and invite strangers or friends in Madurai.',
              buttonText: 'Host a Match Now',
              onButtonPressed: () => context.push('/host-match'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: MatchCard(
                    match: match,
                    onJoinTap: () => context.push('/join-match/${match.id}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/host-match'),
        label: const Text('Host New Match'),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }
}
