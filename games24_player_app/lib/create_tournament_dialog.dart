import 'package:flutter/material.dart';
import 'package:games24_player_app/create_public_tournament_screen.dart';
import 'package:games24_player_app/create_private_tournament_screen.dart';

class CreateTournamentDialog extends StatelessWidget {
  const CreateTournamentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF262626)),
      ),
      backgroundColor: const Color(0xFF141414),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      elevation: 12,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 420,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2916),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFD4FF00),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Host a Tournament',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choose visibility & registration type',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFFA1A1AA), size: 22),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFF262626), height: 1),
              const SizedBox(height: 18),

              // Public Tournament Card
              _buildTypeCard(
                context,
                title: 'Public Championship',
                badgeText: 'Open to All 🌐',
                badgeColor: const Color(0xFF1F2916),
                badgeTextColor: const Color(0xFFD4FF00),
                description:
                    'Listed on public discovery feed and search. Any team can join and compete for the prize pool.',
                icon: Icons.public_rounded,
                iconBgColor: const Color(0xFF1F2916),
                iconColor: const Color(0xFFD4FF00),
                borderColor: const Color(0xFFD4FF00).withValues(alpha: 0.35),
                gradientColors: [const Color(0xFF1C1C1C), const Color(0xFF141414)],
                tags: ['🏆 City Leaderboard', '⚡ Live Bracket', '🚀 High Visibility'],
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePublicTournamentScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Private Tournament Card
              _buildTypeCard(
                context,
                title: 'Private Invite-Only Cup',
                badgeText: 'Secure PIN 🔒',
                badgeColor: const Color(0xFF2B1D08),
                badgeTextColor: const Color(0xFFFBBF24),
                description:
                    'Exclusive tournament protected with a 6-digit access PIN. Ideal for corporate leagues, college cups, and friends.',
                icon: Icons.lock_outline_rounded,
                iconBgColor: const Color(0xFF2B1D08),
                iconColor: const Color(0xFFFBBF24),
                borderColor: const Color(0xFF78350F),
                gradientColors: [const Color(0xFF1C1C1C), const Color(0xFF141414)],
                tags: ['🔑 Secret PIN', '🛡️ Closed Entry', '✉️ Direct Invite'],
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePrivateTournamentScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context, {
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String description,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required Color borderColor,
    required List<Color> gradientColors,
    required List<String> tags,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFA1A1AA)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFFA1A1AA),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF262626)),
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

void showCreateTournamentDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => const CreateTournamentDialog(),
  );
}
