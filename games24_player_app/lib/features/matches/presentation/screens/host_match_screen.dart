import 'package:flutter/material.dart';
import 'package:games24_player_app/core/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/sports_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../shared/models/match_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/repositories/mock_venues.dart';

class HostMatchScreen extends ConsumerStatefulWidget {
  const HostMatchScreen({super.key});

  @override
  ConsumerState<HostMatchScreen> createState() => _HostMatchScreenState();
}

class _HostMatchScreenState extends ConsumerState<HostMatchScreen> {
  String _selectedSport = 'Football';
  late String _selectedVenueId;
  String _selectedSkill = 'Intermediate';
  int _playersNeeded = 10;
  double _pricePerPlayer = 120.0;
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedVenueId = MockVenuesRepository.venues.first.id;
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _onHostMatch() {
    final venue = MockVenuesRepository.venues.firstWhere((v) => v.id == _selectedVenueId);

    final match = MatchModel(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      sportId: _selectedSport.toLowerCase(),
      sportName: _selectedSport,
      hostName: 'You (Host)',
      hostAvatar: 'https://i.pravatar.cc/150?img=68',
      hostPhone: '+91 98765 00000',
      venueId: venue.id,
      venueName: venue.name,
      area: venue.area,
      date: 'Tomorrow, 07:00 PM',
      time: '07:00 PM - 08:00 PM',
      skillLevel: _selectedSkill,
      totalPlayersNeeded: _playersNeeded,
      joinedPlayersCount: 1,
      playerAvatars: ['https://i.pravatar.cc/150?img=68'],
      pricePerPlayer: _pricePerPlayer,
      description: _descController.text.isEmpty
          ? 'Open match hosted by local player in Madurai. Join us!'
          : _descController.text,
    );

    ref.read(hostedMatchesProvider.notifier).addMatch(match);

    ToastUtils.showSuccess(context, "Match hosted successfully! Players can now join.");

    context.go('/main');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host a Match'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Banner Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.groups_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Short of Players?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Host a match in Madurai, gather local players, & split turf fees.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Select Sport
            Text('Select Sport', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: SportsData.allSports.length,
                itemBuilder: (context, index) {
                  final sport = SportsData.allSports[index];
                  final isSelected = _selectedSport == sport.name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(sport.icon, size: 16, color: isSelected ? Colors.white : sport.color),
                      label: Text(sport.name),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedSport = sport.name);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Select Venue in Madurai
            Text('Select Venue in Madurai', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedVenueId,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.place_rounded, color: AppColors.primary, size: 22),
                  border: InputBorder.none,
                ),
                items: MockVenuesRepository.venues.map((venue) {
                  return DropdownMenuItem<String>(
                    value: venue.id,
                    child: Text(
                      '${venue.name} (${venue.area})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedVenueId = val);
                },
              ),
            ),
            const SizedBox(height: 24),

            // Skill Level Required
            Text('Skill Level Required', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.skillLevels.map((skill) {
                final isSelected = _selectedSkill == skill;
                return ChoiceChip(
                  label: Text(skill),
                  selected: isSelected,
                  selectedColor: AppColors.secondary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedSkill = skill);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Players & Price Breakdown Card
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Players Needed', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          const Text('Total spots open for strangers', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.primary),
                            onPressed: _playersNeeded > 2 ? () => setState(() => _playersNeeded--) : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_playersNeeded',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                            onPressed: () => setState(() => _playersNeeded++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  AppTextField(
                    label: 'Price per Player Share (₹)',
                    hint: '120',
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) _pricePerPlayer = parsed;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Match Guidelines Text Field
            AppTextField(
              label: 'Match Guidelines / Notes',
              hint: 'Bring your own boots/rackets. Match balls and bibs provided by host.',
              maxLines: 3,
              controller: _descController,
            ),
            const SizedBox(height: 32),

            AppButton(
              text: 'Publish Open Match',
              icon: Icons.publish_rounded,
              onPressed: _onHostMatch,
            ),
          ],
        ),
      ),
    );
  }
}
