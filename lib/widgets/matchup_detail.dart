import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../models/matchup.dart';
import '../models/slot_player.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'player_tile.dart';
import 'team_avatar.dart';

/// Hiển thị chi tiết Starters vs Bench của hai đội trong một cặp đấu; nhận [pair], [homeStarters], [homeBench], [awayStarters], [awayBench].
class MatchupDetail extends StatelessWidget {
  const MatchupDetail({
    super.key,
    required this.pair,
    required this.homeStarters,
    required this.homeBench,
    required this.awayStarters,
    required this.awayBench,
  });

  final MatchupPair pair;
  final List<SlotPlayer> homeStarters;
  final List<SlotPlayer> homeBench;
  final List<SlotPlayer> awayStarters;
  final List<SlotPlayer> awayBench;

  @override
  Widget build(BuildContext context) {
    final homeName =
        pair.home.team?.teamName ?? 'Roster ${pair.home.rosterId}';
    final awayName = pair.away != null
        ? (pair.away!.team?.teamName ?? 'Roster ${pair.away!.rosterId}')
        : AppStrings.byeLabel;

    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        _ScoreboardHeader(
          homeName: homeName,
          homeAvatar: pair.home.team?.avatar,
          homePoints: pair.home.points,
          awayName: awayName,
          awayAvatar: pair.away?.team?.avatar,
          awayPoints: pair.away?.points,
        ),
        const SizedBox(height: AppSpacing.md),
        _TeamMatchupRosterCard(
          teamName: homeName,
          starters: homeStarters,
          bench: homeBench,
        ),
        if (pair.away != null) ...[
          const SizedBox(height: AppSpacing.md),
          _TeamMatchupRosterCard(
            teamName: awayName,
            starters: awayStarters,
            bench: awayBench,
          ),
        ],
      ],
    );
  }
}

class _ScoreboardHeader extends StatelessWidget {
  const _ScoreboardHeader({
    required this.homeName,
    required this.homeAvatar,
    required this.homePoints,
    required this.awayName,
    required this.awayAvatar,
    required this.awayPoints,
  });

  final String homeName;
  final String? homeAvatar;
  final double homePoints;
  final String awayName;
  final String? awayAvatar;
  final double? awayPoints;

  @override
  Widget build(BuildContext context) {
    final homeLeading = awayPoints != null && homePoints > awayPoints!;
    final awayLeading = awayPoints != null && awayPoints! > homePoints;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TeamAvatar(avatar: homeAvatar, teamName: homeName),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    homeName,
                    style: AppTextStyles.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    homePoints.toStringAsFixed(2),
                    style: homeLeading
                        ? AppTextStyles.scoreLargeWinner
                        : AppTextStyles.scoreLarge,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(AppStrings.vsLabel, style: AppTextStyles.sectionHeader),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TeamAvatar(avatar: awayAvatar, teamName: awayName),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    awayName,
                    style: AppTextStyles.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    awayPoints != null ? awayPoints!.toStringAsFixed(2) : '-',
                    style: awayLeading
                        ? AppTextStyles.scoreLargeWinner
                        : AppTextStyles.scoreLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMatchupRosterCard extends StatelessWidget {
  const _TeamMatchupRosterCard({
    required this.teamName,
    required this.starters,
    required this.bench,
  });

  final String teamName;
  final List<SlotPlayer> starters;
  final List<SlotPlayer> bench;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                teamName,
                style: AppTextStyles.appTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                AppStrings.sectionStarters,
                style: AppTextStyles.sectionHeader,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (starters.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  AppStrings.noPlayersInGroup,
                  style: AppTextStyles.bodyMuted,
                ),
              )
            else
              ...starters.map(
                (sp) => PlayerTile(slotPlayer: sp, showPoints: true),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                AppStrings.sectionBench,
                style: AppTextStyles.sectionHeader,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (bench.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  AppStrings.noPlayersInGroup,
                  style: AppTextStyles.bodyMuted,
                ),
              )
            else
              ...bench.map(
                (sp) => PlayerTile(slotPlayer: sp, showPoints: true),
              ),
          ],
        ),
      ),
    );
  }
}
