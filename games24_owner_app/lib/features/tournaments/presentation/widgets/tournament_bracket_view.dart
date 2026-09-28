import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/tournament_model.dart';

class TournamentBracketView extends StatelessWidget {
  final TournamentModel tournament;
  final Function(TournamentFixture)? onMatchTap;

  const TournamentBracketView({
    super.key,
    required this.tournament,
    this.onMatchTap,
  });

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'cricket':
        return Icons.sports_cricket_rounded;
      case 'football':
      case 'futsal':
        return Icons.sports_soccer_rounded;
      case 'badminton':
      case 'tennis':
        return Icons.sports_tennis_rounded;
      case 'basketball':
        return Icons.sports_basketball_rounded;
      case 'volleyball':
        return Icons.sports_volleyball_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tournament.fixtures.isEmpty) {
      return AppCard(
        child: Column(
          children: const [
            Icon(Icons.account_tree_rounded, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('No Bracket Generated Yet', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Admin can generate fixtures after registrations close.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );
    }

    // Group fixtures by stage
    final stagesMap = <String, List<TournamentFixture>>{};
    for (final fix in tournament.fixtures) {
      stagesMap.putIfAbsent(fix.stage, () => []).add(fix);
    }

    // Ordered stages sequence
    final stageOrder = ['Group Stage', 'Round of 32', 'Round of 16', 'Quarter Final', 'Semi Final', 'Final'];
    final activeStages = stageOrder.where((s) => stagesMap.containsKey(s)).toList();
    final stageMatchCounts = activeStages.map((s) => stagesMap[s]!.length).toList();
    final sportIcon = _getSportIcon(tournament.sportType);

    const double slotHeight = 160.0;
    const double headerHeight = 46.0;

    int maxSlotUnits = 1;
    if (activeStages.isNotEmpty) {
      final firstCount = stageMatchCounts[0];
      maxSlotUnits = firstCount > 0 ? firstCount : 1;
      for (int i = 0; i < activeStages.length; i++) {
        final count = stageMatchCounts[i];
        final units = count * (1 << i);
        if (units > maxSlotUnits) {
          maxSlotUnits = units;
        }
      }
    }
    final double totalHeight = headerHeight + (maxSlotUnits * slotHeight);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tournament.championTeam.isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(sportIcon, color: Colors.white, size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tournament.sportType.toUpperCase()} CHAMPION 🏆',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                          ),
                          Text(
                            tournament.championTeam,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          const Text('Winner of Grand Final', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (isMobile) ...[
              ...activeStages.map((stageName) {
                final isFinal = stageName == 'Final';
                final fixtures = stagesMap[stageName]!;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isFinal
                                ? [Colors.amber.shade700, Colors.amber.shade900]
                                : [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(sportIcon, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              stageName.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...fixtures.map((fix) => _buildBracketMatchCard(context, fix)),
                      if (!isFinal)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Icon(Icons.arrow_downward_rounded, color: AppColors.primary.withValues(alpha: 0.6), size: 24),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ] else ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < activeStages.length; i++) ...[
                      _buildStageColumn(
                        context,
                        activeStages[i],
                        stagesMap[activeStages[i]]!,
                        i,
                        stageMatchCounts,
                        i == activeStages.length - 1,
                        sportIcon,
                        totalHeight,
                        headerHeight,
                        slotHeight,
                      ),
                      if (i < activeStages.length - 1)
                        CustomPaint(
                          size: Size(40, totalHeight),
                          painter: BracketStageConnectorPainter(
                            color: AppColors.primary.withValues(alpha: 0.7),
                            stageIndex: i,
                            stageMatchCounts: stageMatchCounts,
                            headerHeight: headerHeight,
                            slotHeight: slotHeight,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static double getMatchCenterY(
    int stageIndex,
    int matchIndex,
    List<int> stageMatchCounts,
    double headerHeight,
    double slotHeight,
  ) {
    if (stageIndex <= 0) {
      return headerHeight + (matchIndex + 0.5) * slotHeight;
    }

    final currentCount = stageMatchCounts[stageIndex];
    final prevCount = stageMatchCounts[stageIndex - 1];

    if (prevCount == currentCount * 2) {
      final topY = getMatchCenterY(stageIndex - 1, 2 * matchIndex, stageMatchCounts, headerHeight, slotHeight);
      final botY = getMatchCenterY(stageIndex - 1, 2 * matchIndex + 1, stageMatchCounts, headerHeight, slotHeight);
      return (topY + botY) / 2;
    } else {
      final int startK = (matchIndex * prevCount) ~/ currentCount;
      final int endK = (((matchIndex + 1) * prevCount) ~/ currentCount) - 1;
      final safeEndK = endK.clamp(startK, prevCount - 1);
      final firstY = getMatchCenterY(stageIndex - 1, startK, stageMatchCounts, headerHeight, slotHeight);
      final lastY = getMatchCenterY(stageIndex - 1, safeEndK, stageMatchCounts, headerHeight, slotHeight);
      return (firstY + lastY) / 2;
    }
  }

  Widget _buildStageColumn(
    BuildContext context,
    String stageName,
    List<TournamentFixture> fixtures,
    int stageIndex,
    List<int> stageMatchCounts,
    bool isFinalStage,
    IconData sportIcon,
    double totalHeight,
    double headerHeight,
    double slotHeight,
  ) {
    return SizedBox(
      width: 240,
      height: totalHeight,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 34,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFinalStage
                      ? [Colors.amber.shade700, Colors.amber.shade900]
                      : [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(sportIcon, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    stageName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (int j = 0; j < fixtures.length; j++) ...[
            Positioned(
              top: getMatchCenterY(stageIndex, j, stageMatchCounts, headerHeight, slotHeight) - 57.5,
              height: 115,
              left: 0,
              right: 0,
              child: Center(
                child: _buildBracketMatchCard(context, fixtures[j]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBracketMatchCard(BuildContext context, TournamentFixture fix) {
    final isLive = fix.status == 'Live';
    final isCompleted = fix.status == 'Completed';

    return InkWell(
      onTap: onMatchTap != null ? () => onMatchTap!(fix) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isLive
              ? Colors.red.shade50
              : (isCompleted ? Colors.green.shade50 : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLive
                ? Colors.red
                : (isCompleted ? Colors.green.shade400 : Colors.grey.shade300),
            width: isLive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLive ? Colors.red.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    fix.matchNumber,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLive
                        ? Colors.red
                        : (isCompleted ? Colors.green : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    fix.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: (isLive || isCompleted) ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildTeamRow(fix.teamA, fix.logoA, fix.scoreA, fix.wicketsA, fix.oversA, fix.winnerTeam == fix.teamA, fix.winnerTeam.isNotEmpty && fix.winnerTeam != fix.teamA),
            const Divider(height: 8, thickness: 0.8),
            _buildTeamRow(fix.teamB, fix.logoB, fix.scoreB, fix.wicketsB, fix.oversB, fix.winnerTeam == fix.teamB, fix.winnerTeam.isNotEmpty && fix.winnerTeam != fix.teamB),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(
    String name,
    String logo,
    int score,
    int wickets,
    String overs,
    bool isWinner,
    bool isLoser,
  ) {
    final isTbd = name.startsWith('TBD') || name == 'BYE';
    final isBye = name == 'BYE';
    String scoreStr = '$score';
    if (wickets > 0 || overs.isNotEmpty) {
      scoreStr = '$score/$wickets';
    }

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            logo,
            width: 18,
            height: 18,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 18,
              height: 18,
              color: Colors.grey.shade300,
              child: const Icon(Icons.shield, size: 10, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isWinner ? FontWeight.bold : (isTbd ? FontWeight.normal : FontWeight.w500),
              color: isLoser
                  ? Colors.grey
                  : (isBye ? Colors.orange.shade800 : (isWinner ? Colors.green.shade900 : Colors.black87)),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isTbd && !isBye)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isWinner ? Colors.green : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              scoreStr,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isWinner ? Colors.white : Colors.black87,
              ),
            ),
          ),
      ],
    );
  }
}

class BracketStageConnectorPainter extends CustomPainter {
  final Color color;
  final int stageIndex;
  final List<int> stageMatchCounts;
  final double headerHeight;
  final double slotHeight;

  BracketStageConnectorPainter({
    required this.color,
    required this.stageIndex,
    required this.stageMatchCounts,
    required this.headerHeight,
    required this.slotHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final midX = size.width / 2;
    final prevCount = stageMatchCounts[stageIndex];
    final targetCount = stageMatchCounts[stageIndex + 1];

    for (int j = 0; j < targetCount; j++) {
      final targetY = TournamentBracketView.getMatchCenterY(stageIndex + 1, j, stageMatchCounts, headerHeight, slotHeight);

      List<int> feederIndices = [];
      if (prevCount == targetCount * 2) {
        feederIndices = [2 * j, 2 * j + 1];
      } else {
        final int startK = (j * prevCount) ~/ targetCount;
        final int endK = (((j + 1) * prevCount) ~/ targetCount) - 1;
        for (int k = startK; k <= endK && k < prevCount; k++) {
          feederIndices.add(k);
        }
      }

      for (int k in feederIndices) {
        final feederY = TournamentBracketView.getMatchCenterY(stageIndex, k, stageMatchCounts, headerHeight, slotHeight);
        final path = Path();
        path.moveTo(0, feederY);
        path.lineTo(midX, feederY);
        path.lineTo(midX, targetY);
        path.lineTo(size.width, targetY);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BracketStageConnectorPainter oldDelegate) => true;
}
