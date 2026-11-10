import 'package:flutter/material.dart';
import 'package:games24_player_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/sports_data.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/providers/app_providers.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _captainController = TextEditingController();
  String _selectedSport = 'Football';
  String _homeTurf = '';

  @override
  void dispose() {
    _nameController.dispose();
    _captainController.dispose();
    super.dispose();
  }

  void _onCreateTeam() {
    if (_nameController.text.trim().isEmpty) {
      ToastUtils.showError(context, "Please enter your team name.");
      return;
    }
    if (_captainController.text.trim().isEmpty) {
      ToastUtils.showError(context, "Please enter captain name.");
      return;
    }

    final newTeam = TeamModel(
      id: 't_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=200&q=80',
      captainName: _captainController.text.trim(),
      captainAvatar: 'https://i.pravatar.cc/150?img=68',
      sportName: _selectedSport,
      homeTurf: _homeTurf,
      membersCount: 1,
      matchesPlayed: 0,
      wins: 0,
      winRate: 0.0,
      achievements: ['Newly Registered Madurai Team'],
    );

    ref.read(teamsProvider.notifier).addTeam(newTeam);

    ToastUtils.showSuccess(context, "Team created successfully!");

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Team'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Team Name',
              hint: 'e.g. Madurai Warriors FC',
              controller: _nameController,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Captain Name',
              hint: 'Enter Captain Name',
              controller: _captainController,
            ),
            const SizedBox(height: 20),
            Text('Sport', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedSport,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: SportsData.allSports.map((s) {
                return DropdownMenuItem(
                  value: s.name,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSport = val);
              },
            ),
            const SizedBox(height: 20),
            Text('Home Turf in Madurai', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            AppTextField(
              label: 'Home Turf',
              hint: 'e.g. Madurai Turf Arena (KK Nagar)',
              onChanged: (val) => _homeTurf = val,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Register Team',
              icon: Icons.shield_rounded,
              onPressed: _onCreateTeam,
            ),
          ],
        ),
      ),
    );
  }
}
